import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/routing/app_route_paths.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/app/widgets/app_button.dart';
import 'package:global_airsoft_app/src/app/widgets/app_form_padding.dart';
import 'package:global_airsoft_app/src/app/widgets/app_gradient_background.dart';
import 'package:global_airsoft_app/src/app/widgets/app_login_field.dart';
import 'package:global_airsoft_app/src/app/widgets/app_password_field.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/validation/backend_validation_error_mapper.dart';
import 'package:global_airsoft_app/src/core/validation/validation.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/user_login_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const BackendValidationErrorMapper _validationErrorMapper =
      BackendValidationErrorMapper();
  static final ValidationRuleSet _loginValidationRules = ValidationRuleSet(
    <ValidationRule>[RequiredValidationRule()],
  );
  static const ValidationRuleSet _passwordValidationRules = ValidationRuleSet(
    <ValidationRule>[RequiredValidationRule()],
  );

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _loginError;
  String? _passwordError;
  bool _isLoading = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLoginChanged(String _) {
    if (_loginError == null) {
      return;
    }

    setState(() {
      _loginError = null;
    });
  }

  void _handlePasswordChanged(String _) {
    if (_passwordError == null) {
      return;
    }

    setState(() {
      _passwordError = null;
    });
  }

  String _resolveValidationMessage(ValidationFailure failure) {
    final String selectedKey = switch (failure.messageKey) {
      AppLocaleKeys.validationMinLength => _pluralizedValidationKey(
        baseKey: AppLocaleKeys.validationMinLength,
        value: failure.arguments['min'],
      ),
      AppLocaleKeys.validationMaxLength => _pluralizedValidationKey(
        baseKey: AppLocaleKeys.validationMaxLength,
        value: failure.arguments['max'],
      ),
      AppLocaleKeys.validationPasswordMinimumLength => _pluralizedValidationKey(
        baseKey: AppLocaleKeys.validationPasswordMinimumLength,
        value: failure.arguments['min'],
      ),
      _ => failure.messageKey,
    };

    return context.l10n.trArgs(selectedKey, args: failure.arguments);
  }

  String _pluralizedValidationKey({
    required String baseKey,
    required Object? value,
  }) {
    final int? numericValue;
    if (value is int) {
      numericValue = value;
    } else if (value is num) {
      numericValue = value.toInt();
    } else if (value is String) {
      numericValue = int.tryParse(value);
    } else {
      numericValue = null;
    }

    return AppLocaleKeys.withPluralSuffix(
      baseKey: baseKey,
      isSingular: numericValue == 1,
    );
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loginError = null;
      _passwordError = null;
    });

    final FormState? formState = _formKey.currentState;
    if (!(formState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthService authService = ref.read(authServiceProvider);
      await authService.login(
        _loginController.text.trim(),
        _passwordController.text,
      );
      await ref
          .read(appLocaleControllerProvider.notifier)
          .forceApplyServerLocaleIfPending();

      if (mounted) {
        ref.read(isAuthenticatedProvider.notifier).setAuthenticated();
      }
    } on AuthenticationException catch (error) {
      if (mounted) {
        final ValidationMappingResult mappedErrors = _validationErrorMapper.map(
          exception: error.failure,
          targetFields: const <String>{
            UserLoginInputDto.loginField,
            UserLoginInputDto.passwordField,
          },
          memberAliases: const <String, String>{
            UserLoginInputDto.loginField: UserLoginInputDto.loginField,
            UserLoginInputDto.passwordField: UserLoginInputDto.passwordField,
          },
        );

        final String? mappedLoginError =
            mappedErrors.fieldErrors[UserLoginInputDto.loginField];
        final String? mappedPasswordError =
            mappedErrors.fieldErrors[UserLoginInputDto.passwordField];
        setState(() {
          _loginError = mappedLoginError;
          _passwordError = mappedPasswordError;
        });

        final String fallbackMessage = context.l10n.tr(
          AppLocaleKeys.authLoginFailed,
        );
        final String message = error.message ?? fallbackMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Unexpected login failure.',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.tr(AppLocaleKeys.authLoginFailed)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: AppFormPadding(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          const SizedBox(height: 40),
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusLg,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.track_changes_rounded,
                                  color: colorScheme.primary,
                                  size: 30,
                                ),
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'GA',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: colorScheme.onPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.l10n.tr(AppLocaleKeys.appTitle),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Text(
                              context.l10n.tr(AppLocaleKeys.authLoginSubtitle),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      AppLoginField(
                        controller: _loginController,
                        errorText: _loginError,
                        onChanged: _handleLoginChanged,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).nextFocus();
                        },
                        isRequired: _loginValidationRules.hasRequiredRule,
                        validator: _loginValidationRules.asValidator(
                          _resolveValidationMessage,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppPasswordField(
                        labelText: context.l10n.tr(
                          AppLocaleKeys.authPasswordLabel,
                        ),
                        controller: _passwordController,
                        errorText: _passwordError,
                        onChanged: _handlePasswordChanged,
                        onFieldSubmitted: (_) {
                          if (_isLoading) {
                            return;
                          }

                          unawaited(_handleLogin());
                        },
                        isRequired: _passwordValidationRules.hasRequiredRule,
                        validator: _passwordValidationRules.asValidator(
                          _resolveValidationMessage,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutePaths.passwordRecovery);
                                },
                          child: Text(
                            context.l10n.tr(
                              AppLocaleKeys.authForgotPasswordAction,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: context.l10n.tr(AppLocaleKeys.authSignInAction),
                        onPressed: _isLoading ? null : _handleLogin,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            context.l10n.tr(AppLocaleKeys.authLoginNoAccount),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.of(
                                      context,
                                    ).pushNamed(AppRoutePaths.signUp);
                                  },
                            child: Text(
                              context.l10n.tr(
                                AppLocaleKeys.authLoginSignUpAction,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
