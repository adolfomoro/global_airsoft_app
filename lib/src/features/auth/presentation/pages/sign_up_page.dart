import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/routing/app_route_paths.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/localization/app_validation_localizations.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/validation/backend_validation_error_mapper.dart';
import 'package:global_airsoft_app/src/core/validation/full_name_validation.dart';
import 'package:global_airsoft_app/src/core/validation/validation.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_page_header.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_button.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_form_padding.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_text_field.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/create_user_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/email_validation.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/password_validation_policy.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/username_validation.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/sign_up_form_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/support/auth_presentation_extensions.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/app_password_field.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/password_requirements_hint.dart';

class SignUpPage extends ConsumerWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(context.l10n.tr(AppLocaleKeys.authSignUpAction)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: AutofillGroup(
            child: AppFormPadding(
              padding: AppFormPadding.standardScrollablePagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: AppDimensions.spacingXl),
                  const _SignUpHeaderSection(),
                  const SizedBox(height: AppDimensions.spacingXl),
                  _FullNameFieldConsumer(),
                  const SizedBox(height: AppDimensions.spacingLg),
                  _UsernameFieldConsumer(),
                  const SizedBox(height: AppDimensions.spacingLg),
                  _EmailFieldConsumer(),
                  const SizedBox(height: AppDimensions.spacingLg),
                  _PasswordFieldConsumer(),
                  const SizedBox(height: AppDimensions.spacingLg),
                  _ConfirmPasswordFieldConsumer(),
                  const SizedBox(height: AppDimensions.spacingXl),
                  _SubmitButtonConsumer(),
                  const SizedBox(height: AppDimensions.spacingMd),
                  _SignInLinkSection(),
                  const SizedBox(height: AppDimensions.spacingXl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignUpHeaderSection extends StatelessWidget {
  const _SignUpHeaderSection();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return AppPageHeader(
      title: context.l10n.tr(AppLocaleKeys.authSignUpHeading),
      subtitle: context.l10n.tr(AppLocaleKeys.authSignUpSubtitle),
      titleStyle: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
              Icons.person_add_alt_1_rounded,
              color: colorScheme.primary,
              size: 28,
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
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// FULL NAME FIELD CONSUMER
// ============================================================================

class _FullNameFieldConsumer extends ConsumerStatefulWidget {
  const _FullNameFieldConsumer();

  @override
  ConsumerState<_FullNameFieldConsumer> createState() => _FullNameFieldConsumerState();
}

class _FullNameFieldConsumerState extends ConsumerState<_FullNameFieldConsumer> {
  late final TextEditingController _controller;
  static final ValidationRuleSet _fullNameValidationRules = FullNameValidation.rules;

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
    final value = ref.watch(signUpFullNameValueProvider);
    final error = ref.watch(signUpFullNameErrorProvider);

    if (_controller.text != value) {
      _controller.text = value;
    }

    return AppTextField(
      labelText: context.l10n.tr(AppLocaleKeys.authFullNameLabel),
      controller: _controller,
      errorText: error,
      onChanged: (v) {
        ref.read(signUpFullNameFieldProvider.notifier).setValue(v);
      },
      onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
      isRequired: _fullNameValidationRules.hasRequiredRule,
      validator: _fullNameValidationRules.asValidator(
        context.resolveValidationMessage,
      ),
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.name],
      textCapitalization: TextCapitalization.words,
    );
  }
}

// ============================================================================
// USERNAME FIELD CONSUMER
// ============================================================================

class _UsernameFieldConsumer extends ConsumerStatefulWidget {
  const _UsernameFieldConsumer();

  @override
  ConsumerState<_UsernameFieldConsumer> createState() => _UsernameFieldConsumerState();
}

class _UsernameFieldConsumerState extends ConsumerState<_UsernameFieldConsumer> {
  late final TextEditingController _controller;
  static final ValidationRuleSet _usernameValidationRules = UsernameValidation.rules;

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
    final value = ref.watch(signUpUsernameValueProvider);
    final error = ref.watch(signUpUsernameErrorProvider);

    if (_controller.text != value) {
      _controller.text = value;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppTextField(
          labelText: context.l10n.tr(AppLocaleKeys.authUsernameLabel),
          hintText: context.l10n.tr(AppLocaleKeys.authUsernameExampleHint),
          controller: _controller,
          errorText: error,
          onChanged: (v) {
            ref.read(signUpUsernameFieldProvider.notifier).setValue(v);
          },
          onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
          isRequired: _usernameValidationRules.hasRequiredRule,
          validator: _usernameValidationRules.asValidator(
            context.resolveValidationMessage,
          ),
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          enableIMEPersonalizedLearning: false,
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            context.l10n.tr(AppLocaleKeys.authUsernameRestrictionHint),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// EMAIL FIELD CONSUMER
// ============================================================================

class _EmailFieldConsumer extends ConsumerStatefulWidget {
  const _EmailFieldConsumer();

  @override
  ConsumerState<_EmailFieldConsumer> createState() => _EmailFieldConsumerState();
}

class _EmailFieldConsumerState extends ConsumerState<_EmailFieldConsumer> {
  late final TextEditingController _controller;
  static final ValidationRuleSet _emailValidationRules = EmailValidation.rules;

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
    final value = ref.watch(signUpEmailValueProvider);
    final error = ref.watch(signUpEmailErrorProvider);

    if (_controller.text != value) {
      _controller.text = value;
    }

    return AppTextField(
      labelText: context.l10n.tr(AppLocaleKeys.authEmailLabel),
      controller: _controller,
      errorText: error,
      onChanged: (v) {
        ref.read(signUpEmailFieldProvider.notifier).setValue(v);
      },
      onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
      isRequired: _emailValidationRules.hasRequiredRule,
      validator: _emailValidationRules.asValidator(
        context.resolveValidationMessage,
      ),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.email],
    );
  }
}

// ============================================================================
// PASSWORD FIELD CONSUMER
// ============================================================================

class _PasswordFieldConsumer extends ConsumerStatefulWidget {
  const _PasswordFieldConsumer();

  @override
  ConsumerState<_PasswordFieldConsumer> createState() => _PasswordFieldConsumerState();
}

class _PasswordFieldConsumerState extends ConsumerState<_PasswordFieldConsumer> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  static final ValidationRuleSet _passwordValidationRules =
      PasswordValidationPolicy.rules;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(signUpPasswordValueProvider);
    final error = ref.watch(signUpPasswordErrorProvider);

    if (_controller.text != value) {
      _controller.text = value;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppPasswordField(
          labelText: context.l10n.tr(AppLocaleKeys.authPasswordLabel),
          controller: _controller,
          focusNode: _focusNode,
          errorText: error,
          onChanged: (v) {
            ref.read(signUpPasswordFieldProvider.notifier).setValue(v);
          },
          onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
          isRequired: _passwordValidationRules.hasRequiredRule,
          validator: _passwordValidationRules.asValidator(
            context.resolveValidationMessage,
          ),
          textInputAction: TextInputAction.next,
        ),
        PasswordRequirementsHint(
          currentPassword: value,
          isFocused: _focusNode.hasFocus,
        ),
      ],
    );
  }
}

// ============================================================================
// CONFIRM PASSWORD FIELD CONSUMER
// ============================================================================

class _ConfirmPasswordFieldConsumer extends ConsumerStatefulWidget {
  const _ConfirmPasswordFieldConsumer();

  @override
  ConsumerState<_ConfirmPasswordFieldConsumer> createState() =>
      _ConfirmPasswordFieldConsumerState();
}

class _ConfirmPasswordFieldConsumerState extends ConsumerState<_ConfirmPasswordFieldConsumer> {
  late final TextEditingController _controller;

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
    final value = ref.watch(signUpConfirmPasswordValueProvider);
    final error = ref.watch(signUpConfirmPasswordErrorProvider);
    final passwordsMatch = ref.watch(signUpPasswordsMatchProvider);

    if (_controller.text != value) {
      _controller.text = value;
    }

    return AppPasswordField(
      labelText: context.l10n.tr(AppLocaleKeys.authConfirmPasswordLabel),
      controller: _controller,
      errorText: error ??
          (!passwordsMatch && value.isNotEmpty
              ? context.l10n.tr(AppLocaleKeys.authConfirmPasswordMismatch)
              : null),
      onChanged: (v) {
        ref.read(signUpConfirmPasswordFieldProvider.notifier).setValue(v);
      },
      onFieldSubmitted: (_) {
        final isSubmitting = ref.read(signUpIsSubmittingProvider);
        if (!isSubmitting) {
          _SignUpSubmissionLogic.submit(context, ref);
        }
      },
      textInputAction: TextInputAction.send,
    );
  }
}

// ============================================================================
// SUBMIT BUTTON CONSUMER
// ============================================================================

class _SubmitButtonConsumer extends ConsumerWidget {
  const _SubmitButtonConsumer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(signUpIsSubmittingProvider);
    final isEnabled = ref.watch(signUpSubmitEnabledProvider);

    return AppButton(
      label: context.l10n.tr(AppLocaleKeys.authSignUpAction),
      onPressed: !isEnabled ? null : () => _SignUpSubmissionLogic.submit(context, ref),
      isLoading: isSubmitting,
    );
  }
}

// ============================================================================
// SIGN IN LINK SECTION
// ============================================================================

class _SignInLinkSection extends ConsumerWidget {
  const _SignInLinkSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(signUpIsSubmittingProvider);

    return Center(
      child: TextButton(
        onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
        child: Text(context.l10n.tr(AppLocaleKeys.authBackToLoginAction)),
      ),
    );
  }
}

// ============================================================================
// SUBMISSION LOGIC
// ============================================================================

abstract final class _SignUpSubmissionLogic {
  static const BackendValidationErrorMapper _validationErrorMapper =
      BackendValidationErrorMapper();
  static final ValidationRuleSet _fullNameValidationRules = FullNameValidation.rules;
  static final ValidationRuleSet _usernameValidationRules = UsernameValidation.rules;
  static final ValidationRuleSet _emailValidationRules = EmailValidation.rules;
  static final ValidationRuleSet _passwordValidationRules = PasswordValidationPolicy.rules;

  static String? _resolveValidationError(
    BuildContext context,
    ValidationRuleSet rules,
    String value,
  ) {
    final failure = rules.validate(value);
    if (failure == null) {
      return null;
    }

    return context.resolveValidationMessage(failure);
  }

  static Future<void> submit(BuildContext context, WidgetRef ref) async {
    FocusScope.of(context).unfocus();

    // Clear previous errors
    ref.read(signUpFullNameFieldProvider.notifier).clearError();
    ref.read(signUpUsernameFieldProvider.notifier).clearError();
    ref.read(signUpEmailFieldProvider.notifier).clearError();
    ref.read(signUpPasswordFieldProvider.notifier).clearError();
    ref.read(signUpConfirmPasswordFieldProvider.notifier).clearError();
    ref.read(signUpFormStateProvider.notifier).setError(null);

    final fullName = ref.read(signUpFullNameValueProvider).trim();
    final username = ref.read(signUpUsernameValueProvider).trim();
    final email = ref.read(signUpEmailValueProvider).trim();
    final password = ref.read(signUpPasswordValueProvider);
    final confirmPassword = ref.read(signUpConfirmPasswordValueProvider);

    final fullNameError = _resolveValidationError(
      context,
      _fullNameValidationRules,
      fullName,
    );
    final usernameError = _resolveValidationError(
      context,
      _usernameValidationRules,
      username,
    );
    final emailError = _resolveValidationError(
      context,
      _emailValidationRules,
      email,
    );
    final passwordError = _resolveValidationError(
      context,
      _passwordValidationRules,
      password,
    );
    final confirmPasswordError = confirmPassword.trim().isEmpty
        ? context.l10n.tr(AppLocaleKeys.authConfirmPasswordRequired)
        : null;

    if (fullNameError != null) {
      ref.read(signUpFullNameFieldProvider.notifier).setError(fullNameError);
    }
    if (usernameError != null) {
      ref.read(signUpUsernameFieldProvider.notifier).setError(usernameError);
    }
    if (emailError != null) {
      ref.read(signUpEmailFieldProvider.notifier).setError(emailError);
    }
    if (passwordError != null) {
      ref.read(signUpPasswordFieldProvider.notifier).setError(passwordError);
    }
    if (confirmPasswordError != null) {
      ref.read(signUpConfirmPasswordFieldProvider.notifier).setError(
        confirmPasswordError,
      );
    }

    final passwordsMatch = ref.read(signUpPasswordsMatchProvider);
    if (!passwordsMatch && confirmPassword.trim().isNotEmpty) {
      ref.read(signUpConfirmPasswordFieldProvider.notifier).setError(
        context.l10n.tr(AppLocaleKeys.authConfirmPasswordMismatch),
      );
    }

    if (fullNameError != null ||
        usernameError != null ||
        emailError != null ||
        passwordError != null ||
        confirmPasswordError != null ||
        !passwordsMatch) {
      return;
    }

    ref.read(signUpFormStateProvider.notifier).setSubmitting(true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUp(
        fullName: fullName,
        username: username.toLowerCase(),
        email: email,
        password: password,
      );

      if (!context.mounted) {
        return;
      }

      // Navigate to home on success
      await Navigator.of(context).pushReplacementNamed(AppRoutePaths.home);
    } on AuthenticationException catch (error) {
      if (context.mounted) {
        final mappedErrors = _validationErrorMapper.map(
          exception: error.failure,
          targetFields: const <String>{
            CreateUserInputDto.fullNameField,
            CreateUserInputDto.usernameField,
            CreateUserInputDto.emailField,
            CreateUserInputDto.passwordField,
          },
          memberAliases: const <String, String>{
            'fullName': CreateUserInputDto.fullNameField,
            'username': CreateUserInputDto.usernameField,
            'email': CreateUserInputDto.emailField,
            'password': CreateUserInputDto.passwordField,
          },
        );

        // Apply field-specific errors
        if (mappedErrors.fieldErrors[CreateUserInputDto.fullNameField] != null) {
          ref.read(signUpFullNameFieldProvider.notifier).setError(
                mappedErrors.fieldErrors[CreateUserInputDto.fullNameField],
              );
        }
        if (mappedErrors.fieldErrors[CreateUserInputDto.usernameField] != null) {
          ref.read(signUpUsernameFieldProvider.notifier).setError(
                mappedErrors.fieldErrors[CreateUserInputDto.usernameField],
              );
        }
        if (mappedErrors.fieldErrors[CreateUserInputDto.emailField] != null) {
          ref.read(signUpEmailFieldProvider.notifier).setError(
                mappedErrors.fieldErrors[CreateUserInputDto.emailField],
              );
        }
        if (mappedErrors.fieldErrors[CreateUserInputDto.passwordField] != null) {
          ref.read(signUpPasswordFieldProvider.notifier).setError(
                mappedErrors.fieldErrors[CreateUserInputDto.passwordField],
              );
        }

        final fallbackMessage = context.l10n.tr(AppLocaleKeys.authSignUpFailed);
        final message = error.message ?? fallbackMessage;
        context.showErrorSnackBar(message, source: error.failure);
      }
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Unexpected signup failure.',
        error: error,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        context.showLocalizedErrorSnackBar(AppLocaleKeys.authSignUpFailed);
      }
    } finally {
      if (context.mounted) {
        ref.read(signUpFormStateProvider.notifier).setSubmitting(false);
      }
    }
  }
}
