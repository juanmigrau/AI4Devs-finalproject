import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/di/injection.dart';
import 'package:la_pocha/core/widgets/primary_button.dart';
import 'package:la_pocha/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/round/presentation/bloc/scoring_bloc.dart';
import 'package:la_pocha/features/round/presentation/bloc/scoring_event.dart';
import 'package:la_pocha/features/round/presentation/bloc/scoring_state.dart';
import 'package:la_pocha/features/round/presentation/widgets/round_header.dart';
import 'package:la_pocha/features/round/presentation/widgets/scoring_player_row.dart';
import 'package:la_pocha/features/round/presentation/widgets/tricks_balance_indicator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ScoringPage extends StatefulWidget {
  const ScoringPage({
    super.key,
    required this.gameId,
    required this.roundNumber,
  });

  final String gameId;
  final int roundNumber;

  @override
  State<ScoringPage> createState() => _ScoringPageState();
}

class _ScoringPageState extends State<ScoringPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WakelockPlus.enable();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ScoringBloc>()
        ..add(
          ScoringStarted(
            gameId: widget.gameId,
            roundNumber: widget.roundNumber,
          ),
        ),
      child: _ScoringView(
        gameId: widget.gameId,
        roundNumber: widget.roundNumber,
      ),
    );
  }
}

class _ScoringView extends StatelessWidget {
  const _ScoringView({required this.gameId, required this.roundNumber});

  final String gameId;
  final int roundNumber;

  void _onBack(BuildContext context) {
    context.go('/games/$gameId/rounds/$roundNumber/play');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScoringBloc, ScoringState>(
      listener: (context, state) {
        if (state is ScoringNavigateToResult) {
          context.go(
            '/games/${state.gameId}/rounds/${state.roundNumber}/result',
          );
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            return;
          }
          final bloc = context.read<ScoringBloc>();
          final current = bloc.state;
          if (current is ScoringLoaded && current.editingPlayerId != null) {
            bloc.add(const TricksEditCancelled());
            return;
          }
          _onBack(context);
        },
        child: Scaffold(
          body: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BlocBuilder<ScoringBloc, ScoringState>(
                  builder: (context, state) {
                    final cardsInRound = state is ScoringLoaded
                        ? state.round.cardsInRound
                        : null;
                    return RoundHeader(
                      gameId: gameId,
                      roundNumber: roundNumber,
                      cardsInRound: cardsInRound,
                      subtitle: 'Bazas reales',
                      onBack: () => _onBack(context),
                    );
                  },
                ),
                Expanded(
                  child: BlocBuilder<ScoringBloc, ScoringState>(
                    builder: (context, state) {
                      return switch (state) {
                        ScoringLoading() => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        ScoringFailure(:final message) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(message),
                          ),
                        ),
                        ScoringLoaded() => _LoadedBody(state: state),
                        _ => const SizedBox.shrink(),
                      };
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadedBody extends StatefulWidget {
  const _LoadedBody({required this.state});

  final ScoringLoaded state;

  @override
  State<_LoadedBody> createState() => _LoadedBodyState();
}

class _LoadedBodyState extends State<_LoadedBody> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _rowKeys = {};
  String? _lastScrolledPlayerId;

  ScoringLoaded get state => widget.state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
  }

  @override
  void didUpdateWidget(covariant _LoadedBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.currentPlayerId != state.currentPlayerId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(String playerId) {
    return _rowKeys.putIfAbsent(playerId, GlobalKey.new);
  }

  void _scrollToActive() {
    final playerId = state.currentPlayerId;
    if (playerId == null || playerId == _lastScrolledPlayerId) {
      return;
    }
    final ctx = _rowKeys[playerId]?.currentContext;
    if (ctx == null) {
      return;
    }
    _lastScrolledPlayerId = playerId;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.3,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  PlayerEmbed? _playerById(String playerId) {
    for (final player in state.game.players) {
      if (player.id == playerId) {
        return player;
      }
    }
    return null;
  }

  ScoringPlayerRowStatus _statusFor(String playerId) {
    if (playerId == state.editingPlayerId) {
      return ScoringPlayerRowStatus.editing;
    }
    if (state.confirmedTricks.containsKey(playerId)) {
      return ScoringPlayerRowStatus.completed;
    }
    if (playerId == state.currentPlayerId && state.editingPlayerId == null) {
      return ScoringPlayerRowStatus.active;
    }
    return ScoringPlayerRowStatus.pending;
  }

  bool _isExpanded(ScoringPlayerRowStatus status) {
    return status == ScoringPlayerRowStatus.active ||
        status == ScoringPlayerRowStatus.editing;
  }

  void _cancelEditIfNeeded(BuildContext context) {
    if (state.editingPlayerId != null) {
      context.read<ScoringBloc>().add(const TricksEditCancelled());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => _cancelEditIfNeeded(context),
          behavior: HitTestBehavior.opaque,
          child: TricksBalanceIndicator(
            availableTricks: state.remainingTricks,
            zeroIsReady: true,
          ),
        ),
        if (state.validationMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Text(
              state.validationMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colorScheme.error),
            ),
          ),
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < state.scoringOrder.length;
                      index++
                    ) ...[
                      if (index > 0)
                        Divider(
                          height: 1,
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      Builder(
                        builder: (context) {
                          final playerId = state.scoringOrder[index];
                          final player = _playerById(playerId);
                          if (player == null) {
                            return const SizedBox.shrink();
                          }
                          final rowStatus = _statusFor(playerId);
                          final isExpanded = _isExpanded(rowStatus);
                          return KeyedSubtree(
                            key: _keyFor(playerId),
                            child: ScoringPlayerRow(
                              player: player,
                              index: index,
                              photoURL: player.userId == currentUser?.uid
                                  ? currentUser?.photoUrl
                                  : null,
                              status: rowStatus,
                              tricks: state.confirmedTricks[playerId],
                              isDealer: playerId == state.round.dealerPlayerId,
                              draftTrick: isExpanded ? state.draftTrick : 0,
                              cardsInRound: state.round.cardsInRound,
                              canConfirmTrick: state.canConfirmTrick,
                              canAddMore: state.canAddMore,
                              onActivateEdit:
                                  rowStatus == ScoringPlayerRowStatus.completed
                                  ? () => context.read<ScoringBloc>().add(
                                      TricksEditActivated(playerId),
                                    )
                                  : null,
                              onTrickChanged: isExpanded
                                  ? (value) => context.read<ScoringBloc>().add(
                                      TrickValueChanged(value),
                                    )
                                  : null,
                              onTrickConfirmed: isExpanded
                                  ? () {
                                      final bloc = context.read<ScoringBloc>();
                                      if (rowStatus ==
                                          ScoringPlayerRowStatus.editing) {
                                        bloc.add(
                                          TricksUpdated(
                                            playerId: playerId,
                                            newTricks: state.draftTrick,
                                          ),
                                        );
                                      } else {
                                        bloc.add(const TricksConfirmed());
                                      }
                                    }
                                  : null,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: PrimaryButton(
            label: 'Confirmar bazas',
            isLoading: state.isClosing,
            onPressed: state.canConfirm
                ? () => context.read<ScoringBloc>().add(
                    const CloseRoundRequested(),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
