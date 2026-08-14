import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/utils/snack_bar_helper.dart';
import 'package:la_pocha/core/widgets/pocha_app_bar.dart';
import 'package:la_pocha/core/widgets/primary_button.dart';
import 'package:la_pocha/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:la_pocha/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:la_pocha/features/auth/presentation/widgets/forgot_password_dialog.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    context.read<AuthBloc>().add(
          SignInSubmitted(
            email: _emailController.text,
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          SnackBarHelper.showError(state.message);
        }
        if (state is PasswordResetEmailSent) {
          SnackBarHelper.showSuccess(
            'Te hemos enviado un email para restablecer tu contraseña. '
            'Revisa tu bandeja de entrada.',
          );
        }
        if (state is Authenticated) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PochaAppBar(
                title: 'Iniciar sesión',
                onBack: () => context.pop(),
              ),
              Expanded(
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const SizedBox(height: 32),
                                      Text(
                                        'Bienvenido de nuevo',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          color: AppTheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Inicia sesión para acceder a tu historial',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: AppTheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      AuthTextField(
                                        label: 'Email',
                                        controller: _emailController,
                                        prefixIcon: Icons.email_outlined,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        autocorrect: false,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Introduce tu email';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      AuthTextField(
                                        label: 'Contraseña',
                                        controller: _passwordController,
                                        prefixIcon: Icons.lock_outlined,
                                        obscureText: true,
                                        textInputAction: TextInputAction.done,
                                        autocorrect: false,
                                        onFieldSubmitted: (_) => _submit(),
                                        validator: (value) {
                                          if (value == null ||
                                              value.isEmpty) {
                                            return 'Introduce tu contraseña';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: isLoading
                                              ? null
                                              : () => showForgotPasswordDialog(
                                                    context,
                                                    initialEmail:
                                                        _emailController.text,
                                                  ),
                                          child: Text(
                                            '¿Olvidaste tu contraseña?',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      PrimaryButton(
                                        label: 'Entrar',
                                        isLoading: isLoading,
                                        onPressed: _submit,
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '¿No tienes cuenta?',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: AppTheme.onSurfaceVariant,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: isLoading
                                                ? null
                                                : () => context
                                                    .push('/auth/sign-up'),
                                            child: Text(
                                              'Regístrate',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: AppTheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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
