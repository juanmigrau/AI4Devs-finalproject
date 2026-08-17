import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/di/injection.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/utils/snack_bar_helper.dart';
import 'package:la_pocha/core/widgets/player_initial_avatar.dart';
import 'package:la_pocha/core/widgets/pocha_app_bar.dart';
import 'package:la_pocha/features/auth/domain/entities/player_stats.dart';
import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';
import 'package:la_pocha/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:la_pocha/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:la_pocha/features/auth/presentation/widgets/reauth_password_dialog.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(const ProfileStarted()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  bool _isEditing = false;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startEditing(UserProfile user) {
    _nameController.text = user.displayName;
    setState(() => _isEditing = true);
  }

  void _submitName() {
    context.read<ProfileBloc>().add(
      ProfileDisplayNameSubmitted(_nameController.text),
    );
    setState(() => _isEditing = false);
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Seguro que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      context.read<AuthBloc>().add(const SignOutRequested());
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('¿Eliminar tu cuenta?'),
          content: const Text(
            'Esta acción es irreversible. Se eliminarán tus datos de usuario. '
            'Las partidas guardadas en la nube permanecerán accesibles para '
            'los demás participantes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: const Text('Eliminar cuenta'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      context.read<ProfileBloc>().add(const DeleteAccountRequested());
    }
  }

  Future<void> _promptReauthPassword() async {
    final password = await showReauthPasswordDialog(context);
    if (password != null && password.isNotEmpty && mounted) {
      context.read<ProfileBloc>().add(
        DeleteAccountRequested(password: password),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthFailure) {
              SnackBarHelper.showError(state.message);
            }
            if (state is Unauthenticated) {
              context.go('/');
            }
          },
        ),
        BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileFailure) {
              SnackBarHelper.showError(state.message);
            }
            if (state is ProfileLoaded && state.displayNameUpdated) {
              context.read<AuthBloc>().add(AuthProfileUpdated(state.user));
              SnackBarHelper.showSuccess('Nombre actualizado correctamente');
            }
            if (state is AccountDeleteFailure) {
              SnackBarHelper.showError(state.message);
            }
            if (state is AccountReauthRequired) {
              _promptReauthPassword();
            }
            if (state is AccountDeleted) {
              context.go('/');
            }
          },
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PochaAppBar(title: 'Mi cuenta', onBack: () => context.pop()),
              Expanded(
                child: BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, state) {
                    if (state is ProfileLoading ||
                        state is ProfileInitial ||
                        state is AccountDeleting ||
                        state is AccountDeleted) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is! ProfileLoaded) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProfileHeader(
                            user: state.user,
                            isEditing: _isEditing,
                            nameController: _nameController,
                            onEdit: () => _startEditing(state.user),
                            onConfirm: _submitName,
                          ),
                          const Divider(height: 32),
                          Expanded(
                            child: _StatsSection(
                              stats: state.stats,
                              statsLoading: state.statsLoading,
                            ),
                          ),
                          const Divider(height: 24),
                          OutlinedButton.icon(
                            onPressed: _confirmSignOut,
                            icon: const Icon(Icons.logout),
                            label: const Text('Cerrar sesión'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                            ),
                            onPressed: _confirmDeleteAccount,
                            child: Text(
                              'Eliminar cuenta',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.isEditing,
    required this.nameController,
    required this.onEdit,
    required this.onConfirm,
  });

  final UserProfile user;
  final bool isEditing;
  final TextEditingController nameController;
  final VoidCallback onEdit;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        PlayerInitialAvatar(
          name: user.displayName,
          colorIndex: 0,
          photoURL: user.photoUrl,
          radius: 28,
        ),
        const SizedBox(width: 16),
        if (isEditing)
          Expanded(
            child: TextField(
              controller: nameController,
              autofocus: true,
              maxLength: 20,
              decoration: const InputDecoration(isDense: true, counterText: ''),
              onSubmitted: (_) => onConfirm(),
            ),
          )
        else
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        IconButton(
          onPressed: isEditing ? onConfirm : onEdit,
          icon: Icon(
            isEditing ? Icons.check_circle_outline : Icons.edit_outlined,
            color: isEditing ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.stats, required this.statsLoading});

  final PlayerStats? stats;
  final bool statsLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'MIS ESTADÍSTICAS',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppTheme.onSurfaceVariant,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (statsLoading)
          const _StatsSkeleton()
        else if (stats == null || stats!.totalGames == 0)
          Expanded(
            child: Center(
              child: Text(
                'Tus estadísticas aparecerán aquí cuando juegues partidas con sesión iniciada. Las partidas jugadas como invitado no se contabilizan.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: SingleChildScrollView(child: _StatsContent(stats: stats!)),
          ),
      ],
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.stats});

  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            _StatCard(
              value: '${stats.totalGames}',
              label: 'Partidas',
              icon: Icons.sports_esports_outlined,
            ),
            _StatCard(
              value: '${stats.wins}',
              label: 'Victorias',
              icon: Icons.emoji_events_outlined,
            ),
            _StatCard(
              value: '${stats.winPercentage.round()}%',
              label: '% victorias',
              icon: Icons.bar_chart_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _StatCard(
              value: '${stats.bidAccuracyPercentage.round()}%',
              label: 'Acierto\napuestas',
              icon: Icons.gps_fixed_outlined,
            ),
            _StatCard(
              value: stats.averagePosition.toStringAsFixed(1),
              label: 'Pos. media',
              icon: Icons.leaderboard_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _StatCard(
              value: '${stats.recordScore}',
              label: 'Récord pts',
              icon: Icons.trending_up_outlined,
              color: colorScheme.primary,
            ),
            _StatCard(
              value: '${stats.worstScore}',
              label: 'Peor pts',
              icon: Icons.trending_down_outlined,
              color: colorScheme.error,
            ),
            _StatCard(
              value: '${stats.currentWinStreak}',
              label: 'Racha actual',
              icon: Icons.local_fire_department_outlined,
              color: colorScheme.tertiary,
            ),
          ],
        ),
        if (stats.mostFrequentPartner != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Compañero frecuente: ${stats.mostFrequentPartner}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppTheme.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color ?? theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSkeleton extends StatefulWidget {
  const _StatsSkeleton();

  @override
  State<_StatsSkeleton> createState() => _StatsSkeletonState();
}

class _StatsSkeletonState extends State<_StatsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.35 + (_controller.value * 0.4);
        return Opacity(opacity: opacity, child: child);
      },
      child: Column(
        children: [
          Row(children: List.generate(3, (_) => const _SkeletonCell())),
          const SizedBox(height: 16),
          Row(children: List.generate(2, (_) => const _SkeletonCell())),
          const SizedBox(height: 16),
          Row(children: List.generate(3, (_) => const _SkeletonCell())),
        ],
      ),
    );
  }
}

class _SkeletonCell extends StatelessWidget {
  const _SkeletonCell();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 22,
            decoration: BoxDecoration(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 56,
            height: 12,
            decoration: BoxDecoration(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
