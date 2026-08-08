import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/widgets/root_scaffold_messenger_key.dart';
import 'package:la_pocha/features/sync/presentation/bloc/game_sync_bloc.dart';

class SyncStatusSnackbar extends StatelessWidget {
  const SyncStatusSnackbar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameSyncBloc, GameSyncState>(
      listener: (context, state) {
        final messenger = rootScaffoldMessengerKey.currentState;
        if (messenger == null) {
          return;
        }
        messenger.hideCurrentSnackBar();

        switch (state) {
          case GameSyncSuccess():
            messenger.showSnackBar(
              SnackBar(
                content: const Text('Partida guardada en la nube'),
                backgroundColor: AppTheme.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          case GameSyncFailure():
          case GameSyncInProgress():
          case GameSyncIdle():
            break;
        }
      },
      child: child,
    );
  }
}
