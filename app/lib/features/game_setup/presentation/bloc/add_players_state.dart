part of 'add_players_bloc.dart';

sealed class AddPlayersState extends Equatable {
  const AddPlayersState();

  @override
  List<Object?> get props => [];
}

class AddPlayersInitial extends AddPlayersState {
  const AddPlayersInitial();
}

class AddPlayersLoading extends AddPlayersState {
  const AddPlayersLoading();
}

class AddPlayersLoaded extends AddPlayersState {
  const AddPlayersLoaded({
    required this.gameId,
    required this.playerCount,
    required this.players,
    required this.favorites,
    required this.activeEditIndex,
    required this.isLoading,
    this.currentUser,
    this.errorMessage,
    this.isUserSearchActive = false,
    this.userSearchQuery = '',
    this.userSearchResults = const [],
    this.userSearchLoading = false,
    this.userSearchError,
  });

  final String gameId;
  final int playerCount;
  final List<PlayerEmbed> players;
  final List<FavoritePlayer> favorites;
  final UserProfile? currentUser;
  final int? activeEditIndex;
  final bool isLoading;
  final String? errorMessage;
  final bool isUserSearchActive;
  final String userSearchQuery;
  final List<UserSearchResult> userSearchResults;
  final bool userSearchLoading;
  final String? userSearchError;

  bool get isComplete => players.length == playerCount;

  int get remainingCount => playerCount - players.length;

  bool isUserAlreadyInGame(String uid) {
    for (final player in players) {
      if (player.userId == uid) {
        return true;
      }
    }
    return false;
  }

  AddPlayersLoaded copyWith({
    String? gameId,
    int? playerCount,
    List<PlayerEmbed>? players,
    List<FavoritePlayer>? favorites,
    UserProfile? currentUser,
    int? activeEditIndex,
    bool clearActiveEditIndex = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isUserSearchActive,
    String? userSearchQuery,
    List<UserSearchResult>? userSearchResults,
    bool? userSearchLoading,
    String? userSearchError,
    bool clearUserSearchError = false,
    bool resetUserSearch = false,
  }) {
    return AddPlayersLoaded(
      gameId: gameId ?? this.gameId,
      playerCount: playerCount ?? this.playerCount,
      players: players ?? this.players,
      favorites: favorites ?? this.favorites,
      currentUser: currentUser ?? this.currentUser,
      activeEditIndex: clearActiveEditIndex
          ? null
          : (activeEditIndex ?? this.activeEditIndex),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isUserSearchActive: resetUserSearch
          ? false
          : (isUserSearchActive ?? this.isUserSearchActive),
      userSearchQuery: resetUserSearch
          ? ''
          : (userSearchQuery ?? this.userSearchQuery),
      userSearchResults: resetUserSearch
          ? const []
          : (userSearchResults ?? this.userSearchResults),
      userSearchLoading: resetUserSearch
          ? false
          : (userSearchLoading ?? this.userSearchLoading),
      userSearchError: resetUserSearch || clearUserSearchError
          ? null
          : (userSearchError ?? this.userSearchError),
    );
  }

  @override
  List<Object?> get props => [
    gameId,
    playerCount,
    players,
    favorites,
    currentUser,
    activeEditIndex,
    isLoading,
    errorMessage,
    isUserSearchActive,
    userSearchQuery,
    userSearchResults,
    userSearchLoading,
    userSearchError,
  ];
}

class AddPlayersFailure extends AddPlayersState {
  const AddPlayersFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
