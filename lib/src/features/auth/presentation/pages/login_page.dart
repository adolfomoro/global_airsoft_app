import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:global_airsoft_app/src/app/routing/app_route_paths.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/localization/app_validation_localizations.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/validation/backend_validation_error_mapper.dart';
import 'package:global_airsoft_app/src/core/validation/validation.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_page_header.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_button.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_form_padding.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_service.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/google_sign_in_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/google_sign_in_exception.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/user_login_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/support/auth_form_submission_mixin.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/support/auth_presentation_extensions.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/app_gradient_background.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/app_login_field.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/app_password_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with AuthFormSubmissionMixin<LoginPage> {
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
  bool _isLoginLoading = false;
  bool _isGoogleLoading = false;

  bool get _isAnyAuthLoading => _isLoginLoading || _isGoogleLoading;

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

  Future<void> _submitLogin() async {
    if (_isAnyAuthLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loginError = null;
      _passwordError = null;
    });

    if (!validateSubmittedForm(_formKey)) {
      return;
    }

    setState(() {
      _isLoginLoading = true;
    });

    try {
      final AuthService authService = ref.read(authServiceProvider);
      await authService.login(
        _loginController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) {
        return;
      }

      await ref.completeAuthenticatedSession();
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
        context.showErrorSnackBar(message, source: error.failure);
      }
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Unexpected login failure.',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        context.showLocalizedErrorSnackBar(AppLocaleKeys.authLoginFailed);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoginLoading = false;
        });
      }
    }
  }

  Future<void> _submitGoogleSignIn() async {
    if (_isAnyAuthLoading) {
      return;
    }

    setState(() {
      _loginError = null;
      _passwordError = null;
      _isGoogleLoading = true;
    });

    try {
      final GoogleSignInService googleSignInService = ref.read(
        googleSignInServiceProvider,
      );
      final String? idToken = await googleSignInService.requestIdToken();
      if (idToken == null) {
        return;
      }

      final AuthService authService = ref.read(authServiceProvider);
      final response = await authService.signInWithGoogle(idToken);

      if (!mounted) {
        return;
      }

      if (response.userExists) {
        await ref.completeAuthenticatedSession();
        return;
      }

      final suggestion = response.suggestion;
      if (suggestion == null) {
        throw const GoogleSignInException(
          'Google sign-in returned no profile suggestion.',
        );
      }

      await Navigator.of(context).pushNamed(
        AppRoutePaths.googleAccountSetup,
        arguments: (
          challengeToken: response.challengeToken ?? '',
          profilePictureUrl: suggestion.profilePictureUrl,
          profileName: suggestion.username,
        ),
      );
    } on AuthenticationException catch (error) {
      if (mounted) {
        final mappedErrors = _validationErrorMapper.map(
          exception: error.failure,
          targetFields: const <String>{},
        );

        final String? globalError = mappedErrors.firstMeaningfulGlobalError;

        final String fallbackMessage = context.l10n.tr(
          AppLocaleKeys.authGoogleSignInFailed,
        );
        final String message = error.message ?? globalError ?? fallbackMessage;
        context.showErrorSnackBar(message, source: error.failure);
      }
    } on GoogleSignInException catch (_) {
      if (mounted) {
        context.showLocalizedErrorSnackBar(
          AppLocaleKeys.authGoogleSignInFailed,
        );
      }
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Unexpected Google sign-in failure.',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        context.showLocalizedErrorSnackBar(
          AppLocaleKeys.authGoogleSignInFailed,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AppGradientBackground(
        animateOnFirstBuild: true,
        animationId: 'login-page-initial-background-fade',
        child: SafeArea(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              autovalidateMode: formAutovalidateMode,
              child: AutofillGroup(
                child: AppFormPadding(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(height: AppDimensions.spacingXl),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          const SizedBox(height: 40),
                          AppPageHeader(
                            title: context.l10n.tr(AppLocaleKeys.appTitle),
                            subtitle: context.l10n.tr(
                              AppLocaleKeys.authLoginSubtitle,
                            ),
                            titleStyle: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                            leading: Container(
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
                          context.resolveValidationMessage,
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
                          if (_isAnyAuthLoading) {
                            return;
                          }

                          unawaited(_submitLogin());
                        },
                        isRequired: _passwordValidationRules.hasRequiredRule,
                        validator: _passwordValidationRules.asValidator(
                          context.resolveValidationMessage,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isAnyAuthLoading
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
                      const SizedBox(height: AppDimensions.spacingXl),
                      AppButton(
                        label: context.l10n.tr(AppLocaleKeys.authSignInAction),
                        onPressed: _isAnyAuthLoading ? null : _submitLogin,
                        isLoading: _isLoginLoading,
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: context.l10n.tr(
                          AppLocaleKeys.authGoogleContinueAction,
                        ),
                        onPressed: _isAnyAuthLoading
                            ? null
                            : _submitGoogleSignIn,
                        variant: AppButtonVariant.secondary,
                        icon: FontAwesomeIcons.google,
                        isLoading: _isGoogleLoading,
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
                            onPressed: _isAnyAuthLoading
                                ? null
                                : () {
                                    Navigator.of(
                                      context,
                                    ).pushNamed(AppRoutePaths.signUp);
                                  },
                            child: Text(
                              context.l10n.tr(AppLocaleKeys.authSignUpAction),
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
