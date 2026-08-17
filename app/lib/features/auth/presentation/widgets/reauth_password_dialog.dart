import 'package:flutter/material.dart';

Future<String?> showReauthPasswordDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => const ReauthPasswordDialog(),
  );
}

class ReauthPasswordDialog extends StatefulWidget {
  const ReauthPasswordDialog({super.key});

  @override
  State<ReauthPasswordDialog> createState() => _ReauthPasswordDialogState();
}

class _ReauthPasswordDialogState extends State<ReauthPasswordDialog> {
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      return;
    }
    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirma tu identidad'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Por seguridad, introduce tu contraseña para continuar.'),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Contraseña'),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _submit, child: const Text('Confirmar')),
      ],
    );
  }
}
