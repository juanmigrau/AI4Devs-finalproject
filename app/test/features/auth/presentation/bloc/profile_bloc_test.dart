import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/auth/domain/entities/player_stats.dart';
import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';
import 'package:la_pocha/features/auth/domain/failures/auth_failure.dart'
    as domain;
import 'package:la_pocha/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:la_pocha/features/auth/domain/usecases/get_player_stats_usecase.dart';
import 'package:la_pocha/features/auth/domain/usecases/update_display_name_usecase.dart';
import 'package:la_pocha/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'profile_bloc_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GetCurrentUserUseCase>(),
  MockSpec<GetPlayerStatsUseCase>(),
  MockSpec<UpdateDisplayNameUseCase>(),
])
void main() {
  late MockGetCurrentUserUseCase getCurrentUser;
  late MockGetPlayerStatsUseCase getPlayerStats;
  late MockUpdateDisplayNameUseCase updateDisplayName;

  final profile = UserProfile(
    uid: 'uid-1',
    displayName: 'Ana',
    email: 'ana@example.com',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  const stats = PlayerStats(
    totalGames: 2,
    wins: 1,
    winPercentage: 50,
    averagePosition: 1.5,
    bidAccuracyPercentage: 75,
    recordScore: 100,
    worstScore: 10,
    currentWinStreak: 1,
    bestWinStreak: 1,
    mostFrequentPartner: 'Luis',
  );

  ProfileBloc buildBloc() => ProfileBloc(
        getCurrentUser: getCurrentUser,
        getPlayerStats: getPlayerStats,
        updateDisplayName: updateDisplayName,
      );

  setUp(() {
    getCurrentUser = MockGetCurrentUserUseCase();
    getPlayerStats = MockGetPlayerStatsUseCase();
    updateDisplayName = MockUpdateDisplayNameUseCase();
  });

  blocTest<ProfileBloc, ProfileState>(
    'loads user then stats',
    build: buildBloc,
    setUp: () {
      when(getCurrentUser()).thenAnswer((_) async => profile);
      when(getPlayerStats(userId: 'uid-1')).thenAnswer((_) async => stats);
    },
    act: (bloc) => bloc.add(const ProfileStarted()),
    expect: () => [
      const ProfileLoading(),
      ProfileLoaded(user: profile, stats: null, statsLoading: true),
      ProfileLoaded(user: profile, stats: stats, statsLoading: false),
    ],
  );

  blocTest<ProfileBloc, ProfileState>(
    'updates display name and emits displayNameUpdated flag',
    build: buildBloc,
    seed: () => ProfileLoaded(
      user: profile,
      stats: stats,
      statsLoading: false,
    ),
    setUp: () {
      final updated = UserProfile(
        uid: profile.uid,
        displayName: 'Nuevo',
        email: profile.email,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
      );
      when(updateDisplayName('Nuevo')).thenAnswer((_) async => updated);
    },
    act: (bloc) => bloc.add(const ProfileDisplayNameSubmitted('Nuevo')),
    expect: () {
      final updated = UserProfile(
        uid: profile.uid,
        displayName: 'Nuevo',
        email: profile.email,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
      );
      return [
        ProfileLoaded(
          user: updated,
          stats: stats,
          statsLoading: false,
          displayNameUpdated: true,
        ),
        ProfileLoaded(
          user: updated,
          stats: stats,
          statsLoading: false,
        ),
      ];
    },
  );

  blocTest<ProfileBloc, ProfileState>(
    'emits failure then restores loaded state when update fails',
    build: buildBloc,
    seed: () => ProfileLoaded(
      user: profile,
      stats: stats,
      statsLoading: false,
    ),
    setUp: () {
      when(updateDisplayName('X'))
          .thenThrow(const domain.ValidationFailure('El nombre es obligatorio'));
    },
    act: (bloc) => bloc.add(const ProfileDisplayNameSubmitted('X')),
    expect: () => [
      const ProfileFailure(message: 'El nombre es obligatorio'),
      ProfileLoaded(user: profile, stats: stats, statsLoading: false),
    ],
  );
}
