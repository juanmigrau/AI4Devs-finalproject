import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/di/injection.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/utils/snack_bar_helper.dart';
import 'package:la_pocha/core/widgets/pocha_app_bar.dart';
import 'package:la_pocha/core/widgets/primary_button.dart';
import 'package:la_pocha/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/home/presentation/bloc/home_bloc.dart';
import 'package:la_pocha/features/home/presentation/widgets/debug_config_panel.dart';
import 'package:la_pocha/features/home/presentation/widgets/recent_game_tile.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeBloc>()..add(const HomeStarted()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final GlobalKey<DebugConfigPanelState> _debugPanelKey =
      GlobalKey<DebugConfigPanelState>();
  late final Future<PackageInfo> _packageInfoFuture =
      PackageInfo.fromPlatform();

  void _onNewGamePressed() {
    if (kDebugMode) {
      final committed = _debugPanelKey.currentState?.commitSequence() ?? true;
      if (!committed) {
        SnackBarHelper.showError('Secuencia inválida. Revisa el formato.');
        return;
      }
    }
    context.push('/games/new');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            PochaAppBar(
              title: 'La Pocha',
              subtitle: 'Marcador de puntos',
              expanded: true,
              actions: [
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isAuthenticated = state is Authenticated;
                    final photoURL = isAuthenticated
                        ? state.user.photoUrl
                        : null;
                    return IconButton(
                      onPressed: () => context.push(
                        isAuthenticated ? '/profile' : '/auth/sign-in',
                      ),
                      icon: photoURL != null && photoURL.isNotEmpty
                          ? CircleAvatar(
                              radius: 16,
                              backgroundImage: NetworkImage(photoURL),
                              onBackgroundImageError: (_, _) {},
                            )
                          : const Icon(
                              Icons.account_circle_outlined,
                              color: Colors.white,
                            ),
                      tooltip: 'Mi cuenta',
                    );
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: PrimaryButton(
                label: 'Nueva partida',
                icon: Icons.add,
                onPressed: _onNewGamePressed,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(
                'ÚLTIMAS PARTIDAS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  return switch (state) {
                    HomeLoading() || HomeInitial() => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    HomeLoaded(:final recentGames) => _RecentGamesList(
                      games: recentGames,
                    ),
                    HomeEmpty() => const _RecentGamesEmpty(),
                    HomeFailure(:final message) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  };
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: OutlinedButton.icon(
                onPressed: () => context.push('/rules'),
                icon: const Icon(Icons.help_outline),
                label: const Text('¿Cómo se juega?'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
            if (kDebugMode) DebugConfigPanel(key: _debugPanelKey),
            FutureBuilder<PackageInfo>(
              future: _packageInfoFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final info = snapshot.data!;
                final versionLabel = kDebugMode
                    ? 'v${info.version}+${info.buildNumber} (debug)'
                    : 'v${info.version}';
                return Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  child: Text(
                    versionLabel,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentGamesList extends StatelessWidget {
  const _RecentGamesList({required this.games});

  final List<GameHistoryItem> games;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < games.length; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          RecentGameTile(
            item: games[index],
            onTap: () =>
                context.push('/history/${games[index].id}?source=local'),
          ),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push('/history'),
            child: Text(
              'Ver todas →',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppTheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentGamesEmpty extends StatelessWidget {
  const _RecentGamesEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(
            Icons.style,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'Crea tu primera partida para empezar',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
