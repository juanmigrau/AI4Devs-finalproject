import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/di/injection.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/utils/snack_bar_helper.dart';
import 'package:la_pocha/core/widgets/pocha_app_bar.dart';
import 'package:la_pocha/core/widgets/warning_banner.dart';
import 'package:la_pocha/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/history/presentation/bloc/delete_game_from_history_cubit.dart';
import 'package:la_pocha/features/history/presentation/bloc/history_list_bloc.dart';
import 'package:la_pocha/features/history/presentation/widgets/delete_game_dialog.dart';
import 'package:la_pocha/features/history/presentation/widgets/delete_game_slidable.dart';
import 'package:la_pocha/features/history/presentation/widgets/empty_history_view.dart';

class HistoryListPage extends StatelessWidget {
  const HistoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<HistoryListBloc>()..add(const HistoryListStarted()),
        ),
        BlocProvider(create: (_) => getIt<DeleteGameFromHistoryCubit>()),
      ],
      child: const _HistoryListView(),
    );
  }
}

class _HistoryListView extends StatelessWidget {
  const _HistoryListView();

  Future<void> _requestDelete(
    BuildContext context,
    GameHistoryItem item,
  ) async {
    final confirmed = await showDeleteGameDialog(context, source: item.source);
    if (!confirmed || !context.mounted) {
      return;
    }

    final cubit = context.read<DeleteGameFromHistoryCubit>();
    await cubit.delete(gameId: item.id, source: item.source);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DeleteGameFromHistoryCubit, DeleteGameFromHistoryState>(
          listener: (context, state) {
            if (state is DeleteGameFromHistorySuccess) {
              context.read<HistoryListBloc>().add(
                HistoryListGameDeleted(state.gameId),
              );
            } else if (state is DeleteGameFromHistoryFailure) {
              SnackBarHelper.showError(state.message);
            }
          },
        ),
        BlocListener<HistoryListBloc, HistoryListState>(
          listenWhen: (previous, current) {
            if (current is! HistoryListLoaded ||
                current.syncRetryFeedback == null) {
              return false;
            }
            final previousFeedback = previous is HistoryListLoaded
                ? previous.syncRetryFeedback
                : null;
            return previousFeedback != current.syncRetryFeedback;
          },
          listener: (context, state) {
            if (state is! HistoryListLoaded) {
              return;
            }
            switch (state.syncRetryFeedback) {
              case HistorySyncRetryFeedback.success:
                SnackBarHelper.showSuccess(
                  'Partida sincronizada correctamente',
                );
              case HistorySyncRetryFeedback.failure:
                SnackBarHelper.showError(
                  'No se pudo sincronizar. Comprueba '
                  'tu conexión e inténtalo de nuevo.',
                );
              case null:
                break;
            }
          },
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PochaAppBar(
                title: 'Historial',
                expanded: true,
                onBack: () => context.pop(),
              ),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  if (authState is! Authenticated) {
                    return const SizedBox.shrink();
                  }
                  return BlocBuilder<HistoryListBloc, HistoryListState>(
                    buildWhen: (previous, current) {
                      if (previous.runtimeType != current.runtimeType) {
                        return true;
                      }
                      if (previous is HistoryListLoaded &&
                          current is HistoryListLoaded) {
                        final previousPending = previous.items
                            .where((item) => item.needsSyncRetry)
                            .length;
                        final currentPending = current.items
                            .where((item) => item.needsSyncRetry)
                            .length;
                        return previous.cloudError != current.cloudError ||
                            previousPending != currentPending;
                      }
                      return false;
                    },
                    builder: (context, historyState) {
                      if (historyState is! HistoryListLoaded) {
                        return const SizedBox.shrink();
                      }

                      final pendingCount = historyState.items
                          .where((item) => item.needsSyncRetry)
                          .length;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (pendingCount > 0)
                            _PendingSyncBanner(pendingCount: pendingCount),
                          if (historyState.cloudError)
                            const _OfflineSyncBanner(),
                        ],
                      );
                    },
                  );
                },
              ),
              Expanded(
                child: BlocBuilder<HistoryListBloc, HistoryListState>(
                  builder: (context, state) {
                    return switch (state) {
                      HistoryListInitial() || HistoryListLoading() =>
                        const Center(child: CircularProgressIndicator()),
                      HistoryListEmpty() => const EmptyHistoryView(),
                      HistoryListFailure(:final message) => Center(
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
                      HistoryListLoaded(:final items) => RefreshIndicator(
                        onRefresh: () async {
                          context.read<HistoryListBloc>().add(
                            const HistoryListRefreshed(),
                          );
                          await context
                              .read<HistoryListBloc>()
                              .stream
                              .firstWhere(
                                (state) =>
                                    state is HistoryListLoaded ||
                                    state is HistoryListEmpty ||
                                    state is HistoryListFailure,
                              );
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return DeleteGameSlidable(
                              item: item,
                              onTap: () => context.push(
                                '/history/${item.id}?source=${item.source.name}',
                              ),
                              onDeleteRequested: () =>
                                  _requestDelete(context, item),
                            );
                          },
                        ),
                      ),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingSyncBanner extends StatelessWidget {
  const _PendingSyncBanner({required this.pendingCount});

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final n = pendingCount;
    final message =
        '$n partida${n == 1 ? '' : 's'} pendiente${n == 1 ? '' : 's'} '
        'de sincronizar.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: WarningBanner(
        message: message,
        icon: Icons.cloud_sync_outlined,
        onTap: () => context.read<HistoryListBloc>().add(
          const SyncAllPendingRequested(),
        ),
      ),
    );
  }
}

class _OfflineSyncBanner extends StatelessWidget {
  const _OfflineSyncBanner();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: WarningBanner(
        message: 'Sin conexión a la nube: mostrando solo datos locales.',
        icon: Icons.cloud_off,
      ),
    );
  }
}
