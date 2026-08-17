import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pocha/features/auth/domain/entities/player_stats.dart';
import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';
import 'package:la_pocha/features/auth/domain/failures/auth_failure.dart'
    as domain;
import 'package:la_pocha/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:la_pocha/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:la_pocha/features/auth/domain/usecases/get_player_stats_usecase.dart';
import 'package:la_pocha/features/auth/domain/usecases/update_display_name_usecase.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required this._getCurrentUser,
    required this._getPlayerStats,
    required this._updateDisplayName,
    required this._deleteAccount,
  }) : super(const ProfileInitial()) {
    on<ProfileStarted>(_onStarted);
    on<ProfileDisplayNameSubmitted>(_onDisplayNameSubmitted);
    on<DeleteAccountRequested>(_onDeleteAccountRequested);
  }

  final GetCurrentUserUseCase _getCurrentUser;
  final GetPlayerStatsUseCase _getPlayerStats;
  final UpdateDisplayNameUseCase _updateDisplayName;
  final DeleteAccountUseCase _deleteAccount;
  ProfileLoaded? _loadedSnapshot;

  Future<void> _onStarted(
    ProfileStarted event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      final user = await _getCurrentUser();
      if (user == null) {
        emit(const ProfileFailure(message: 'No hay sesión activa.'));
        return;
      }

      emit(ProfileLoaded(user: user, stats: null, statsLoading: true));

      try {
        final stats = await _getPlayerStats(userId: user.uid);
        emit(ProfileLoaded(user: user, stats: stats, statsLoading: false));
      } catch (_) {
        emit(
          ProfileLoaded(
            user: user,
            stats: const PlayerStats.empty(),
            statsLoading: false,
          ),
        );
      }
    } catch (_) {
      emit(const ProfileFailure(message: 'No se pudo cargar el perfil.'));
    }
  }

  Future<void> _onDisplayNameSubmitted(
    ProfileDisplayNameSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state;
    if (current is! ProfileLoaded) {
      return;
    }

    try {
      final updated = await _updateDisplayName(event.displayName);
      emit(
        ProfileLoaded(
          user: updated,
          stats: current.stats,
          statsLoading: current.statsLoading,
          displayNameUpdated: true,
        ),
      );
      emit(
        ProfileLoaded(
          user: updated,
          stats: current.stats,
          statsLoading: current.statsLoading,
        ),
      );
    } on domain.AuthFailure catch (error) {
      emit(ProfileFailure(message: error.message));
      emit(
        ProfileLoaded(
          user: current.user,
          stats: current.stats,
          statsLoading: current.statsLoading,
        ),
      );
    } catch (_) {
      emit(const ProfileFailure(message: 'No se pudo actualizar el nombre.'));
      emit(
        ProfileLoaded(
          user: current.user,
          stats: current.stats,
          statsLoading: current.statsLoading,
        ),
      );
    }
  }

  Future<void> _onDeleteAccountRequested(
    DeleteAccountRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state;
    if (current is ProfileLoaded) {
      _loadedSnapshot = current;
    } else if (current is AccountDeleting) {
      return;
    }

    final snapshot = _loadedSnapshot;
    if (snapshot == null) {
      return;
    }

    emit(const AccountDeleting());
    try {
      await _deleteAccount(password: event.password);
      emit(const AccountDeleted());
    } on domain.RequiresRecentLoginFailure {
      emit(const AccountReauthRequired());
      emit(
        ProfileLoaded(
          user: snapshot.user,
          stats: snapshot.stats,
          statsLoading: snapshot.statsLoading,
        ),
      );
    } on domain.ReauthCancelledFailure {
      emit(
        ProfileLoaded(
          user: snapshot.user,
          stats: snapshot.stats,
          statsLoading: snapshot.statsLoading,
        ),
      );
    } on domain.AuthFailure catch (error) {
      emit(AccountDeleteFailure(message: error.message));
      emit(
        ProfileLoaded(
          user: snapshot.user,
          stats: snapshot.stats,
          statsLoading: snapshot.statsLoading,
        ),
      );
    } catch (_) {
      emit(
        const AccountDeleteFailure(
          message: 'No se pudo eliminar la cuenta. Inténtalo de nuevo.',
        ),
      );
      emit(
        ProfileLoaded(
          user: snapshot.user,
          stats: snapshot.stats,
          statsLoading: snapshot.statsLoading,
        ),
      );
    }
  }
}
