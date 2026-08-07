import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/di/injection.dart';
import 'package:la_pocha/core/router/app_router.dart';
import 'package:la_pocha/core/router/auth_refresh_notifier.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/widgets/root_scaffold_messenger_key.dart';
import 'package:la_pocha/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/round_repository.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/get_active_game_usecase.dart';
import 'package:la_pocha/features/sync/presentation/bloc/game_sync_bloc.dart';
import 'package:la_pocha/features/sync/presentation/widgets/sync_status_snackbar.dart';
import 'package:la_pocha/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await configureDependencies();

  final resumeLocation = await _resolveResumeLocation();

  final authBloc = getIt<AuthBloc>()..add(const AuthStarted());
  final gameSyncBloc = getIt<GameSyncBloc>();
  final refreshNotifier = AuthRefreshNotifier(authBloc);
  final router = createAppRouter(
    refreshListenable: refreshNotifier,
    authBloc: authBloc,
    resumeLocation: resumeLocation,
  );

  runApp(LaPochaApp(
    authBloc: authBloc,
    gameSyncBloc: gameSyncBloc,
    router: router,
  ));
}

Future<String?> _resolveResumeLocation() async {
  try {
    final activeGame = await getIt<GetActiveGameUseCase>()();
    final roundNumber = activeGame?.currentRoundNumber;
    if (activeGame == null || roundNumber == null) {
      return null;
    }

    final round = await getIt<RoundRepository>().getRoundByGameAndNumber(
      activeGame.id,
      roundNumber,
    );
    if (round == null) {
      return null;
    }

    final gameId = activeGame.id;
    return switch (round.status) {
      RoundStatus.bidding => '/games/$gameId/rounds/$roundNumber/bids',
      RoundStatus.playing => '/games/$gameId/rounds/$roundNumber/play',
      RoundStatus.closed => '/games/$gameId/rounds/$roundNumber/result',
    };
  } catch (_) {
    return null;
  }
}

class LaPochaApp extends StatelessWidget {
  const LaPochaApp({
    super.key,
    required this.authBloc,
    required this.gameSyncBloc,
    required this.router,
  });

  final AuthBloc authBloc;
  final GameSyncBloc gameSyncBloc;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<GameSyncBloc>.value(value: gameSyncBloc),
      ],
      child: SyncStatusSnackbar(
        child: MaterialApp.router(
          title: 'La Pocha',
          theme: AppTheme.light,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          routerConfig: router,
        ),
      ),
    );
  }
}
