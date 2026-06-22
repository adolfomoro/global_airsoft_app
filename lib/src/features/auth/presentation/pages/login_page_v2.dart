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
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/google_sign_in_exception.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/user_login_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/login_form_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/support/auth_presentation_extensions.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/app_gradient_background.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/app_login_field.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/app_password_field.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AppGradientBackground(
        animateOnFirstBuild: true,
        animationId: 'login-page-initial-background-fade',
        child: SafeArea(
          child: SingleChildScrollView(
            child: Form(
              child: AutofillGroup(
                child: AppFormPadding(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(height: AppDimensions.spacingXl),
                      _LoginHeaderSection(),
                      const SizedBox(height: 40),
                      _LoginFieldConsumer(),
                      const SizedBox(height: 16),
                      _PasswordFieldConsumer(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _ForgotPasswordButtonConsumer(),
                      ),
                      const SizedBox(height: AppDimensions.spacingXl),
                      _SubmitButtonConsumer(),
                      const SizedBox(height: 12),
                      _GoogleSignInButtonConsumer(),
                      const SizedBox(height: 18),
                      _SignUpLinkSection(),
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

// ============================================================================
// STATIC HEADER SECTION
// ============================================================================

class _LoginHeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const SizedBox(height: 40),
        AppPageHeader(
          title: context.l10n.tr(AppLocaleKeys.appTitle),
          subtitle: context.l10n.tr(AppLocaleKeys.authLoginSubtitle),
          titleStyle:
              Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          leading: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
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
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'GA',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
    );
  }
}

// ============================================================================
// LOGIN FIELD CONSUMER
// Rebuilds ONLY when login value/error changes
// ============================================================================

class _LoginFieldConsumer extends ConsumerStatefulWidget {
  const _LoginFieldConsumer();

  @override
  ConsumerState<_LoginFieldConsumer> createState() => _LoginFieldConsumerState();
}

class _LoginFieldConsumerState extends ConsumerState<_LoginFieldConsumer> {
  late final TextEditingController _controller;

  static final ValidationRuleSet _loginValidationRules = ValidationRuleSet(
    <ValidationRule>[RequiredValidationRule()],
  );

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Granular selectors: only watch what's needed
    final loginValue = ref.watch(loginValueProvider);
    final loginError = ref.watch(loginErrorProvider);

    // Sync controller with provider state
    if (_controller.text != loginValue) {
      _controller.text = loginValue;
    }

    return AppLoginField(
      controller: _controller,
      errorText: loginError,
      onChanged: (value) {
        ref.read(loginFieldProvider.notifier).setValue(value);
      },
      onFieldSubmitted: (_) {
        FocusScope.of(context).nextFocus();
      },
      isRequired: _loginValidationRules.hasRequiredRule,
      validator: _loginValidationRules.asValidator(
        context.resolveValidationMessage,
      ),
    );
  }
}

// ============================================================================
// PASSWORD FIELD CONSUMER
// Rebuilds ONLY when password value/error changes
// ============================================================================

class _PasswordFieldConsumer extends ConsumerStatefulWidget {
  const _PasswordFieldConsumer();

  @override
  ConsumerState<_PasswordFieldConsumer> createState() => _PasswordFieldConsumerState();
}

class _PasswordFieldConsumerState extends ConsumerState<_PasswordFieldConsumer> {
  late final TextEditingController _controller;

  static final ValidationRuleSet _passwordValidationRules = ValidationRuleSet(
    <ValidationRule>[RequiredValidationRule()],
  );

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Granular selectors: only watch what's needed
    final passwordValue = ref.watch(passwordValueProvider);
    final passwordError = ref.watch(passwordErrorProvider);
    final isAnyLoading = ref.watch(loginIsSubmittingProvider);

    // Sync controller with provider state
    if (_controller.text != passwordValue) {
      _controller.text = passwordValue;
    }

    return AppPasswordField(
      labelText: context.l10n.tr(AppLocaleKeys.authPasswordLabel),
      controller: _controller,
      errorText: passwordError,
      onChanged: (value) {
        ref.read(passwordFieldProvider.notifier).setValue(value);
      },
      onFieldSubmitted: (_) {
        if (!isAnyLoading) {
          _LoginSubmissionLogic.submitLogin(context, ref);
        }
      },
      isRequired: _passwordValidationRules.hasRequiredRule,
      validator: _passwordValidationRules.asValidator(
        context.resolveValidationMessage,
      ),
    );
  }
}

// ============================================================================
// FORGOT PASSWORD BUTTON CONSUMER
// Rebuilds ONLY when loading state changes
// ============================================================================

class _ForgotPasswordButtonConsumer extends ConsumerWidget {
  const _ForgotPasswordButtonConsumer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnyLoading = ref.watch(loginIsSubmittingProvider);

    return TextButton(
      onPressed: isAnyLoading
          ? null
          : () {
              Navigator.of(context).pushNamed(AppRoutePaths.passwordRecovery);
            },
      child: Text(
        context.l10n.tr(AppLocaleKeys.authForgotPasswordAction),
      ),
    );
  }
}

// ============================================================================
// SUBMIT BUTTON CONSUMER
// Rebuilds ONLY when loading or validity changes
// ============================================================================

class _SubmitButtonConsumer extends ConsumerWidget {
  const _SubmitButtonConsumer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(loginIsSubmittingProvider);
    final isEnabled = ref.watch(loginSubmitEnabledProvider);

    return AppButton(
      label: context.l10n.tr(AppLocaleKeys.authSignInAction),
      onPressed: !isEnabled ? null : () => _LoginSubmissionLogic.submitLogin(context, ref),
      isLoading: isSubmitting,
    );
  }
}

// ============================================================================
// GOOGLE SIGN-IN BUTTON CONSUMER
// Rebuilds ONLY when google loading state changes
// ============================================================================

class _GoogleSignInButtonConsumer extends ConsumerWidget {
  const _GoogleSignInButtonConsumer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnyLoading = ref.watch(loginIsSubmittingProvider);

    return AppButton(
      label: context.l10n.tr(AppLocaleKeys.authGoogleContinueAction),
      onPressed: isAnyLoading ? null : () => _GoogleSubmissionLogic.submitGoogle(context, ref),
      variant: AppButtonVariant.secondary,
      iconWidget: const FaIcon(FontAwesomeIcons.google),
      isLoading: isAnyLoading && ref.watch(loginFormStateProvider).isSubmitting,
    );
  }
}

// ============================================================================
// STATIC SIGN-UP LINK SECTION
// ============================================================================

class _SignUpLinkSection extends ConsumerWidget {
  const _SignUpLinkSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnyLoading = ref.watch(loginIsSubmittingProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          context.l10n.tr(AppLocaleKeys.authLoginNoAccount),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: isAnyLoading
              ? null
              : () {
                  Navigator.of(context).pushNamed(AppRoutePaths.signUp);
                },
          child: Text(
            context.l10n.tr(AppLocaleKeys.authSignUpAction),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SUBMISSION LOGIC - Extracted to keep consumers clean
// ============================================================================

abstract final class _LoginSubmissionLogic {
  static const BackendValidationErrorMapper _validationErrorMapper =
      BackendValidationErrorMapper();

  static Future<void> submitLogin(BuildContext context, WidgetRef ref) async {
    FocusScope.of(context).unfocus();

    // Clear previous errors
    ref.read(loginFieldProvider.notifier).clearError();
    ref.read(passwordFieldProvider.notifier).clearError();
    ref.read(loginFormStateProvider.notifier).setError(null);

    // Validate all fields
    final loginValid = ref.read(loginFieldProvider.notifier).validate();
    final passwordValid = ref.read(passwordFieldProvider.notifier).validate();

    if (!loginValid || !passwordValid) {
      return;
    }

    // Get current values
    final loginValue = ref.read(loginValueProvider);
    final passwordValue = ref.read(passwordValueProvider);

    // Mark as submitting
    ref.read(loginFormStateProvider.notifier).setSubmitting(true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.login(loginValue.trim(), passwordValue);

      if (!context.mounted) {
        return;
      }

      await ref.completeAuthenticatedSession();
    } on AuthenticationException catch (error) {
      if (context.mounted) {
        final mappedErrors = _validationErrorMapper.map(
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

        final mappedLoginError =
            mappedErrors.fieldErrors[UserLoginInputDto.loginField];
        final mappedPasswordError =
            mappedErrors.fieldErrors[UserLoginInputDto.passwordField];

        // Update field-specific errors
        if (mappedLoginError != null) {
          ref.read(loginFieldProvider.notifier).setError(mappedLoginError);
        }
        if (mappedPasswordError != null) {
          ref.read(passwordFieldProvider.notifier).setError(mappedPasswordError);
        }

        final fallbackMessage = context.l10n.tr(AppLocaleKeys.authLoginFailed);
        final message = error.message ?? fallbackMessage;
        context.showErrorSnackBar(message, source: error.failure);
      }
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Unexpected login failure.',
        error: error,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        context.showLocalizedErrorSnackBar(AppLocaleKeys.authLoginFailed);
      }
    } finally {
      if (context.mounted) {
        ref.read(loginFormStateProvider.notifier).setSubmitting(false);
      }
    }
  }
}

abstract final class _GoogleSubmissionLogic {
  static const BackendValidationErrorMapper _validationErrorMapper =
      BackendValidationErrorMapper();

  static Future<void> submitGoogle(BuildContext context, WidgetRef ref) async {
    // Clear previous errors
    ref.read(loginFormStateProvider.notifier).setError(null);

    ref.read(loginFormStateProvider.notifier).setSubmitting(true);

    try {
      final googleSignInService = ref.read(googleSignInServiceProvider);
      final idToken = await googleSignInService.requestIdToken();

      if (idToken == null) {
        ref.read(loginFormStateProvider.notifier).setSubmitting(false);
        return;
      }

      final authService = ref.read(authServiceProvider);
      final response = await authService.signInWithGoogle(idToken);

      if (!context.mounted) {
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
      if (context.mounted) {
        final mappedErrors = _validationErrorMapper.map(
          exception: error.failure,
          targetFields: const <String>{},
        );

        final globalError = mappedErrors.firstMeaningfulGlobalError;
        final fallbackMessage = context.l10n.tr(AppLocaleKeys.authGoogleSignInFailed);
        final message = error.message ?? globalError ?? fallbackMessage;
        context.showErrorSnackBar(message, source: error.failure);
      }
    } on GoogleSignInException catch (_) {
      if (context.mounted) {
        context.showLocalizedErrorSnackBar(AppLocaleKeys.authGoogleSignInFailed);
      }
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Unexpected Google sign-in failure.',
        error: error,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        context.showLocalizedErrorSnackBar(AppLocaleKeys.authGoogleSignInFailed);
      }
    } finally {
      if (context.mounted) {
        ref.read(loginFormStateProvider.notifier).setSubmitting(false);
      }
    }
  }
}
