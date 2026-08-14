import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/di/injection.dart';
import 'package:la_pocha/core/utils/snack_bar_helper.dart';
import 'package:la_pocha/core/widgets/pocha_app_bar.dart';
import 'package:la_pocha/core/widgets/primary_button.dart';
import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';
import 'package:la_pocha/features/favorites/domain/entities/favorite_player.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/presentation/bloc/add_players_bloc.dart';
import 'package:la_pocha/features/game_setup/presentation/widgets/favorites_chip_section.dart';
import 'package:la_pocha/features/game_setup/presentation/widgets/players_roster_section.dart';
import 'package:la_pocha/features/game_setup/presentation/widgets/search_player_stub.dart';

class AddPlayersPage extends StatelessWidget {
  const AddPlayersPage({super.key, required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<AddPlayersBloc>()..add(AddPlayersStarted(gameId: gameId)),
      child: _AddPlayersView(gameId: gameId),
    );
  }
}

class _AddPlayersView extends StatelessWidget {
  const _AddPlayersView({required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddPlayersBloc, AddPlayersState>(
      listener: (context, state) {
        if (state is! AddPlayersLoaded) {
          return;
        }
        final errorMessage = state.errorMessage;
        if (errorMessage == null || errorMessage.isEmpty) {
          return;
        }
        SnackBarHelper.showError(errorMessage);
      },
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<AddPlayersBloc, AddPlayersState>(
            builder: (context, state) {
              if (state is AddPlayersLoading || state is AddPlayersInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is AddPlayersFailure) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(state.message),
                  ),
                );
              }
              if (state is! AddPlayersLoaded) {
                return const SizedBox.shrink();
              }

              final visibleFavorites = _visibleFavorites(state);
              final remaining = state.playerCount - state.players.length;
              final isComplete = remaining == 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PochaAppBar(
                    title: 'Jugadores',
                    subtitle:
                        '${state.players.length} de ${state.playerCount} añadidos',
                    onBack: () => context.go('/games/new'),
                    actions: [
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SearchPlayerStub(),
                              fullscreenDialog: true,
                            ),
                          );
                        },
                        icon: const Icon(Icons.search, color: Colors.white),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FavoritesChipSection(
                              visibleFavorites: visibleFavorites,
                              currentUser: _visibleCurrentUser(state),
                              onFavoriteTap: (favorite) {
                                context.read<AddPlayersBloc>().add(
                                  FavoriteChipTapped(favorite: favorite),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            PlayersRosterSection(
                              playerCount: state.playerCount,
                              players: state.players,
                              activeEditIndex: state.activeEditIndex,
                              isLoading: state.isLoading,
                              currentUserId: state.currentUser?.uid,
                              isFavoritePlayer: (player) =>
                                  _isFavoritePlayer(player, state.favorites),
                              onEmptySlotEditActivated: (index) {
                                context.read<AddPlayersBloc>().add(
                                  EditSlotActivated(index: index),
                                );
                              },
                              onPlayerEditActivated: (playerId) {
                                context.read<AddPlayersBloc>().add(
                                  PlayerEditActivated(playerId: playerId),
                                );
                              },
                              onEditCancelled: () {
                                context.read<AddPlayersBloc>().add(
                                  const EditSlotCancelled(),
                                );
                              },
                              onEmptySlotNameConfirmed: (index, name) {
                                context.read<AddPlayersBloc>().add(
                                  PlayerNameConfirmed(index: index, name: name),
                                );
                              },
                              onPlayerNameUpdated: (playerId, name) {
                                context.read<AddPlayersBloc>().add(
                                  PlayerNameUpdated(
                                    playerId: playerId,
                                    newName: name,
                                  ),
                                );
                              },
                              onFavoriteToggle: (playerId) {
                                context.read<AddPlayersBloc>().add(
                                  PlayerFavoriteToggled(playerId: playerId),
                                );
                              },
                              onRemovePlayer: (playerId) {
                                context.read<AddPlayersBloc>().add(
                                  PlayerRemoved(playerId: playerId),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: PrimaryButton(
                      label: isComplete
                          ? 'Continuar'
                          : 'Faltan $remaining jugadores',
                      onPressed: isComplete && !state.isLoading
                          ? () => context.go('/games/$gameId/setup')
                          : null,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<FavoritePlayer> _visibleFavorites(AddPlayersLoaded state) {
    return state.favorites
        .where((favorite) => !_playersContainsFavorite(state.players, favorite))
        .toList();
  }

  UserProfile? _visibleCurrentUser(AddPlayersLoaded state) {
    final user = state.currentUser;
    if (user == null) {
      return null;
    }
    for (final player in state.players) {
      if (player.userId == user.uid) {
        return null;
      }
    }
    return user;
  }

  bool _playersContainsFavorite(
    List<PlayerEmbed> players,
    FavoritePlayer favorite,
  ) {
    for (final player in players) {
      if (_isFavoriteMatch(player, favorite)) {
        return true;
      }
    }
    return false;
  }

  bool _isFavoritePlayer(PlayerEmbed player, List<FavoritePlayer> favorites) {
    for (final favorite in favorites) {
      if (_isFavoriteMatch(player, favorite)) {
        return true;
      }
    }
    return false;
  }

  bool _isFavoriteMatch(PlayerEmbed player, FavoritePlayer favorite) {
    if (player.userId != null && favorite.userId == player.userId) {
      return true;
    }
    return player.userId == null &&
        favorite.userId == null &&
        player.displayName.toLowerCase() == favorite.displayName.toLowerCase();
  }
}
