import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/di/injection.dart';
import 'package:la_pocha/core/errors/user_facing_error_mapper.dart';
import 'package:la_pocha/core/utils/snack_bar_helper.dart';
import 'package:la_pocha/core/widgets/final_standings_list.dart';
import 'package:la_pocha/core/widgets/pocha_app_bar.dart';
import 'package:la_pocha/core/widgets/primary_button.dart';
import 'package:la_pocha/core/widgets/warning_banner.dart';
import 'package:la_pocha/core/widgets/winner_card.dart';
import 'package:la_pocha/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/game_repository.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/round_repository.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_source.dart';
import 'package:la_pocha/features/history/presentation/bloc/repeat_game_cubit.dart';
import 'package:la_pocha/features/history/presentation/widgets/repeat_game_dialog.dart';
import 'package:la_pocha/features/round/domain/entities/ranking_entry.dart';
import 'package:la_pocha/features/round/domain/services/ranking_service.dart';
import 'package:la_pocha/features/sync/presentation/bloc/game_sync_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class GameFinalResultPage extends StatefulWidget {
  const GameFinalResultPage({super.key, required this.gameId});

  final String gameId;

  @override
  State<GameFinalResultPage> createState() => _GameFinalResultPageState();
}

class _GameFinalResultPageState extends State<GameFinalResultPage> {
  late Future<_FinalResultData> _loadFuture;

  @override
  void initState() {
    super.initState();
    WakelockPlus.disable();
    _loadFuture = _loadFinalResult();
  }

  Future<_FinalResultData> _loadFinalResult() async {
    final gameRepository = getIt<GameRepository>();
    final roundRepository = getIt<RoundRepository>();
    const rankingService = RankingService();

    final game = await gameRepository.getGameById(widget.gameId);
    if (game == null) {
      throw StateError('Game not found: ${widget.gameId}');
    }

    final lastRoundNumber =
        game.currentRoundNumber ?? game.roundSequence.length;
    final lastRound = await roundRepository.getRoundByGameAndNumber(
      widget.gameId,
      lastRoundNumber,
    );

    final scoresDelta = lastRound?.scoresDelta ?? {};
    final entries = rankingService.buildRanking(
      players: game.players,
      scoresDelta: scoresDelta,
      includePositionDelta: false,
    );

    return _FinalResultData(
      entries: entries,
      roundCount: game.roundSequence.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RepeatGameCubit>(),
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: FutureBuilder<_FinalResultData>(
            future: _loadFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(mapExceptionToUserMessage(snapshot.error!)),
                  ),
                );
              }

              final data = snapshot.data!;
              return _LoadedBody(gameId: widget.gameId, data: data);
            },
          ),
        ),
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.gameId, required this.data});

  final String gameId;
  final _FinalResultData data;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;

    return MultiBlocListener(
      listeners: [
        BlocListener<RepeatGameCubit, RepeatGameState>(
          listener: (context, state) {
            if (state is RepeatGameSuccess) {
              context.go('/games/${state.newGameId}/setup');
            } else if (state is RepeatGameFailure) {
              SnackBarHelper.showError(state.message);
            }
          },
        ),
        BlocListener<GameSyncBloc, GameSyncState>(
          listener: (context, state) {
            if (state is! GameSyncFailure || state.gameId != gameId) {
              return;
            }

            SnackBarHelper.showError(
              'No se pudo sincronizar con la nube. '
              'Puedes intentarlo de nuevo desde el historial.',
            );
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PochaAppBar(
            title: 'Resultado final',
            subtitle: '${data.roundCount} rondas',
            leading: IconButton(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home, color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.table_chart_outlined,
                  color: Colors.white,
                ),
                tooltip: 'Ver tabla de puntos',
                onPressed: () => context.push('/games/$gameId/scorecard'),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                const _SignUpBanner(),
                if (data.entries.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  WinnerCard(
                    entry: data.entries.first,
                    photoURL:
                        data.entries.first.player.userId == currentUser?.uid
                        ? currentUser?.photoUrl
                        : null,
                  ),
                ],
                if (data.entries.length > 1) ...[
                  const SizedBox(height: 16),
                  FinalStandingsList(
                    entries: data.entries.skip(1).toList(),
                    currentUserId: currentUser?.uid,
                    currentUserPhotoUrl: currentUser?.photoUrl,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RepeatGameOutlinedButton(gameId: gameId),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Nueva partida',
                  onPressed: () => context.go('/games/new'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RepeatGameOutlinedButton extends StatelessWidget {
  const _RepeatGameOutlinedButton({required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RepeatGameCubit, RepeatGameState>(
      builder: (context, state) {
        final isLoading = state is RepeatGameInProgress;

        return OutlinedButton(
          onPressed: isLoading ? null : () => _onRepeatPressed(context),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Repetir partida'),
        );
      },
    );
  }

  Future<void> _onRepeatPressed(BuildContext context) async {
    final confirmed = await showRepeatGameDialog(context);
    if (!confirmed || !context.mounted) {
      return;
    }

    await context.read<RepeatGameCubit>().repeat(
      gameId: gameId,
      source: GameHistorySource.local,
    );
  }
}

class _SignUpBanner extends StatelessWidget {
  const _SignUpBanner();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is Authenticated) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: WarningBanner(
            message: 'Crea una cuenta para guardar y compartir esta partida',
            icon: Icons.cloud_upload_outlined,
            onTap: () => context.push('/auth/sign-up'),
          ),
        );
      },
    );
  }
}

class _FinalResultData {
  const _FinalResultData({required this.entries, required this.roundCount});

  final List<RankingEntry> entries;
  final int roundCount;
}
