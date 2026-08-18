import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/di/injection.dart';
import 'package:la_pocha/core/errors/user_facing_error_mapper.dart';
import 'package:la_pocha/core/widgets/pocha_app_bar.dart';
import 'package:la_pocha/features/round/domain/entities/scorecard_row.dart';
import 'package:la_pocha/features/round/domain/usecases/get_game_scorecard_usecase.dart';
import 'package:la_pocha/features/round/presentation/widgets/scorecard_table.dart';

class ScorecardPage extends StatefulWidget {
  const ScorecardPage({super.key, required this.gameId});

  final String gameId;

  @override
  State<ScorecardPage> createState() => _ScorecardPageState();
}

class _ScorecardPageState extends State<ScorecardPage> {
  late Future<GameScorecard> _loadFuture;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _loadFuture = getIt<GetGameScorecardUseCase>()(gameId: widget.gameId);
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
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PochaAppBar(title: 'Tabla de partida', onBack: () => context.pop()),
            Expanded(
              child: FutureBuilder<GameScorecard>(
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

                  final scorecard = snapshot.data!;
                  if (scorecard.rows.isEmpty) {
                    return const Center(
                      child: Text('Aún no hay rondas para mostrar'),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: ScorecardTable(
                      players: scorecard.players,
                      rows: scorecard.rows,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
