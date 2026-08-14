import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/di/injection.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/utils/snack_bar_helper.dart';
import 'package:la_pocha/core/widgets/final_standings_list.dart';
import 'package:la_pocha/core/widgets/pocha_app_bar.dart';
import 'package:la_pocha/core/widgets/winner_card.dart';
import 'package:la_pocha/features/history/domain/entities/game_detail.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_source.dart';
import 'package:la_pocha/features/history/domain/services/game_history_mapper.dart';
import 'package:la_pocha/features/history/presentation/bloc/delete_game_from_history_cubit.dart';
import 'package:la_pocha/features/history/presentation/bloc/game_detail_bloc.dart';
import 'package:la_pocha/features/history/presentation/bloc/repeat_game_cubit.dart';
import 'package:la_pocha/features/history/presentation/widgets/delete_game_dialog.dart';
import 'package:la_pocha/features/history/presentation/widgets/repeat_game_button.dart';
import 'package:la_pocha/features/history/presentation/widgets/source_badge.dart';

class GameDetailPage extends StatelessWidget {
  const GameDetailPage({super.key, required this.gameId, required this.source});

  final String gameId;
  final GameHistorySource source;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<GameDetailBloc>()
                ..add(GameDetailStarted(gameId: gameId, source: source)),
        ),
        BlocProvider(create: (_) => getIt<DeleteGameFromHistoryCubit>()),
        BlocProvider(create: (_) => getIt<RepeatGameCubit>()),
      ],
      child: _GameDetailView(gameId: gameId),
    );
  }
}

class _GameDetailView extends StatelessWidget {
  const _GameDetailView({required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DeleteGameFromHistoryCubit, DeleteGameFromHistoryState>(
          listener: (context, state) {
            if (state is DeleteGameFromHistorySuccess) {
              context.pop();
            } else if (state is DeleteGameFromHistoryFailure) {
              SnackBarHelper.showError(state.message);
            }
          },
        ),
        BlocListener<RepeatGameCubit, RepeatGameState>(
          listener: (context, state) {
            if (state is RepeatGameSuccess) {
              handleRepeatGameSuccess(context, state.newGameId);
            } else if (state is RepeatGameFailure) {
              SnackBarHelper.showError(state.message);
            }
          },
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<GameDetailBloc, GameDetailState>(
            builder: (context, state) {
              return switch (state) {
                GameDetailInitial() || GameDetailLoading() => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PochaAppBar(
                      title: 'Detalle de partida',
                      expanded: true,
                      onBack: () => context.pop(),
                    ),
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                ),
                GameDetailFailure(:final message) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PochaAppBar(
                      title: 'Detalle de partida',
                      expanded: true,
                      onBack: () => context.pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppTheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                GameDetailLoaded(:final detail) => _LoadedBody(detail: detail),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.detail});

  final GameDetail detail;

  Future<void> _requestDelete(BuildContext context) async {
    final confirmed = await showDeleteGameDialog(
      context,
      source: detail.source,
    );
    if (!confirmed || !context.mounted) {
      return;
    }

    await context.read<DeleteGameFromHistoryCubit>().delete(
      gameId: detail.game.id,
      source: detail.source,
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = detail.game;
    final finishedAt = game.finishedAt;
    final formattedDate = finishedAt != null
        ? const GameHistoryMapper().formatFinishedAt(finishedAt)
        : '—';
    final colorScheme = Theme.of(context).colorScheme;
    final ranking = detail.finalRanking;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PochaAppBar(
          title: 'Detalle de partida',
          expanded: true,
          onBack: () => context.pop(),
          actions: [
            IconButton(
              icon: const Icon(Icons.table_chart_outlined, color: Colors.white),
              tooltip: 'Ver tabla de puntos',
              onPressed: () =>
                  context.push('/games/${detail.game.id}/scorecard'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                formattedDate,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              SourceBadge(source: detail.source),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              if (ranking.isNotEmpty) ...[WinnerCard(entry: ranking.first)],
              if (ranking.length > 1) ...[
                const SizedBox(height: 16),
                FinalStandingsList(entries: ranking.skip(1).toList()),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: RepeatGameButton(
                  gameId: detail.game.id,
                  source: detail.source,
                ),
              ),
              const SizedBox(width: 12),
              IconButton.outlined(
                icon: const Icon(Icons.delete_outline),
                color: colorScheme.error,
                tooltip: 'Eliminar del historial',
                style: IconButton.styleFrom(
                  side: BorderSide(color: colorScheme.error),
                ),
                onPressed: () => _requestDelete(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
