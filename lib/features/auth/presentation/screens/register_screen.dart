import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/constants/app_strings.dart';
import 'package:planticula/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:planticula/shared/widgets/app_button.dart';
import 'package:planticula/shared/widgets/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    // [FIX-8] Limpiar error cuando el usuario empieza a editar los campos
    _nameController.addListener(_clearErrorOnEdit);
    _emailController.addListener(_clearErrorOnEdit);
    _passwordController.addListener(_clearErrorOnEdit);
    _confirmPasswordController.addListener(_clearErrorOnEdit);
  }

  @override
  void dispose() {
    _nameController.removeListener(_clearErrorOnEdit);
    _emailController.removeListener(_clearErrorOnEdit);
    _passwordController.removeListener(_clearErrorOnEdit);
    _confirmPasswordController.removeListener(_clearErrorOnEdit);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearErrorOnEdit() {
    final bloc = context.read<AuthBloc>();
    if (bloc.state.hasError) {
      bloc.add(const AuthErrorCleared());
    }
  }

  void _onRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_acceptTerms) {
        // [FIX-8] Snackbar consistente con los demás
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.registerTermsError),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      context.read<AuthBloc>().add(AuthSignUpRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            // [FIX-11] trim() evita que un nombre solo de espacios pase la validación
            displayName: _nameController.text.trim(),
          ));
    }
  }

  /// [FIX-2] Validación de email con regex estándar
  static bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.registerTitle),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.hasError != current.hasError ||
            previous.isAuthenticated != current.isAuthenticated,
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
          // [FIX-9] Redirigir a home tras registro exitoso
          // GoRouter's redirect lo gestiona automáticamente cuando
          // isAuthenticated cambia, pero hacemos pop() explícito por si
          // el router no redirige desde esta ruta hija.
          if (state.isAuthenticated && context.canPop()) {
            context.pop();
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.registerWelcome,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.registerSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                    const SizedBox(height: 32),

                    // Nombre
                    AppTextField(
                      controller: _nameController,
                      label: AppStrings.fieldName,
                      hint: AppStrings.fieldNameHint,
                      prefixIcon: Icons.person_outlined,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        // [FIX-11] trim() para detectar nombres solo de espacios
                        if (value == null || value.trim().isEmpty) {
                          return AppStrings.fieldNameRequired;
                        }
                        if (value.trim().length < 2) {
                          return AppStrings.fieldNameTooShort;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    AppTextField(
                      controller: _emailController,
                      label: AppStrings.fieldEmail,
                      hint: AppStrings.fieldEmailHint,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      autocorrect: false,
                      enableSuggestions: false,
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
                    const SizedBox(height: 16),

                    // Contraseña
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
                    const SizedBox(height: 16),

                    // Confirmar contraseña
                    AppTextField(
                      controller: _confirmPasswordController,
                      label: AppStrings.fieldPasswordConfirm,
                      hint: AppStrings.fieldPasswordHint,
                      obscureText: _obscureConfirmPassword,
                      prefixIcon: Icons.lock_outlined,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppStrings.fieldPasswordConfirmError;
                        }
                        if (value != _passwordController.text) {
                          return AppStrings.fieldPasswordMismatch;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Términos y condiciones
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: state.isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _acceptTerms = value ?? false;
                                  });
                                },
                        ),
                        Expanded(
                          child: Text(
                            AppStrings.registerTermsCheckbox,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Botón registro
                    AppButton(
                      text: AppStrings.registerButton,
                      onPressed: state.isLoading ? null : _onRegister,
                      isLoading: state.isLoading,
                    ),
                    const SizedBox(height: 16),

                    // Link login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(AppStrings.registerHasAccount),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed:
                              state.isLoading ? null : () => context.pop(),
                          child: const Text(AppStrings.registerLoginLink),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
