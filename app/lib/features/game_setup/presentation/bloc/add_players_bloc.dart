import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pocha/core/errors/user_facing_error_mapper.dart';
import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';
import 'package:la_pocha/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:la_pocha/features/favorites/domain/entities/favorite_player.dart';
import 'package:la_pocha/features/favorites/domain/usecases/add_favorite_usecase.dart';
import 'package:la_pocha/features/favorites/domain/usecases/get_favorites_usecase.dart';
import 'package:la_pocha/features/favorites/domain/usecases/remove_favorite_usecase.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/entities/user_search_result.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/add_player_from_favorite_usecase.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/add_player_usecase.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/add_registered_player_usecase.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/get_game_by_id_usecase.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/remove_player_usecase.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/search_users_usecase.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/update_player_name_usecase.dart';

part 'add_players_event.dart';
part 'add_players_state.dart';

class AddPlayersBloc extends Bloc<AddPlayersEvent, AddPlayersState> {
  AddPlayersBloc({
    required GetGameByIdUseCase getGameById,
    required GetFavoritesUseCase getFavorites,
    required GetCurrentUserUseCase getCurrentUser,
    required AddPlayerUseCase addPlayer,
    required AddPlayerFromFavoriteUseCase addPlayerFromFavorite,
    required AddRegisteredPlayerUseCase addRegisteredPlayer,
    required SearchUsersUseCase searchUsers,
    required RemovePlayerUseCase removePlayer,
    required UpdatePlayerNameUseCase updatePlayerName,
    required AddFavoriteUseCase addFavorite,
    required RemoveFavoriteUseCase removeFavorite,
    Connectivity? connectivity,
  }) : _getGameById = getGameById,
       _getFavorites = getFavorites,
       _getCurrentUser = getCurrentUser,
       _addPlayer = addPlayer,
       _addPlayerFromFavorite = addPlayerFromFavorite,
       _addRegisteredPlayer = addRegisteredPlayer,
       _searchUsers = searchUsers,
       _removePlayer = removePlayer,
       _updatePlayerName = updatePlayerName,
       _addFavorite = addFavorite,
       _removeFavorite = removeFavorite,
       _connectivity = connectivity ?? Connectivity(),
       super(const AddPlayersInitial()) {
    on<AddPlayersStarted>(_onStarted);
    on<FavoriteChipTapped>(_onFavoriteChipTapped);
    on<PlayerFavoriteToggled>(_onPlayerFavoriteToggled);
    on<PlayerRemoved>(_onPlayerRemoved);
    on<EditSlotActivated>(_onEditSlotActivated);
    on<EditSlotCancelled>(_onEditSlotCancelled);
    on<PlayerNameConfirmed>(_onPlayerNameConfirmed);
    on<PlayerEditActivated>(_onPlayerEditActivated);
    on<PlayerNameUpdated>(_onPlayerNameUpdated);
    on<UserSearchOpened>(_onUserSearchOpened);
    on<UserSearchQueryChanged>(_onUserSearchQueryChanged);
    on<UserSearchResultSelected>(_onUserSearchResultSelected);
    on<UserSearchClosed>(_onUserSearchClosed);
  }

  static const offlineSearchMessage =
      'Búsqueda no disponible sin conexión. '
      'Puedes añadir jugadores por nombre o favoritos.';

  static const searchTimeoutMessage =
      'La búsqueda tardó demasiado. Inténtalo de nuevo.';

  static const Duration searchDebounce = Duration(milliseconds: 300);

  final GetGameByIdUseCase _getGameById;
  final GetFavoritesUseCase _getFavorites;
  final GetCurrentUserUseCase _getCurrentUser;
  final AddPlayerUseCase _addPlayer;
  final AddPlayerFromFavoriteUseCase _addPlayerFromFavorite;
  final AddRegisteredPlayerUseCase _addRegisteredPlayer;
  final SearchUsersUseCase _searchUsers;
  final RemovePlayerUseCase _removePlayer;
  final UpdatePlayerNameUseCase _updatePlayerName;
  final AddFavoriteUseCase _addFavorite;
  final RemoveFavoriteUseCase _removeFavorite;
  final Connectivity _connectivity;

  Future<void> _onStarted(
    AddPlayersStarted event,
    Emitter<AddPlayersState> emit,
  ) async {
    emit(const AddPlayersLoading());
    try {
      final gameFuture = _getGameById(event.gameId);
      final favoritesFuture = _getFavorites();
      final currentUserFuture = _getCurrentUser();
      final game = await gameFuture;
      if (game == null) {
        emit(AddPlayersFailure(message: 'Partida no encontrada'));
        return;
      }
      final favorites = await favoritesFuture;
      final currentUser = await currentUserFuture;
      emit(
        AddPlayersLoaded(
          gameId: game.id,
          playerCount: game.playerCount,
          players: game.players,
          favorites: favorites,
          currentUser: currentUser,
          activeEditIndex: null,
          isLoading: false,
        ),
      );
    } catch (error) {
      emit(AddPlayersFailure(message: mapExceptionToUserMessage(error)));
    }
  }

  Future<void> _onFavoriteChipTapped(
    FavoriteChipTapped event,
    Emitter<AddPlayersState> emit,
  ) async {
    final current = state;
    if (current is! AddPlayersLoaded) {
      return;
    }

    emit(
      current.copyWith(
        isLoading: true,
        clearError: true,
        clearActiveEditIndex: true,
      ),
    );
    try {
      final isCurrentUserChip = _isCurrentUserFavorite(
        event.favorite,
        current.currentUser,
      );
      final game = isCurrentUserChip
          ? await _addPlayerFromFavorite(
              gameId: current.gameId,
              favoriteId: event.favorite.id,
              favorite: event.favorite,
            )
          : await _addPlayerFromFavorite(
              gameId: current.gameId,
              favoriteId: event.favorite.id,
            );
      emit(
        current.copyWith(
          players: game.players,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (error) {
      _emitTransientError(emit, current, mapExceptionToUserMessage(error));
    }
  }

  Future<void> _onPlayerFavoriteToggled(
    PlayerFavoriteToggled event,
    Emitter<AddPlayersState> emit,
  ) async {
    final current = state;
    if (current is! AddPlayersLoaded) {
      return;
    }

    PlayerEmbed? player;
    for (final item in current.players) {
      if (item.id == event.playerId) {
        player = item;
        break;
      }
    }
    if (player == null) {
      return;
    }

    final existingFavorite = _findFavoriteForPlayer(
      player: player,
      favorites: current.favorites,
    );

    emit(current.copyWith(isLoading: true, clearError: true));
    try {
      final updatedFavorites = [...current.favorites];
      if (existingFavorite == null) {
        final createdFavorite = await _addFavorite(
          displayName: player.displayName,
          userId: player.userId,
        );
        updatedFavorites.add(createdFavorite);
      } else {
        await _removeFavorite(existingFavorite.id);
        updatedFavorites.removeWhere((item) => item.id == existingFavorite.id);
      }
      emit(
        current.copyWith(
          favorites: updatedFavorites,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (error) {
      _emitTransientError(emit, current, mapExceptionToUserMessage(error));
    }
  }

  Future<void> _onPlayerRemoved(
    PlayerRemoved event,
    Emitter<AddPlayersState> emit,
  ) async {
    final current = state;
    if (current is! AddPlayersLoaded) {
      return;
    }

    emit(
      current.copyWith(
        isLoading: true,
        clearError: true,
        clearActiveEditIndex: true,
      ),
    );
    try {
      final game = await _removePlayer(
        gameId: current.gameId,
        playerId: event.playerId,
      );
      if (game == null) {
        emit(current.copyWith(isLoading: false, clearError: true));
        return;
      }
      emit(
        current.copyWith(
          players: game.players,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (error) {
      _emitTransientError(emit, current, mapExceptionToUserMessage(error));
    }
  }

  void _onEditSlotActivated(
    EditSlotActivated event,
    Emitter<AddPlayersState> emit,
  ) {
    final current = state;
    if (current is! AddPlayersLoaded) {
      return;
    }
    if (event.index < 0 || event.index >= current.playerCount) {
      return;
    }
    if (event.index < current.players.length) {
      return;
    }
    emit(current.copyWith(activeEditIndex: event.index, clearError: true));
  }

  void _onEditSlotCancelled(
    EditSlotCancelled event,
    Emitter<AddPlayersState> emit,
  ) {
    final current = state;
    if (current is! AddPlayersLoaded || current.activeEditIndex == null) {
      return;
    }
    emit(current.copyWith(clearActiveEditIndex: true, clearError: true));
  }

  Future<void> _onPlayerNameConfirmed(
    PlayerNameConfirmed event,
    Emitter<AddPlayersState> emit,
  ) async {
    final current = state;
    if (current is! AddPlayersLoaded) {
      return;
    }
    if (event.index != current.activeEditIndex) {
      return;
    }
    final trimmedName = event.name.trim();
    if (trimmedName.isEmpty) {
      _emitTransientError(emit, current, 'El nombre no puede estar vacío');
      return;
    }

    emit(current.copyWith(isLoading: true, clearError: true));
    try {
      final game = await _addPlayer(gameId: current.gameId, name: trimmedName);
      emit(
        current.copyWith(
          players: game.players,
          isLoading: false,
          clearActiveEditIndex: true,
          clearError: true,
        ),
      );
    } catch (error) {
      _emitTransientError(emit, current, mapExceptionToUserMessage(error));
    }
  }

  void _onPlayerEditActivated(
    PlayerEditActivated event,
    Emitter<AddPlayersState> emit,
  ) {
    final current = state;
    if (current is! AddPlayersLoaded) {
      return;
    }
    final index = current.players.indexWhere(
      (player) => player.id == event.playerId,
    );
    if (index < 0) {
      return;
    }
    emit(current.copyWith(activeEditIndex: index, clearError: true));
  }

  Future<void> _onPlayerNameUpdated(
    PlayerNameUpdated event,
    Emitter<AddPlayersState> emit,
  ) async {
    final current = state;
    if (current is! AddPlayersLoaded) {
      return;
    }

    PlayerEmbed? player;
    for (final item in current.players) {
      if (item.id == event.playerId) {
        player = item;
        break;
      }
    }
    if (player == null) {
      return;
    }

    final trimmedName = event.newName.trim();
    if (trimmedName.isEmpty) {
      _emitTransientError(emit, current, 'El nombre no puede estar vacío');
      return;
    }

    if (trimmedName.toLowerCase() == player.displayName.toLowerCase()) {
      emit(current.copyWith(clearActiveEditIndex: true, clearError: true));
      return;
    }

    emit(current.copyWith(isLoading: true, clearError: true));
    try {
      final game = await _updatePlayerName(
        gameId: current.gameId,
        playerId: event.playerId,
        newName: trimmedName,
      );
      emit(
        current.copyWith(
          players: game.players,
          isLoading: false,
          clearActiveEditIndex: true,
          clearError: true,
        ),
      );
    } catch (error) {
      _emitTransientError(emit, current, mapExceptionToUserMessage(error));
    }
  }

  void _onUserSearchOpened(
    UserSearchOpened event,
    Emitter<AddPlayersState> emit,
  ) {
    final current = state;
    if (current is! AddPlayersLoaded) {
      return;
    }
    emit(
      current.copyWith(
        isUserSearchActive: true,
        userSearchQuery: '',
        userSearchResults: const [],
        userSearchLoading: false,
        clearUserSearchError: true,
      ),
    );
  }

  Future<void> _onUserSearchQueryChanged(
    UserSearchQueryChanged event,
    Emitter<AddPlayersState> emit,
  ) async {
    final current = state;
    if (current is! AddPlayersLoaded || !current.isUserSearchActive) {
      return;
    }

    final trimmed = event.query.trim();
    if (trimmed.length < SearchUsersUseCase.minQueryLength) {
      emit(
        current.copyWith(
          userSearchQuery: event.query,
          userSearchResults: const [],
          userSearchLoading: false,
          clearUserSearchError: true,
        ),
      );
      return;
    }

    emit(
      current.copyWith(
        userSearchQuery: event.query,
        clearUserSearchError: true,
      ),
    );

    await Future<void>.delayed(searchDebounce);
    if (emit.isDone) {
      return;
    }
    final afterDelay = state;
    if (afterDelay is! AddPlayersLoaded ||
        !afterDelay.isUserSearchActive ||
        afterDelay.userSearchQuery != event.query) {
      return;
    }

    if (!await _hasConnectivity()) {
      emit(
        afterDelay.copyWith(
          userSearchLoading: false,
          userSearchResults: const [],
          userSearchError: offlineSearchMessage,
        ),
      );
      return;
    }

    emit(afterDelay.copyWith(userSearchLoading: true, clearUserSearchError: true));
    try {
      final results = await _searchUsers(
        event.query,
        excludeUid: afterDelay.currentUser?.uid,
      );
      final latest = state;
      if (latest is! AddPlayersLoaded ||
          latest.userSearchQuery != event.query) {
        return;
      }
      emit(
        latest.copyWith(
          userSearchResults: results,
          userSearchLoading: false,
          clearUserSearchError: true,
        ),
      );
    } on TimeoutException {
      final latest = state;
      if (latest is! AddPlayersLoaded) {
        return;
      }
      emit(
        latest.copyWith(
          userSearchLoading: false,
          userSearchResults: const [],
          userSearchError: searchTimeoutMessage,
        ),
      );
    } catch (error) {
      final latest = state;
      if (latest is! AddPlayersLoaded) {
        return;
      }
      final isTimeout = error is TimeoutException ||
          error.toString().contains('TimeoutException');
      emit(
        latest.copyWith(
          userSearchLoading: false,
          userSearchResults: const [],
          userSearchError: isTimeout
              ? searchTimeoutMessage
              : mapExceptionToUserMessage(error),
        ),
      );
    }
  }

  Future<void> _onUserSearchResultSelected(
    UserSearchResultSelected event,
    Emitter<AddPlayersState> emit,
  ) async {
    final current = state;
    if (current is! AddPlayersLoaded) {
      return;
    }
    if (current.isUserAlreadyInGame(event.user.uid)) {
      return;
    }

    emit(current.copyWith(isLoading: true, clearError: true));
    try {
      final game = await _addRegisteredPlayer(
        gameId: current.gameId,
        user: event.user,
      );
      emit(
        current.copyWith(
          players: game.players,
          isLoading: false,
          clearError: true,
          resetUserSearch: true,
        ),
      );
    } catch (error) {
      _emitTransientError(emit, current, mapExceptionToUserMessage(error));
    }
  }

  void _onUserSearchClosed(
    UserSearchClosed event,
    Emitter<AddPlayersState> emit,
  ) {
    final current = state;
    if (current is! AddPlayersLoaded) {
      return;
    }
    emit(current.copyWith(resetUserSearch: true));
  }

  Future<bool> _hasConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    if (result.contains(ConnectivityResult.none)) {
      return false;
    }
    return true;
  }

  /// Emits an error for the UI listener, then clears it so a later event
  /// cannot re-trigger the same SnackBar from a stale [errorMessage].
  void _emitTransientError(
    Emitter<AddPlayersState> emit,
    AddPlayersLoaded current,
    String message,
  ) {
    emit(current.copyWith(isLoading: false, errorMessage: message));
    emit(current.copyWith(isLoading: false, clearError: true));
  }

  bool _isCurrentUserFavorite(
    FavoritePlayer favorite,
    UserProfile? currentUser,
  ) {
    if (currentUser == null) {
      return false;
    }
    return favorite.userId == currentUser.uid;
  }

  FavoritePlayer? _findFavoriteForPlayer({
    required PlayerEmbed player,
    required List<FavoritePlayer> favorites,
  }) {
    for (final favorite in favorites) {
      if (player.userId != null && favorite.userId == player.userId) {
        return favorite;
      }
      if (player.userId == null &&
          favorite.userId == null &&
          favorite.displayName.toLowerCase() ==
              player.displayName.toLowerCase()) {
        return favorite;
      }
    }
    return null;
  }
}
