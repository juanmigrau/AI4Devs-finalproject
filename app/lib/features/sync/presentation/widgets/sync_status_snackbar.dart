import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pocha/core/utils/snack_bar_helper.dart';
import 'package:la_pocha/core/widgets/root_scaffold_messenger_key.dart';
import 'package:la_pocha/features/sync/presentation/bloc/game_sync_bloc.dart';

class SyncStatusSnackbar extends StatelessWidget {
  const SyncStatusSnackbar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameSyncBloc, GameSyncState>(
      listener: (context, state) {
        switch (state) {
          case GameSyncSuccess():
            rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
            SnackBarHelper.showSuccess('Partida guardada en la nube');
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
