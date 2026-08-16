import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/di/injection.dart';
import 'package:la_pocha/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:la_pocha/features/round/domain/usecases/revert_round_to_bidding_usecase.dart';
import 'package:la_pocha/features/round/presentation/bloc/play_state_bloc.dart';
import 'package:la_pocha/features/round/presentation/bloc/play_state_event.dart';
import 'package:la_pocha/features/round/presentation/bloc/play_state_state.dart';
import 'package:la_pocha/features/round/presentation/widgets/player_play_card.dart';
import 'package:la_pocha/features/round/presentation/widgets/round_header.dart';
import 'package:la_pocha/features/round/presentation/widgets/tricks_balance_banner.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({super.key, required this.gameId, required this.roundNumber});

  final String gameId;
  final int roundNumber;

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PlayStateBloc>()
        ..add(
          PlayStateStarted(
            gameId: widget.gameId,
            roundNumber: widget.roundNumber,
          ),
        ),
      child: _PlayView(gameId: widget.gameId, roundNumber: widget.roundNumber),
    );
  }
}

class _PlayView extends StatelessWidget {
  const _PlayView({required this.gameId, required this.roundNumber});

  final String gameId;
  final int roundNumber;

  Future<void> _goToBidding(BuildContext context) async {
    await getIt<RevertRoundToBiddingUseCase>()(
      gameId: gameId,
      roundNumber: roundNumber,
    );
    if (!context.mounted) {
      return;
    }
    context.go('/games/$gameId/rounds/$roundNumber/bids');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlayStateBloc, PlayStateBlocState>(
      listener: (context, state) {
        if (state is PlayStateNavigateToTricks) {
          context.go(
            '/games/${state.gameId}/rounds/${state.roundNumber}/tricks',
          );
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            return;
          }
          _goToBidding(context);
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BlocBuilder<PlayStateBloc, PlayStateBlocState>(
                  builder: (context, state) {
                    final cardsInRound = state is PlayStateLoaded
                        ? state.playState.round.cardsInRound
                        : null;
                    return RoundHeader(
                      gameId: gameId,
                      roundNumber: roundNumber,
                      cardsInRound: cardsInRound,
                      subtitle: 'En juego',
                      onBack: () => _goToBidding(context),
                    );
                  },
                ),
                Expanded(
                  child: BlocBuilder<PlayStateBloc, PlayStateBlocState>(
                    builder: (context, state) {
                      return switch (state) {
                        PlayStateLoading() => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        PlayStateFailure(:final message) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(message),
                          ),
                        ),
                        PlayStateLoaded() => _LoadedBody(state: state),
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

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.state});

  static const Color _warningColor = Color(0xFFD9772E);

  final PlayStateLoaded state;

  @override
  Widget build(BuildContext context) {
    final playState = state.playState;
    final colorScheme = Theme.of(context).colorScheme;
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TricksBalanceBanner(
          bidSum: playState.bidSum,
          cardsInRound: playState.round.cardsInRound,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Expanded(flex: 3, child: SizedBox()),
                    SizedBox(
                      width: 52,
                      child: Text(
                        'Bazas',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: Text(
                        'Pts',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
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
                      index < playState.players.length;
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
                          final player = playState.players[index];
                          return PlayerPlayCard(
                            player: player,
                            index: index,
                            bid: playState.round.bids[player.id] ?? 0,
                            isDealer:
                                player.id == playState.round.dealerPlayerId,
                            photoURL: player.userId == currentUser?.uid
                                ? currentUser?.photoUrl
                                : null,
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
        if (!playState.restrictionMet)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Text(
              'La suma de apuestas iguala ${playState.round.cardsInRound}. '
              'El repartidor debe corregir su apuesta antes de continuar.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: _warningColor),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: FilledButton(
            onPressed: playState.restrictionMet
                ? () => context.read<PlayStateBloc>().add(
                    const IntroduceTricksRequested(),
                  )
                : null,
            child: const Text('Introducir bazas reales'),
          ),
        ),
      ],
    );
  }
}
