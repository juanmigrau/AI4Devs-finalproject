import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/auth/domain/entities/player_stats.dart';
import 'package:la_pocha/features/auth/domain/usecases/get_player_stats_usecase.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game_status.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_definition.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/history/domain/entities/game_detail.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_load_result.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_source.dart';
import 'package:la_pocha/features/history/domain/entities/round_summary.dart';
import 'package:la_pocha/features/history/domain/usecases/get_game_detail_usecase.dart';
import 'package:la_pocha/features/history/domain/usecases/get_game_history_usecase.dart';
import 'package:la_pocha/features/round/domain/entities/ranking_entry.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_player_stats_usecase_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GetGameHistoryUseCase>(),
  MockSpec<GetGameDetailUseCase>(),
])
void main() {
  group('GetPlayerStatsUseCase', () {
    const userId = 'user-1';
    late MockGetGameHistoryUseCase getGameHistory;
    late MockGetGameDetailUseCase getGameDetail;
    late GetPlayerStatsUseCase useCase;

    setUp(() {
      getGameHistory = MockGetGameHistoryUseCase();
      getGameDetail = MockGetGameDetailUseCase();
      useCase = GetPlayerStatsUseCase(
        getGameHistory: getGameHistory,
        getGameDetail: getGameDetail,
      );
    });

    test('returns empty stats when history has no games', () async {
      when(getGameHistory()).thenAnswer(
        (_) async => const GameHistoryLoadResult(items: []),
      );

      final stats = await useCase(userId: userId);

      expect(stats, const PlayerStats.empty());
      verifyNever(
        getGameDetail(
          gameId: anyNamed('gameId'),
          source: anyNamed('source'),
        ),
      );
    });

    test('computes wins, percentages, streaks, bid accuracy and partner',
        () async {
      final day1 = DateTime(2026, 8, 1);
      final day2 = DateTime(2026, 8, 2);
      final day3 = DateTime(2026, 8, 3);

      final historyItems = [
        _historyItem('g3', day3),
        _historyItem('g2', day2),
        _historyItem('g1', day1),
      ];

      when(getGameHistory()).thenAnswer(
        (_) async => GameHistoryLoadResult(items: historyItems),
      );

      // Newest: win with accurate bid
      when(
        getGameDetail(gameId: 'g3', source: GameHistorySource.local),
      ).thenAnswer(
        (_) async => _detail(
          id: 'g3',
          finishedAt: day3,
          selfScore: 100,
          selfRank: 1,
          partnerName: 'Luis',
          partnerUserId: 'partner-1',
          bid: 2,
          tricks: 2,
        ),
      );
      // Middle: loss, inaccurate bid
      when(
        getGameDetail(gameId: 'g2', source: GameHistorySource.local),
      ).thenAnswer(
        (_) async => _detail(
          id: 'g2',
          finishedAt: day2,
          selfScore: -10,
          selfRank: 2,
          partnerName: 'Luis',
          partnerUserId: 'partner-1',
          bid: 1,
          tricks: 0,
        ),
      );
      // Oldest: win
      when(
        getGameDetail(gameId: 'g1', source: GameHistorySource.local),
      ).thenAnswer(
        (_) async => _detail(
          id: 'g1',
          finishedAt: day1,
          selfScore: 50,
          selfRank: 1,
          partnerName: 'Ana',
          partnerUserId: 'partner-2',
          bid: 3,
          tricks: 3,
        ),
      );

      final stats = await useCase(userId: userId);

      expect(stats.totalGames, 3);
      expect(stats.wins, 2);
      expect(stats.winPercentage, closeTo(66.666, 0.01));
      expect(stats.averagePosition, closeTo(1.333, 0.01));
      expect(stats.bidAccuracyPercentage, closeTo(66.666, 0.01));
      expect(stats.recordScore, 100);
      expect(stats.worstScore, -10);
      expect(stats.currentWinStreak, 1);
      expect(stats.bestWinStreak, 1);
      expect(stats.mostFrequentPartner, 'Luis');
    });

    test('excludes own userId from mostFrequentPartner', () async {
      final finishedAt = DateTime(2026, 8, 5);
      when(getGameHistory()).thenAnswer(
        (_) async => GameHistoryLoadResult(
          items: [_historyItem('g1', finishedAt)],
        ),
      );
      when(
        getGameDetail(gameId: 'g1', source: GameHistorySource.local),
      ).thenAnswer(
        (_) async => _detail(
          id: 'g1',
          finishedAt: finishedAt,
          selfScore: 40,
          selfRank: 1,
          partnerName: 'Bob',
          partnerUserId: 'partner-bob',
          bid: 1,
          tricks: 1,
        ),
      );

      final stats = await useCase(userId: userId);

      expect(stats.mostFrequentPartner, 'Bob');
      expect(stats.mostFrequentPartner, isNot('Me'));
    });

    test('skips games where current user is not a player', () async {
      final finishedAt = DateTime(2026, 8, 5);
      when(getGameHistory()).thenAnswer(
        (_) async => GameHistoryLoadResult(
          items: [_historyItem('g1', finishedAt)],
        ),
      );
      when(
        getGameDetail(gameId: 'g1', source: GameHistorySource.local),
      ).thenAnswer(
        (_) async => _detail(
          id: 'g1',
          finishedAt: finishedAt,
          selfScore: 10,
          selfRank: 1,
          partnerName: 'X',
          partnerUserId: 'other',
          bid: 1,
          tricks: 1,
          includeSelf: false,
        ),
      );

      final stats = await useCase(userId: userId);

      expect(stats, const PlayerStats.empty());
    });

    test('computes bestWinStreak across chronological wins', () async {
      final d1 = DateTime(2026, 8, 1);
      final d2 = DateTime(2026, 8, 2);
      final d3 = DateTime(2026, 8, 3);
      final d4 = DateTime(2026, 8, 4);

      when(getGameHistory()).thenAnswer(
        (_) async => GameHistoryLoadResult(
          items: [
            _historyItem('g4', d4),
            _historyItem('g3', d3),
            _historyItem('g2', d2),
            _historyItem('g1', d1),
          ],
        ),
      );

      Future<GameDetail> detail({
        required String id,
        required DateTime at,
        required int rank,
      }) async =>
          _detail(
            id: id,
            finishedAt: at,
            selfScore: rank == 1 ? 80 : 20,
            selfRank: rank,
            partnerName: 'P',
            partnerUserId: 'p1',
            bid: 1,
            tricks: 1,
          );

      when(getGameDetail(gameId: 'g1', source: GameHistorySource.local))
          .thenAnswer((_) => detail(id: 'g1', at: d1, rank: 1));
      when(getGameDetail(gameId: 'g2', source: GameHistorySource.local))
          .thenAnswer((_) => detail(id: 'g2', at: d2, rank: 1));
      when(getGameDetail(gameId: 'g3', source: GameHistorySource.local))
          .thenAnswer((_) => detail(id: 'g3', at: d3, rank: 2));
      when(getGameDetail(gameId: 'g4', source: GameHistorySource.local))
          .thenAnswer((_) => detail(id: 'g4', at: d4, rank: 1));

      final stats = await useCase(userId: userId);

      expect(stats.currentWinStreak, 1);
      expect(stats.bestWinStreak, 2);
    });
  });
}

GameHistoryItem _historyItem(String id, DateTime finishedAt) {
  return GameHistoryItem(
    id: id,
    source: GameHistorySource.local,
    finishedAt: finishedAt,
    playerCount: 2,
    displayLabel: id,
  );
}

GameDetail _detail({
  required String id,
  required DateTime finishedAt,
  required int selfScore,
  required int selfRank,
  required String partnerName,
  required String partnerUserId,
  required int bid,
  required int tricks,
  bool includeSelf = true,
}) {
  const selfId = 'p-self';
  const partnerId = 'p-partner';

  final self = PlayerEmbed(
    id: selfId,
    displayName: 'Me',
    isGuest: false,
    userId: includeSelf ? 'user-1' : 'someone-else',
    seatOrder: 0,
    totalScore: selfScore,
    joinedAt: finishedAt,
  );
  final partner = PlayerEmbed(
    id: partnerId,
    displayName: partnerName,
    isGuest: false,
    userId: partnerUserId,
    seatOrder: 1,
    totalScore: selfRank == 1 ? selfScore - 10 : selfScore + 10,
    joinedAt: finishedAt,
  );

  final players = [self, partner];
  final ranking = selfRank == 1
      ? [
          RankingEntry(
            player: self,
            rank: 1,
            roundScore: 0,
            totalScore: self.totalScore,
          ),
          RankingEntry(
            player: partner,
            rank: 2,
            roundScore: 0,
            totalScore: partner.totalScore,
          ),
        ]
      : [
          RankingEntry(
            player: partner,
            rank: 1,
            roundScore: 0,
            totalScore: partner.totalScore,
          ),
          RankingEntry(
            player: self,
            rank: 2,
            roundScore: 0,
            totalScore: self.totalScore,
          ),
        ];

  final round = Round(
    id: 'r-$id',
    gameId: id,
    roundNumber: 1,
    cardsInRound: 1,
    dealerPlayerId: selfId,
    status: RoundStatus.closed,
    bids: {selfId: bid, partnerId: 0},
    tricks: {selfId: tricks, partnerId: 0},
    scoresDelta: {selfId: selfScore, partnerId: partner.totalScore},
    createdAt: finishedAt,
    closedAt: finishedAt,
  );

  final game = Game(
    id: id,
    status: GameStatus.finished,
    playerCount: 2,
    totalCards: 40,
    maxCardsPerRound: 1,
    roundSequence: const [RoundDefinition(roundNumber: 1, cardsPerPlayer: 1)],
    players: players,
    finishedAt: finishedAt,
    createdAt: finishedAt,
    updatedAt: finishedAt,
  );

  return GameDetail(
    game: game,
    roundSummaries: [
      RoundSummary(
        round: round,
        dealerDisplayName: 'Me',
        cumulativeRanking: ranking,
      ),
    ],
    finalRanking: ranking,
    source: GameHistorySource.local,
  );
}
