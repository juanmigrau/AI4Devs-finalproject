import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/di/injection.dart';
import 'package:la_pocha/core/widgets/primary_button.dart';
import 'package:la_pocha/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:la_pocha/features/round/domain/entities/round_result.dart';
import 'package:la_pocha/features/round/domain/usecases/revert_round_to_playing_usecase.dart';
import 'package:la_pocha/features/round/presentation/bloc/round_result_bloc.dart';
import 'package:la_pocha/features/round/presentation/bloc/round_result_event.dart';
import 'package:la_pocha/features/round/presentation/bloc/round_result_state.dart';
import 'package:la_pocha/features/round/presentation/widgets/round_header.dart';
import 'package:la_pocha/features/round/presentation/widgets/round_result_player_row.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class RoundResultPage extends StatefulWidget {
  const RoundResultPage({
    super.key,
    required this.gameId,
    required this.roundNumber,
    this.readOnly = false,
  });

  final String gameId;
  final int roundNumber;
  final bool readOnly;

  @override
  State<RoundResultPage> createState() => _RoundResultPageState();
}

class _RoundResultPageState extends State<RoundResultPage> {
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
      create: (_) => getIt<RoundResultBloc>()
        ..add(
          RoundResultStarted(
            gameId: widget.gameId,
            roundNumber: widget.roundNumber,
          ),
        ),
      child: _RoundResultView(
        gameId: widget.gameId,
        roundNumber: widget.roundNumber,
        readOnly: widget.readOnly,
      ),
    );
  }
}

class _RoundResultView extends StatelessWidget {
  const _RoundResultView({
    required this.gameId,
    required this.roundNumber,
    required this.readOnly,
  });

  final String gameId;
  final int roundNumber;
  final bool readOnly;

  Future<void> _goToScoring(BuildContext context) async {
    await getIt<RevertRoundToPlayingUseCase>()(
      gameId: gameId,
      roundNumber: roundNumber,
    );
    if (!context.mounted) {
      return;
    }
    context.go('/games/$gameId/rounds/$roundNumber/tricks');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoundResultBloc, RoundResultState>(
      listener: (context, state) {
        if (state is RoundResultNavigateToBids) {
          context.go('/games/${state.gameId}/rounds/${state.roundNumber}/bids');
        } else if (state is RoundResultNavigateToFinal) {
          context.go('/games/${state.gameId}/final');
        }
      },
      child: PopScope(
        canPop: readOnly,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop || readOnly) {
            return;
          }
          _goToScoring(context);
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BlocBuilder<RoundResultBloc, RoundResultState>(
                  builder: (context, state) {
                    final cardsInRound = switch (state) {
                      RoundResultLoaded(:final result) =>
                        result.round.cardsInRound,
                      RoundResultAdvancing(:final result) =>
                        result.round.cardsInRound,
                      _ => null,
                    };
                    return RoundHeader(
                      gameId: gameId,
                      roundNumber: roundNumber,
                      cardsInRound: cardsInRound,
                      subtitle: 'Resultado',
                      repeatRoundNumber: readOnly ? null : roundNumber,
                      onBack: readOnly ? null : () => _goToScoring(context),
                    );
                  },
                ),
                Expanded(
                  child: BlocBuilder<RoundResultBloc, RoundResultState>(
                    builder: (context, state) {
                      return switch (state) {
                        RoundResultLoading() => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        RoundResultFailure(:final message) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(message),
                          ),
                        ),
                        RoundResultLoaded(:final result) ||
                        RoundResultAdvancing(:final result) => _LoadedBody(
                          result: result,
                          isAdvancing: state is RoundResultAdvancing,
                          readOnly: readOnly,
                        ),
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
  const _LoadedBody({
    required this.result,
    required this.isAdvancing,
    required this.readOnly,
  });

  final RoundResult result;
  final bool isAdvancing;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.style, color: colorScheme.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                result.dealerDisplayName,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
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
                        'Ronda',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: Text(
                        'Total',
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
                      index < result.entries.length;
                      index++
                    ) ...[
                      if (index > 0)
                        Divider(
                          height: 1,
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      RoundResultPlayerRow(
                        entry: result.entries[index],
                        photoURL:
                            result.entries[index].player.userId ==
                                currentUser?.uid
                            ? currentUser?.photoUrl
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!readOnly)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: PrimaryButton(
              label: result.isLastRound
                  ? 'Ver resultado final'
                  : 'Siguiente ronda',
              isLoading: isAdvancing,
              onPressed: () {
                if (result.isLastRound) {
                  context.read<RoundResultBloc>().add(
                    const FinishGameRequested(),
                  );
                } else {
                  context.read<RoundResultBloc>().add(
                    const AdvanceToNextRoundRequested(),
                  );
                }
              },
            ),
          ),
      ],
    );
  }
}
