import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/widgets/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/app/widgets/app_button.dart';
import 'package:global_airsoft_app/src/app/widgets/app_password_field.dart';
import 'package:global_airsoft_app/src/app/widgets/app_text_field.dart';
import 'package:global_airsoft_app/src/app/widgets/focus_aware_scroll_coordinator.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/validation/backend_validation_error_mapper.dart';
import 'package:global_airsoft_app/src/core/validation/validation.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/create_user_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/password_validation_rules_output_dto.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/auth_validation_patterns.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/password_validation_rules_card.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage>
    with WidgetsBindingObserver {
  static const int _minUserNameLength = 3;
  static const int _maxUserNameLength = 32;
  static final RegExp _userNamePattern = RegExp(r'^[a-z]+$');

  static const BackendValidationErrorMapper _validationErrorMapper =
      BackendValidationErrorMapper();
  static final ValidationRuleSet _userNameValidationRules =
      ValidationRuleSet(<ValidationRule>[
        const RequiredValidationRule(),
        const MinLengthValidationRule(_minUserNameLength),
        const MaxLengthValidationRule(_maxUserNameLength),
        PatternValidationRule(
          _userNamePattern,
          messageKey: AppLocaleKeys.validationUserNameLowercaseOnly,
          allowEmpty: false,
          trimValue: true,
        ),
      ]);
  static final ValidationRuleSet _emailValidationRules =
      ValidationRuleSet(<ValidationRule>[
        const RequiredValidationRule(),
        const MaxLengthValidationRule(256),
        PatternValidationRule(
          AuthValidationPatterns.emailPattern,
          allowEmpty: false,
          trimValue: true,
        ),
      ]);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _passwordFieldKey = GlobalKey();
  final GlobalKey _passwordRulesCardKey = GlobalKey();
  late TextEditingController _userNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  final FocusNode _passwordFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late FocusAwareScrollCoordinator _passwordFocusScrollCoordinator;
  String? _userNameError;
  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _passwordFocusScrollCoordinator = FocusAwareScrollCoordinator(
      focusNode: _passwordFocusNode,
      scrollController: _scrollController,
      focusedFieldKey: _passwordFieldKey,
      revealTargetKey: _passwordRulesCardKey,
      minGapFromAppBar: 30,
      desiredRevealRatio: 0.9,
    );
    _passwordFocusNode.addListener(_handlePasswordFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      unawaited(_warmUpPasswordRulesInBackground());
    });
  }

  Future<void> _warmUpPasswordRulesInBackground() async {
    await ref
        .read(passwordValidationRulesProvider.notifier)
        .fetchInBackground();
  }

  void _handlePasswordFocusChanged() {
    _passwordFocusScrollCoordinator.onFocusChanged(context);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _passwordFocusScrollCoordinator.onMetricsChanged(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _passwordFocusScrollCoordinator.dispose();
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.removeListener(_handlePasswordFocusChanged);
    _passwordFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleUserNameChanged(String _) {
    if (_userNameError == null) {
      return;
    }

    setState(() {
      _userNameError = null;
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
      AppLocaleKeys.validationPasswordUniqueCharacters =>
        _pluralizedValidationKey(
          baseKey: AppLocaleKeys.validationPasswordUniqueCharacters,
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

  ValidationRuleSet _buildPasswordValidationRules(
    PasswordValidationRulesOutputDto? rules,
  ) {
    if (rules == null) {
      return const ValidationRuleSet(<ValidationRule>[
        RequiredValidationRule(),
      ]);
    }

    return rules.toValidationRuleSet();
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
      _userNameError = null;
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
        userName: _userNameController.text.trim().toLowerCase(),
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
      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((Route<void> route) => route.isFirst);
    } on AuthenticationException catch (error) {
      if (!mounted) {
        return;
      }

      final ValidationMappingResult mappedErrors = _validationErrorMapper.map(
        exception: error.failure,
        targetFields: const <String>{
          CreateUserInputDto.userNameField,
          CreateUserInputDto.emailField,
          CreateUserInputDto.passwordField,
        },
        memberAliases: const <String, String>{
          'username': CreateUserInputDto.userNameField,
          'email': CreateUserInputDto.emailField,
          'password': CreateUserInputDto.passwordField,
        },
      );

      setState(() {
        _userNameError =
            mappedErrors.fieldErrors[CreateUserInputDto.userNameField];
        _emailError = mappedErrors.fieldErrors[CreateUserInputDto.emailField];
        _passwordError =
            mappedErrors.fieldErrors[CreateUserInputDto.passwordField]
                    ?.trim()
                    .isNotEmpty ==
                true
            ? context.l10n.tr(AppLocaleKeys.authPasswordRequirementsNotMet)
            : null;
      });

      final String? globalError = mappedErrors.globalErrors
          .where((String e) => e.trim().isNotEmpty)
          .cast<String?>()
          .firstWhere((String? e) => e != null, orElse: () => null);

      final String? message = error.message ?? globalError;
      if (message != null && message.trim().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.tr(AppLocaleKeys.authSignUpFailed)),
          backgroundColor: Colors.red,
        ),
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
    final AsyncValue<PasswordValidationRulesOutputDto?> passwordRulesAsync = ref
        .watch(passwordValidationRulesProvider);
    final PasswordValidationRulesOutputDto? passwordRules =
        passwordRulesAsync.asData?.value;
    final bool hasPasswordRules = passwordRules != null;
    final bool isPasswordRulesLoading = passwordRulesAsync.isLoading;
    final ValidationRuleSet passwordValidationRules =
        _buildPasswordValidationRules(passwordRules);
    final ValidationRuleSet? effectivePasswordValidationRules = hasPasswordRules
        ? passwordValidationRules
        : null;
    final bool canSubmit = !_isLoading && !isPasswordRulesLoading;
    final Widget? passwordRulesWidget;
    if (isPasswordRulesLoading && !hasPasswordRules) {
      passwordRulesWidget = SizedBox(
        key: _passwordRulesCardKey,
        child: const PasswordValidationRulesCard(),
      );
    } else if (hasPasswordRules) {
      passwordRulesWidget = SizedBox(
        key: _passwordRulesCardKey,
        child: PasswordValidationRulesCard(
          rulesAsyncValue: AsyncValue<PasswordValidationRulesOutputDto>.data(
            passwordRules,
          ),
          currentPassword: _passwordController.text,
        ),
      );
    } else {
      passwordRulesWidget = null;
    }

    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(context.l10n.tr(AppLocaleKeys.authSignUpTitle)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
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
                    labelText: context.l10n.tr(AppLocaleKeys.authUserNameLabel),
                    hintText: context.l10n.tr(AppLocaleKeys.authUserNameHint),
                    controller: _userNameController,
                    onChanged: _handleUserNameChanged,
                    errorText: _userNameError,
                    isRequired: _userNameValidationRules.hasRequiredRule,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                    validator: _userNameValidationRules.asValidator(
                      _resolveValidationMessage,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    labelText: context.l10n.tr(AppLocaleKeys.authEmailLabel),
                    hintText: context.l10n.tr(AppLocaleKeys.authEmailHint),
                    controller: _emailController,
                    onChanged: _handleEmailChanged,
                    errorText: _emailError,
                    isRequired: _emailValidationRules.hasRequiredRule,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                    validator: _emailValidationRules.asValidator(
                      _resolveValidationMessage,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    key: _passwordFieldKey,
                    child: AppPasswordField(
                      labelText: context.l10n.tr(
                        AppLocaleKeys.authPasswordLabel,
                      ),
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      onChanged: _handlePasswordChanged,
                      errorText: _passwordError,
                      isRequired:
                          effectivePasswordValidationRules?.hasRequiredRule ??
                          true,
                      textInputAction: TextInputAction.done,
                      validator: effectivePasswordValidationRules?.asValidator(
                        (ValidationFailure failure) => context.l10n.tr(
                          AppLocaleKeys.authPasswordRequirementsNotMet,
                        ),
                      ),
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
                  const SizedBox(height: 16),
                  if (passwordRulesWidget case final Widget rulesWidget)
                    rulesWidget,
                  const SizedBox(height: 24),
                  AppButton(
                    label: context.l10n.tr(AppLocaleKeys.authSignUpAction),
                    isLoading: _isLoading,
                    onPressed: canSubmit ? _handleSignUp : null,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      context.l10n.tr(AppLocaleKeys.authBackToLoginAction),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
