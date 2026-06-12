import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/constants/app_constants.dart';
import 'package:planticula/core/constants/app_strings.dart';
import 'package:planticula/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:planticula/shared/widgets/app_button.dart';
import 'package:planticula/shared/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // [FIX-8] Limpiar error cuando el usuario empieza a editar los campos
    _emailController.addListener(_clearErrorOnEdit);
    _passwordController.addListener(_clearErrorOnEdit);
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearErrorOnEdit);
    _passwordController.removeListener(_clearErrorOnEdit);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrorOnEdit() {
    final bloc = context.read<AuthBloc>();
    if (bloc.state.hasError) {
      bloc.add(const AuthErrorCleared());
    }
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(AuthSignInRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ));
    }
  }

  void _onRegister() {
    context.push(AppConstants.routeRegister);
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.forgotPasswordTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(AppStrings.forgotPasswordBody),
              const SizedBox(height: 16),
              TextFormField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: AppStrings.fieldEmail,
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.fieldEmailRequired;
                  }
                  // [FIX-2] Validación con regex en lugar de solo '@'
                  if (!_isValidEmail(value.trim())) {
                    return AppStrings.fieldEmailInvalid;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                context.read<AuthBloc>().add(
                      AuthResetPasswordRequested(
                        email: resetEmailController.text.trim(),
                      ),
                    );
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text(AppStrings.send),
          ),
        ],
      ),
    ).then((_) => resetEmailController.dispose());
  }

  /// [FIX-2] Validación de email con regex estándar RFC-5322 simplificado
  static bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.hasError != current.hasError ||
            previous.successMessage != current.successMessage,
        listener: (context, state) {
          if (state.hasError && state.errorMessage != null) {
            // [FIX-8] Cerrar snackbar anterior antes de mostrar el nuevo
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: AppStrings.close,
                  textColor: Theme.of(context).colorScheme.onError,
                  onPressed: () =>
                      ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                ),
              ),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Icon(
                        Icons.local_florist,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppConstants.appName,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.appSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                      const SizedBox(height: 48),

                      // Email
                      AppTextField(
                        controller: _emailController,
                        label: AppStrings.fieldEmail,
                        hint: AppStrings.fieldEmailHint,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        // [FIX-2] autocorrect desactivado en campos de email
                        autocorrect: false,
                        enableSuggestions: false,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.fieldEmailRequired;
                          }
                          if (!_isValidEmail(value.trim())) {
                            return AppStrings.fieldEmailInvalid;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      AppTextField(
                        controller: _passwordController,
                        label: AppStrings.fieldPassword,
                        hint: AppStrings.fieldPasswordHint,
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outlined,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.fieldPasswordRequired;
                          }
                          if (value.length < 6) {
                            return AppStrings.fieldPasswordMinLength;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: state.isLoading
                              ? null
                              : () => _showForgotPasswordDialog(context),
                          child:
                              const Text(AppStrings.loginForgotPassword),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botón login
                      AppButton(
                        text: AppStrings.loginButton,
                        onPressed: state.isLoading ? null : _onLogin,
                        isLoading: state.isLoading,
                      ),
                      const SizedBox(height: 16),

                      // Link registro
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(AppStrings.loginNoAccount),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed:
                                state.isLoading ? null : _onRegister,
                            child:
                                const Text(AppStrings.loginRegisterLink),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
