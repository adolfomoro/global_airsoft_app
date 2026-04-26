import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/widgets/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/app/widgets/app_button.dart';
import 'package:global_airsoft_app/src/app/widgets/app_form_with_bottom_actions.dart';
import 'package:global_airsoft_app/src/app/widgets/app_password_field.dart';
import 'package:global_airsoft_app/src/app/widgets/app_text_field.dart';
import 'package:global_airsoft_app/src/app/widgets/focus_aware_scroll_coordinator.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/validation/backend_validation_error_mapper.dart';
import 'package:global_airsoft_app/src/core/validation/validation.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/create_user_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/email_validation.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/full_name_validation.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/password_validation_policy.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/user_name_validation.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/password_requirements_hint.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage>
    with WidgetsBindingObserver {
  static const BackendValidationErrorMapper _validationErrorMapper =
      BackendValidationErrorMapper();
  static final ValidationRuleSet _fullNameValidationRules =
      FullNameValidation.rules;
  static final ValidationRuleSet _usernameValidationRules =
      UsernameValidation.rules;
  static final ValidationRuleSet _emailValidationRules = EmailValidation.rules;
  static final ValidationRuleSet _passwordValidationRules =
      PasswordValidationPolicy.rules;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _passwordFocusNode = FocusNode();
  final GlobalKey _passwordFieldKey = GlobalKey();
  final GlobalKey _passwordHintKey = GlobalKey();
  String? _fullNameError;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;
  bool _isPasswordFocused = false;
  bool _hasRevealedPasswordHint = false;
  late final FocusAwareScrollCoordinator _passwordHintScrollCoordinator =
      FocusAwareScrollCoordinator(
        focusNode: _passwordFocusNode,
        scrollController: _scrollController,
        focusedFieldKey: _passwordFieldKey,
        revealTargetKey: _passwordHintKey,
        desiredRevealRatio: 1.0,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _passwordFocusNode.addListener(_handlePasswordFocusChanged);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (_hasRevealedPasswordHint && _shouldShowPasswordHint()) {
      _passwordHintScrollCoordinator.onMetricsChanged(context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _passwordFocusNode.removeListener(_handlePasswordFocusChanged);
    _passwordFocusNode.dispose();
    _scrollController.dispose();
    _passwordHintScrollCoordinator.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleFullNameChanged(String _) {
    if (_fullNameError == null) {
      return;
    }

    setState(() {
      _fullNameError = null;
    });
  }

  void _handleUsernameChanged(String _) {
    if (_usernameError == null) {
      return;
    }

    setState(() {
      _usernameError = null;
    });
  }

  void _handleEmailChanged(String _) {
    if (_emailError == null) {
      return;
    }

    setState(() {
      _emailError = null;
    });
  }

  void _handlePasswordChanged(String _) {
    setState(() {
      _passwordError = null;
    });

    _requestPasswordHintRevealIfNeeded();
  }

  void _handlePasswordFocusChanged() {
    if (_isPasswordFocused == _passwordFocusNode.hasFocus) {
      return;
    }

    setState(() {
      _isPasswordFocused = _passwordFocusNode.hasFocus;
      if (!_isPasswordFocused) {
        _hasRevealedPasswordHint = false;
      }
    });

    _requestPasswordHintRevealIfNeeded();
  }

  bool _shouldShowPasswordHint() {
    return _passwordValidationRules.validate(_passwordController.text) !=
            null &&
        (_isPasswordFocused || _passwordController.text.isNotEmpty);
  }

  bool _shouldRevealPasswordHintNow() {
    return _isPasswordFocused &&
        _shouldShowPasswordHint() &&
        !_hasRevealedPasswordHint;
  }

  void _requestPasswordHintRevealIfNeeded() {
    if (!_shouldRevealPasswordHintNow()) {
      return;
    }

    _hasRevealedPasswordHint = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_shouldShowPasswordHint()) {
        return;
      }

      _passwordHintScrollCoordinator.onFocusChanged(context);
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

  String? _validateConfirmPassword(String? value) {
    final String normalizedValue = value?.trim() ?? '';
    if (normalizedValue.isEmpty) {
      return context.l10n.tr(AppLocaleKeys.authConfirmPasswordRequired);
    }

    if (normalizedValue != _passwordController.text) {
      return context.l10n.tr(AppLocaleKeys.authConfirmPasswordMismatch);
    }

    return null;
  }

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _fullNameError = null;
      _usernameError = null;
      _emailError = null;
      _passwordError = null;
    });

    final FormState? formState = _formKey.currentState;
    if (!(formState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final AuthService authService = ref.read(authServiceProvider);
      await authService.signUp(
        username: _usernameController.text.trim().toLowerCase(),
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await ref
          .read(appLocaleControllerProvider.notifier)
          .forceApplyServerLocaleIfPending();

      if (!mounted) {
        return;
      }

      ref.read(isAuthenticatedProvider.notifier).setAuthenticated();
    } on AuthenticationException catch (error) {
      if (!mounted) {
        return;
      }

      final ValidationMappingResult mappedErrors = _validationErrorMapper.map(
        exception: error.failure,
        targetFields: const <String>{
          CreateUserInputDto.fullNameField,
          CreateUserInputDto.usernameField,
          CreateUserInputDto.emailField,
          CreateUserInputDto.passwordField,
        },
      );

      setState(() {
        _fullNameError =
            mappedErrors.fieldErrors[CreateUserInputDto.fullNameField];
        _usernameError =
            mappedErrors.fieldErrors[CreateUserInputDto.usernameField];
        _emailError = mappedErrors.fieldErrors[CreateUserInputDto.emailField];
        _passwordError =
            mappedErrors.fieldErrors[CreateUserInputDto.passwordField]
                    ?.trim()
                    .isNotEmpty ==
                true
            ? mappedErrors.fieldErrors[CreateUserInputDto.passwordField]
            : null;
      });

      final String? globalError = mappedErrors.globalErrors
          .where((String e) => e.trim().isNotEmpty)
          .cast<String?>()
          .firstWhere((String? e) => e != null, orElse: () => null);

      final String? message = error.message ?? globalError;
      if (message != null && message.trim().isNotEmpty) {
        context.showErrorSnackBar(message, source: error.failure);
      }
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Unexpected sign-up failure.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }

      context.showErrorSnackBar(
        context.l10n.tr(AppLocaleKeys.authSignUpFailed),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ValidationRuleSet passwordValidationRules = _passwordValidationRules;
    final bool canSubmit = !_isLoading;

    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(context.l10n.tr(AppLocaleKeys.authSignUpAction)),
      ),
      body: Form(
        key: _formKey,
        child: AppFormWithBottomActions(
          scrollController: _scrollController,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 20),
              Text(
                context.l10n.tr(AppLocaleKeys.authSignUpHeading),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.tr(AppLocaleKeys.authSignUpSubtitle),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              AppTextField(
                labelText: context.l10n.tr(AppLocaleKeys.authUsernameLabel),
                controller: _usernameController,
                onChanged: _handleUsernameChanged,
                errorText: _usernameError,
                isRequired: _usernameValidationRules.hasRequiredRule,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                validator: _usernameValidationRules.asValidator(
                  _resolveValidationMessage,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                labelText: context.l10n.tr(AppLocaleKeys.authFullNameLabel),
                controller: _fullNameController,
                onChanged: _handleFullNameChanged,
                errorText: _fullNameError,
                isRequired: _fullNameValidationRules.hasRequiredRule,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                validator: _fullNameValidationRules.asValidator(
                  _resolveValidationMessage,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                labelText: context.l10n.tr(AppLocaleKeys.authEmailLabel),
                controller: _emailController,
                onChanged: _handleEmailChanged,
                errorText: _emailError,
                isRequired: _emailValidationRules.hasRequiredRule,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: _emailValidationRules.asValidator(
                  _resolveValidationMessage,
                ),
              ),
              const SizedBox(height: 16),
              AppPasswordField(
                key: _passwordFieldKey,
                labelText: context.l10n.tr(AppLocaleKeys.authPasswordLabel),
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                onChanged: _handlePasswordChanged,
                errorText: _passwordError,
                isRequired: passwordValidationRules.hasRequiredRule,
                textInputAction: TextInputAction.done,
                validator: passwordValidationRules.asValidator(
                  _resolveValidationMessage,
                ),
              ),
              SizedBox(
                key: _passwordHintKey,
                child: PasswordRequirementsHint(
                  currentPassword: _passwordController.text,
                  isFocused: _isPasswordFocused,
                ),
              ),
              const SizedBox(height: 16),
              AppPasswordField(
                controller: _confirmPasswordController,
                labelText: context.l10n.tr(
                  AppLocaleKeys.authConfirmPasswordLabel,
                ),
                isRequired: true,
                textInputAction: TextInputAction.done,
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 24),
            ],
          ),
          bottomActions: <AppFormBottomAction>[
            AppFormBottomAction(
              showWhenKeyboardOpen: true,
              child: AppButton(
                label: context.l10n.tr(AppLocaleKeys.authSignUpAction),
                isLoading: _isLoading,
                onPressed: canSubmit ? _handleSignUp : null,
              ),
            ),
            AppFormBottomAction(child: const SizedBox(height: 8)),
            AppFormBottomAction(
              showWhenKeyboardOpen: false,
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                child: Text(
                  context.l10n.tr(AppLocaleKeys.authBackToLoginAction),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
