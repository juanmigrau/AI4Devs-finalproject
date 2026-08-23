import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/di/injection.dart';
import 'package:la_pocha/core/widgets/primary_button.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/revert_game_to_setup_usecase.dart';
import 'package:la_pocha/features/round/presentation/bloc/bidding_bloc.dart';
import 'package:la_pocha/features/round/presentation/bloc/bidding_event.dart';
import 'package:la_pocha/features/round/presentation/bloc/bidding_state.dart';
import 'package:la_pocha/features/round/presentation/widgets/bidding_player_row.dart';
import 'package:la_pocha/features/round/presentation/widgets/round_header.dart';
import 'package:la_pocha/features/round/presentation/widgets/tricks_balance_indicator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class BiddingPage extends StatefulWidget {
  const BiddingPage({
    super.key,
    required this.gameId,
    required this.roundNumber,
  });

  final String gameId;
  final int roundNumber;

  @override
  State<BiddingPage> createState() => _BiddingPageState();
}

class _BiddingPageState extends State<BiddingPage> {
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
      create: (_) => getIt<BiddingBloc>()
        ..add(
          BiddingStarted(
            gameId: widget.gameId,
            roundNumber: widget.roundNumber,
          ),
        ),
      child: _BiddingView(
        gameId: widget.gameId,
        roundNumber: widget.roundNumber,
      ),
    );
  }
}

class _BiddingView extends StatelessWidget {
  const _BiddingView({required this.gameId, required this.roundNumber});

  final String gameId;
  final int roundNumber;

  Future<void> _onBack(BuildContext context) async {
    if (roundNumber <= 1) {
      await getIt<RevertGameToSetupUseCase>()(gameId);
      if (!context.mounted) {
        return;
      }
      context.go('/games/$gameId/setup');
    } else {
      context.push(
        '/games/$gameId/rounds/${roundNumber - 1}/result',
        extra: <String, Object?>{'readOnly': true},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BiddingBloc, BiddingState>(
      listener: (context, state) {
        if (state is BiddingNavigateToPlay) {
          context.go('/games/${state.gameId}/rounds/${state.roundNumber}/play');
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) {
            return;
          }
          final bloc = context.read<BiddingBloc>();
          final current = bloc.state;
          if (current is BiddingLoaded && current.editingPlayerId != null) {
            bloc.add(const BidEditCancelled());
            return;
          }
          await _onBack(context);
        },
        child: Scaffold(
          body: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BlocBuilder<BiddingBloc, BiddingState>(
                  builder: (context, state) {
                    final cardsInRound = state is BiddingLoaded
                        ? state.round.cardsInRound
                        : null;
                    return RoundHeader(
                      gameId: gameId,
                      roundNumber: roundNumber,
                      cardsInRound: cardsInRound,
                      subtitle: 'Apuestas',
                      onBack: () {
                        _onBack(context);
                      },
                    );
                  },
                ),
                Expanded(
                  child: BlocBuilder<BiddingBloc, BiddingState>(
                    builder: (context, state) {
                      return switch (state) {
                        BiddingLoading() => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        BiddingFailure(:final message) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(message),
                          ),
                        ),
                        BiddingLoaded() => _LoadedBody(state: state),
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

  final BiddingLoaded state;

  @override
  State<_LoadedBody> createState() => _LoadedBodyState();
}

class _LoadedBodyState extends State<_LoadedBody> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _rowKeys = {};
  String? _lastScrolledPlayerId;

  BiddingLoaded get state => widget.state;

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

  BiddingPlayerRowStatus _statusFor(String playerId) {
    if (playerId == state.editingPlayerId) {
      return BiddingPlayerRowStatus.editing;
    }
    if (state.round.bids.containsKey(playerId)) {
      return BiddingPlayerRowStatus.completed;
    }
    if (playerId == state.currentPlayerId && state.editingPlayerId == null) {
      return BiddingPlayerRowStatus.active;
    }
    if (playerId == state.currentPlayerId) {
      // Current turn collapsed while another row is being edited.
      return BiddingPlayerRowStatus.pending;
    }
    return BiddingPlayerRowStatus.pending;
  }

  bool _isExpanded(BiddingPlayerRowStatus status) {
    return status == BiddingPlayerRowStatus.active ||
        status == BiddingPlayerRowStatus.editing;
  }

  void _cancelEditIfNeeded(BuildContext context) {
    if (state.editingPlayerId != null) {
      context.read<BiddingBloc>().add(const BidEditCancelled());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => _cancelEditIfNeeded(context),
          behavior: HitTestBehavior.opaque,
          child: TricksBalanceIndicator(availableTricks: state.availableTricks),
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
                      index < state.biddingOrder.length;
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
                          final playerId = state.biddingOrder[index];
                          final player = _playerById(playerId);
                          if (player == null) {
                            return const SizedBox.shrink();
                          }
                          final rowStatus = _statusFor(playerId);
                          final isExpanded = _isExpanded(rowStatus);
                          final isDealer =
                              playerId == state.round.dealerPlayerId;
                          final showForbidden =
                              isDealer &&
                              state.forbiddenBid != null &&
                              rowStatus != BiddingPlayerRowStatus.pending;
                          return KeyedSubtree(
                            key: _keyFor(playerId),
                            child: BiddingPlayerRow(
                              player: player,
                              index: index,
                              status: rowStatus,
                              bid: state.round.bids[playerId],
                              isDealer: isDealer,
                              draftBid: isExpanded ? state.draftBid : 0,
                              cardsInRound: state.round.cardsInRound,
                              forbiddenBid: showForbidden
                                  ? state.forbiddenBid
                                  : null,
                              canConfirmBid: state.canConfirmBid,
                              isSubmitting: state.isSubmitting,
                              onActivateEdit:
                                  rowStatus == BiddingPlayerRowStatus.completed
                                  ? () => context.read<BiddingBloc>().add(
                                      BidEditActivated(playerId),
                                    )
                                  : null,
                              onBidChanged: isExpanded
                                  ? (bid) => context.read<BiddingBloc>().add(
                                      BidValueChanged(bid),
                                    )
                                  : null,
                              onBidConfirmed: isExpanded
                                  ? () {
                                      final bloc = context.read<BiddingBloc>();
                                      if (rowStatus ==
                                          BiddingPlayerRowStatus.editing) {
                                        bloc.add(
                                          BidUpdated(
                                            playerId: playerId,
                                            newBid: state.draftBid,
                                          ),
                                        );
                                      } else {
                                        bloc.add(const BidConfirmed());
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
            label: 'Cerrar apuestas',
            isLoading: state.isClosing,
            onPressed: state.canClose
                ? () => context.read<BiddingBloc>().add(
                    const CloseBiddingRequested(),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
