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
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.registerTermsError),
          ),
        );
        return;
      }

      context.read<AuthBloc>().add(AuthSignUpRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.registerTitle),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? AppStrings.unknownError),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
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

                    // Name field
                    AppTextField(
                      controller: _nameController,
                      label: AppStrings.fieldName,
                      hint: AppStrings.fieldNameHint,
                      prefixIcon: Icons.person_outlined,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return AppStrings.fieldNameRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email field
                    AppTextField(
                      controller: _emailController,
                      label: AppStrings.fieldEmail,
                      hint: AppStrings.fieldEmailHint,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return AppStrings.fieldEmailRequired;
                        }
                        if (!value!.contains('@')) {
                          return AppStrings.fieldEmailInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field
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
                        if (value?.isEmpty ?? true) {
                          return AppStrings.fieldPasswordRequired;
                        }
                        if (value!.length < 6) {
                          return AppStrings.fieldPasswordMinLength;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm password field
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
                        if (value?.isEmpty ?? true) {
                          return AppStrings.fieldPasswordConfirmError;
                        }
                        if (value != _passwordController.text) {
                          return AppStrings.fieldPasswordMismatch;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Terms checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) {
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

                    // Register button
                    AppButton(
                      text: AppStrings.registerButton,
                      onPressed: _onRegister,
                      isLoading: state.isLoading,
                    ),
                    const SizedBox(height: 16),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.registerHasAccount,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => context.pop(),
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
