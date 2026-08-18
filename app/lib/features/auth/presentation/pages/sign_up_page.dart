import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/utils/snack_bar_helper.dart';
import 'package:la_pocha/core/widgets/pocha_app_bar.dart';
import 'package:la_pocha/core/widgets/primary_button.dart';
import 'package:la_pocha/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:la_pocha/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:la_pocha/features/auth/presentation/widgets/google_sign_in_button.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    context.read<AuthBloc>().add(
      SignUpSubmitted(
        displayName: _displayNameController.text,
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
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PochaAppBar(title: 'Crear cuenta', onBack: () => context.pop()),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const SizedBox(height: 32),
                                      Text(
                                        'Crea una cuenta',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              color: AppTheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Crea una cuenta para guardar tu '
                                        'historial en la nube',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: AppTheme.onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 32),
                                      AuthTextField(
                                        label: 'Nombre visible',
                                        controller: _displayNameController,
                                        prefixIcon: Icons.person_outlined,
                                        maxLength: 20,
                                        textInputAction: TextInputAction.next,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'El nombre es obligatorio';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
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
                                              value.length < 6) {
                                            return 'Mínimo 6 caracteres';
                                          }
                                          return null;
                                        },
                                      ),
                                      const Spacer(),
                                      PrimaryButton(
                                        label: 'Crear cuenta',
                                        isLoading: isLoading,
                                        onPressed: _submit,
                                      ),
                                      const SizedBox(height: 16),
                                      GoogleSignInButton(
                                        isLoading: isLoading,
                                        onPressed: () => context
                                            .read<AuthBloc>()
                                            .add(const GoogleSignInSubmitted()),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '¿Ya tienes cuenta?',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      AppTheme.onSurfaceVariant,
                                                ),
                                          ),
                                          TextButton(
                                            onPressed: isLoading
                                                ? null
                                                : () => context.push(
                                                    '/auth/sign-in',
                                                  ),
                                            child: Text(
                                              'Inicia sesión',
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
