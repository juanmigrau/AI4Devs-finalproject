import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/core/widgets/player_initial_avatar.dart';

void main() {
  Future<void> pumpAvatar(
    WidgetTester tester, {
    required String name,
    String? photoURL,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerInitialAvatar(
            name: name,
            colorIndex: 0,
            photoURL: photoURL,
          ),
        ),
      ),
    );
  }

  testWidgets('shows the name initial when photoURL is null', (tester) async {
    await pumpAvatar(tester, name: 'Ana');

    expect(find.text('A'), findsOneWidget);
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.backgroundImage, isNull);
  });

  testWidgets('shows a question mark when the name is empty', (tester) async {
    await pumpAvatar(tester, name: '');

    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('uses NetworkImage and hides the initial when photoURL is set', (
    tester,
  ) async {
    await pumpAvatar(
      tester,
      name: 'Ana',
      photoURL: 'https://example.com/photo.jpg',
    );

    expect(find.text('A'), findsNothing);
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.backgroundImage, isA<NetworkImage>());
    expect(
      (avatar.backgroundImage! as NetworkImage).url,
      'https://example.com/photo.jpg',
    );
  });
}
