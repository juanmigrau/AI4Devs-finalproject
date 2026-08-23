import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/di/injection.dart';
import 'package:la_pocha/core/errors/user_facing_error_mapper.dart';
import 'package:la_pocha/core/widgets/pocha_app_bar.dart';
import 'package:la_pocha/features/round/domain/entities/game_stats.dart';
import 'package:la_pocha/features/round/domain/entities/scorecard_row.dart';
import 'package:la_pocha/features/round/domain/usecases/get_game_scorecard_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/get_game_stats_usecase.dart';
import 'package:la_pocha/features/round/presentation/widgets/game_progress_chart.dart';
import 'package:la_pocha/features/round/presentation/widgets/game_stats_tab.dart';
import 'package:la_pocha/features/round/presentation/widgets/scorecard_table.dart';

class ScorecardPage extends StatefulWidget {
  const ScorecardPage({super.key, required this.gameId});

  final String gameId;

  @override
  State<ScorecardPage> createState() => _ScorecardPageState();
}

class _ScorecardLoad {
  const _ScorecardLoad({
    required this.scorecard,
    required this.stats,
  });

  final GameScorecard scorecard;
  final GameStats stats;
}

class _ScorecardPageState extends State<ScorecardPage> {
  late Future<_ScorecardLoad> _loadFuture;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _loadFuture = _load();
  }

  Future<_ScorecardLoad> _load() async {
    final results = await Future.wait([
      getIt<GetGameScorecardUseCase>()(gameId: widget.gameId),
      getIt<GetGameStatsUseCase>()(gameId: widget.gameId),
    ]);
    return _ScorecardLoad(
      scorecard: results[0] as GameScorecard,
      stats: results[1] as GameStats,
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PochaAppBar(
                title: 'Tabla de partida',
                onBack: () => context.pop(),
              ),
              Material(
                color: Theme.of(context).colorScheme.surface,
                child: TabBar(
                  tabs: const [
                    Tab(text: 'Tabla'),
                    Tab(text: 'Stats'),
                    Tab(text: 'Gráfica'),
                  ],
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              Expanded(
                child: FutureBuilder<_ScorecardLoad>(
                  future: _loadFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            mapExceptionToUserMessage(snapshot.error!),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final load = snapshot.data!;
                    final scorecard = load.scorecard;
                    final stats = load.stats;

                    return TabBarView(
                      children: [
                        scorecard.rows.isEmpty
                            ? const Center(
                                child: Text('Aún no hay rondas para mostrar'),
                              )
                            : Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                child: ScorecardTable(
                                  players: scorecard.players,
                                  rows: scorecard.rows,
                                ),
                              ),
                        GameStatsTab(stats: stats),
                        GameProgressChart(stats: stats),
                      ],
                    );
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
