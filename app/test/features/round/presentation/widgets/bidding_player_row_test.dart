import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/round/presentation/widgets/bid_input_stepper.dart';
import 'package:la_pocha/features/round/presentation/widgets/bidding_player_row.dart';

void main() {
  final player = PlayerEmbed(
    id: 'p1',
    displayName: 'Ana',
    isGuest: true,
    userId: null,
    seatOrder: 0,
    totalScore: 42,
    joinedAt: DateTime(2026),
  );

  Future<void> pumpRow(
    WidgetTester tester, {
    required BiddingPlayerRowStatus status,
    int? bid,
    int draftBid = 0,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: BiddingPlayerRow(
            player: player,
            index: 0,
            status: status,
            bid: bid,
            isDealer: false,
            draftBid: draftBid,
            cardsInRound: 5,
            canConfirmBid: true,
          ),
        ),
      ),
    );
  }

  testWidgets('completed row shows avatar, name and bid circle', (tester) async {
    await pumpRow(tester, status: BiddingPlayerRowStatus.completed, bid: 2);

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.byType(BidInputStepper), findsNothing);
    expect(find.text('42 pts'), findsNothing);
  });

  testWidgets('active row shows avatar, name and bid stepper', (tester) async {
    await pumpRow(tester, status: BiddingPlayerRowStatus.active, draftBid: 1);

    expect(find.text('Ana'), findsOneWidget);
    expect(find.byType(BidInputStepper), findsOneWidget);
    expect(find.text('42 pts'), findsNothing);
  });

  testWidgets('pending row shows faded avatar and name only', (tester) async {
    await pumpRow(tester, status: BiddingPlayerRowStatus.pending);

    expect(find.text('Ana'), findsOneWidget);
    expect(find.byType(BidInputStepper), findsNothing);
    expect(find.text('42 pts'), findsNothing);
  });
}
