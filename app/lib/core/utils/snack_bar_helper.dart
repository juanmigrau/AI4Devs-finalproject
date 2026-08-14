import 'package:flutter/material.dart';
import 'package:la_pocha/core/widgets/root_scaffold_messenger_key.dart';

class SnackBarHelper {
  SnackBarHelper._();

  static void showSuccess(String message, {SnackBarAction? action}) {
    final messenger = rootScaffoldMessengerKey.currentState;
    final context = rootScaffoldMessengerKey.currentContext;
    if (messenger == null || context == null) {
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: colorScheme.onInverseSurface),
        ),
        backgroundColor: colorScheme.inverseSurface,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: action,
      ),
    );
  }

  static void showError(String message) {
    final messenger = rootScaffoldMessengerKey.currentState;
    final context = rootScaffoldMessengerKey.currentContext;
    if (messenger == null || context == null) {
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: colorScheme.onErrorContainer),
        ),
        backgroundColor: colorScheme.errorContainer,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
