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
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/password_requirements_hint.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/username_availability_field.dart';

final class SignUpFormState {
  const SignUpFormState({
    this.fullNameError,
    this.usernameError,
    this.emailError,
    this.passwordError,
    this.usernameAvailabilityStatus = UsernameAvailabilityStatus.idle,
    this.isLoading = false,
    this.isPasswordFocused = false,
    this.hasRevealedPasswordHint = false,
  });
  final String? fullNameError;

  final String? usernameError;

  final String? emailError;

  final String? passwordError;

  final UsernameAvailabilityStatus usernameAvailabilityStatus;

  final bool isLoading;

  final bool isPasswordFocused;

  final bool hasRevealedPasswordHint;

  SignUpFormState copyWith({
    String? fullNameError,
    String? usernameError,
    String? emailError,
    String? passwordError,
    UsernameAvailabilityStatus? usernameAvailabilityStatus,
    bool? isLoading,
    bool? isPasswordFocused,
    bool? hasRevealedPasswordHint,
  }) {
    return SignUpFormState(
      fullNameError: fullNameError ?? this.fullNameError,
      usernameError: usernameError ?? this.usernameError,
      emailError: emailError ?? this.emailError,
      passwordError: passwordError ?? this.passwordError,
      usernameAvailabilityStatus:
          usernameAvailabilityStatus ?? this.usernameAvailabilityStatus,
      isLoading: isLoading ?? this.isLoading,
      isPasswordFocused: isPasswordFocused ?? this.isPasswordFocused,
      hasRevealedPasswordHint:
          hasRevealedPasswordHint ?? this.hasRevealedPasswordHint,
    );
  }

  SignUpFormState clearErrors() {
    return copyWith(
      fullNameError: null,
      usernameError: null,
      emailError: null,
      passwordError: null,
    );
  }
}

enum SignUpFieldType { fullName, username, email, password }

final Provider<TextEditingController> signUpFullNameControllerProvider =
    Provider<TextEditingController>((Ref ref) => TextEditingController());

final Provider<TextEditingController> signUpUsernameControllerProvider =
    Provider<TextEditingController>((Ref ref) => TextEditingController());

final Provider<TextEditingController> signUpEmailControllerProvider =
    Provider<TextEditingController>((Ref ref) => TextEditingController());

final Provider<TextEditingController> signUpPasswordControllerProvider =
    Provider<TextEditingController>((Ref ref) => TextEditingController());

final Provider<TextEditingController> signUpConfirmPasswordControllerProvider =
    Provider<TextEditingController>((Ref ref) => TextEditingController());

final Provider<FocusNode> signUpPasswordFocusNodeProvider = Provider<FocusNode>(
  (Ref ref) => FocusNode(),
);

final Provider<ScrollController> signUpScrollControllerProvider =
    Provider<ScrollController>((Ref ref) => ScrollController());

final class SignUpFormNotifier extends Notifier<SignUpFormState> {
  static const BackendValidationErrorMapper _validationErrorMapper =
      BackendValidationErrorMapper();

  @override
  SignUpFormState build() {
    return const SignUpFormState();
  }

  void clearErrors() {
    state = state.clearErrors();
  }

  void setPasswordFocused(bool isFocused) {
    state = state.copyWith(
      isPasswordFocused: isFocused,
      hasRevealedPasswordHint: isFocused
          ? state.hasRevealedPasswordHint
          : false,
    );
  }

  void markPasswordHintRevealed() {
    state = state.copyWith(hasRevealedPasswordHint: true);
  }

  void clearFieldError(SignUpFieldType fieldType) {
    switch (fieldType) {
      case SignUpFieldType.fullName:
        state = state.copyWith(fullNameError: null);
      case SignUpFieldType.username:
        state = state.copyWith(usernameError: null);
      case SignUpFieldType.email:
        state = state.copyWith(emailError: null);
      case SignUpFieldType.password:
        state = state.copyWith(passwordError: null);
    }
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setUsernameAvailabilityStatus(UsernameAvailabilityStatus status) {
    if (state.usernameAvailabilityStatus == status) {
      return;
    }

    state = state.copyWith(usernameAvailabilityStatus: status);
  }

  void setFieldError(SignUpFieldType fieldType, String? error) {
    switch (fieldType) {
      case SignUpFieldType.fullName:
        state = state.copyWith(fullNameError: error);
      case SignUpFieldType.username:
        state = state.copyWith(usernameError: error);
      case SignUpFieldType.email:
        state = state.copyWith(emailError: error);
      case SignUpFieldType.password:
        state = state.copyWith(passwordError: error);
    }
  }

  void handleBackendValidationErrors(AuthenticationException error) {
    final ValidationMappingResult mappedErrors = _validationErrorMapper.map(
      exception: error.failure,
      targetFields: const <String>{
        CreateUserInputDto.fullNameField,
        CreateUserInputDto.usernameField,
        CreateUserInputDto.emailField,
        CreateUserInputDto.passwordField,
      },
    );

    state = state.copyWith(
      fullNameError: mappedErrors.fieldErrors[CreateUserInputDto.fullNameField],
      usernameError: mappedErrors.fieldErrors[CreateUserInputDto.usernameField],
      emailError: mappedErrors.fieldErrors[CreateUserInputDto.emailField],
      passwordError:
          (mappedErrors.fieldErrors[CreateUserInputDto.passwordField]
                  ?.trim()
                  .isNotEmpty ??
              false)
          ? mappedErrors.fieldErrors[CreateUserInputDto.passwordField]
          : null,
    );
  }
}

final NotifierProvider<SignUpFormNotifier, SignUpFormState>
signUpFormStateProvider = NotifierProvider<SignUpFormNotifier, SignUpFormState>(
  SignUpFormNotifier.new,
);

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage>
    with WidgetsBindingObserver {
  static final ValidationRuleSet _fullNameValidationRules =
      FullNameValidation.rules;
  static final ValidationRuleSet _emailValidationRules = EmailValidation.rules;
  static final ValidationRuleSet _passwordValidationRules =
      PasswordValidationPolicy.rules;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _passwordFieldKey = GlobalKey();
  final GlobalKey _passwordHintKey = GlobalKey();
  late final FocusAwareScrollCoordinator _passwordHintScrollCoordinator;
  late final FocusNode _passwordFocus;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _passwordFocus = ref.read(signUpPasswordFocusNodeProvider);
      _scrollController = ref.read(signUpScrollControllerProvider);

      _passwordHintScrollCoordinator = FocusAwareScrollCoordinator(
        focusNode: _passwordFocus,
        scrollController: _scrollController,
        focusedFieldKey: _passwordFieldKey,
        revealTargetKey: _passwordHintKey,
        desiredRevealRatio: 1.0,
      );

      _passwordFocus.addListener(_handlePasswordFocusChanged);
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final signUpState = ref.read(signUpFormStateProvider);
    final passwordText = _scrollController.hasClients
        ? ref.read(signUpPasswordControllerProvider).text
        : '';

    if (signUpState.hasRevealedPasswordHint &&
        _shouldShowPasswordHint(passwordText)) {
      _passwordHintScrollCoordinator.onMetricsChanged(context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _passwordFocus.removeListener(_handlePasswordFocusChanged);
    super.dispose();
  }

  void _handlePasswordFocusChanged() {
    final isFocused = _passwordFocus.hasFocus;
    final currentFocusState = ref
        .read(signUpFormStateProvider)
        .isPasswordFocused;

    if (isFocused == currentFocusState) {
      return;
    }

    ref.read(signUpFormStateProvider.notifier).setPasswordFocused(isFocused);
    _requestPasswordHintRevealIfNeeded();
  }

  void _handleFieldChanged(SignUpFieldType fieldType) {
    ref.read(signUpFormStateProvider.notifier).clearFieldError(fieldType);
  }

  void _handlePasswordChanged() {
    _handleFieldChanged(SignUpFieldType.password);
    _requestPasswordHintRevealIfNeeded();
  }

  void _handleUsernameAvailabilityChanged(UsernameAvailabilityStatus status) {
    ref
        .read(signUpFormStateProvider.notifier)
        .setUsernameAvailabilityStatus(status);
  }

  bool _shouldShowPasswordHint(String passwordText) {
    return _passwordValidationRules.validate(passwordText) != null &&
        (ref.read(signUpFormStateProvider).isPasswordFocused ||
            passwordText.isNotEmpty);
  }

  bool _shouldRevealPasswordHintNow(String passwordText) {
    final signUpState = ref.read(signUpFormStateProvider);
    return signUpState.isPasswordFocused &&
        _shouldShowPasswordHint(passwordText) &&
        !signUpState.hasRevealedPasswordHint;
  }

  void _requestPasswordHintRevealIfNeeded() {
    final passwordText = ref.read(signUpPasswordControllerProvider).text;

    if (!_shouldRevealPasswordHintNow(passwordText)) {
      return;
    }

    ref.read(signUpFormStateProvider.notifier).markPasswordHintRevealed();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_shouldShowPasswordHint(passwordText)) {
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

    final passwordText = ref.read(signUpPasswordControllerProvider).text;
    if (normalizedValue != passwordText) {
      return context.l10n.tr(AppLocaleKeys.authConfirmPasswordMismatch);
    }

    return null;
  }

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();
    ref.read(signUpFormStateProvider.notifier).clearErrors();

    final FormState? formState = _formKey.currentState;
    if (!(formState?.validate() ?? false)) {
      return;
    }

    ref.read(signUpFormStateProvider.notifier).setLoading(true);

    try {
      final fullNameController = ref.read(signUpFullNameControllerProvider);
      final usernameController = ref.read(signUpUsernameControllerProvider);
      final emailController = ref.read(signUpEmailControllerProvider);
      final passwordController = ref.read(signUpPasswordControllerProvider);

      final AuthService authService = ref.read(authServiceProvider);
      await authService.signUp(
        username: usernameController.text.trim().toLowerCase(),
        fullName: fullNameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
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

      ref
          .read(signUpFormStateProvider.notifier)
          .handleBackendValidationErrors(error);

      final String fallbackMessage = context.l10n.tr(
        AppLocaleKeys.authSignUpFailed,
      );
      final String message = error.message ?? fallbackMessage;
      if (message.trim().isNotEmpty) {
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
        ref.read(signUpFormStateProvider.notifier).setLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final signUpState = ref.watch(signUpFormStateProvider);
    final scrollController = ref.watch(signUpScrollControllerProvider);
    final bool canSubmit =
        !signUpState.isLoading &&
        signUpState.usernameAvailabilityStatus !=
            UsernameAvailabilityStatus.waiting &&
        signUpState.usernameAvailabilityStatus !=
            UsernameAvailabilityStatus.checking &&
        signUpState.usernameAvailabilityStatus !=
            UsernameAvailabilityStatus.unavailable;

    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(context.l10n.tr(AppLocaleKeys.authSignUpAction)),
      ),
      body: Form(
        key: _formKey,
        child: AppFormWithBottomActions(
          scrollController: scrollController,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 20),
              _SignUpFormHeader(),
              const SizedBox(height: 24),
              _SignUpFormFields(
                fullNameValidationRules: _fullNameValidationRules,
                emailValidationRules: _emailValidationRules,
                passwordValidationRules: _passwordValidationRules,
                onFieldChanged: _handleFieldChanged,
                onPasswordChanged: _handlePasswordChanged,
                onUsernameAvailabilityChanged:
                    _handleUsernameAvailabilityChanged,
                resolveValidationMessage: _resolveValidationMessage,
                validateConfirmPassword: _validateConfirmPassword,
                passwordFieldKey: _passwordFieldKey,
                passwordHintKey: _passwordHintKey,
                signUpState: signUpState,
              ),
              const SizedBox(height: 24),
            ],
          ),
          bottomActions: <AppFormBottomAction>[
            AppFormBottomAction(
              showWhenKeyboardOpen: true,
              child: AppButton(
                label: context.l10n.tr(AppLocaleKeys.authSignUpAction),
                isLoading: signUpState.isLoading,
                onPressed: canSubmit ? _handleSignUp : null,
              ),
            ),
            AppFormBottomAction(child: const SizedBox(height: 8)),
            AppFormBottomAction(
              showWhenKeyboardOpen: false,
              child: TextButton(
                onPressed: signUpState.isLoading
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

class _SignUpFormHeader extends ConsumerWidget {
  const _SignUpFormHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
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
      ],
    );
  }
}

class _SignUpFormFields extends ConsumerWidget {
  const _SignUpFormFields({
    required this.fullNameValidationRules,
    required this.emailValidationRules,
    required this.passwordValidationRules,
    required this.onFieldChanged,
    required this.onPasswordChanged,
    required this.onUsernameAvailabilityChanged,
    required this.resolveValidationMessage,
    required this.validateConfirmPassword,
    required this.passwordFieldKey,
    required this.passwordHintKey,
    required this.signUpState,
  });

  final ValidationRuleSet fullNameValidationRules;
  final ValidationRuleSet emailValidationRules;
  final ValidationRuleSet passwordValidationRules;
  final void Function(SignUpFieldType) onFieldChanged;
  final VoidCallback onPasswordChanged;
  final ValueChanged<UsernameAvailabilityStatus> onUsernameAvailabilityChanged;
  final String Function(ValidationFailure) resolveValidationMessage;
  final String? Function(String?) validateConfirmPassword;
  final GlobalKey passwordFieldKey;
  final GlobalKey passwordHintKey;
  final SignUpFormState signUpState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = ref.watch(signUpUsernameControllerProvider);
    final fullNameController = ref.watch(signUpFullNameControllerProvider);
    final emailController = ref.watch(signUpEmailControllerProvider);
    final passwordController = ref.watch(signUpPasswordControllerProvider);
    final confirmPasswordController = ref.watch(
      signUpConfirmPasswordControllerProvider,
    );
    final passwordFocusNode = ref.watch(signUpPasswordFocusNodeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        UsernameAvailabilityField(
          controller: usernameController,
          onChanged: (_) => onFieldChanged(SignUpFieldType.username),
          errorText: signUpState.usernameError,
          onAvailabilityChanged: onUsernameAvailabilityChanged,
        ),
        const SizedBox(height: 16),
        AppTextField(
          labelText: context.l10n.tr(AppLocaleKeys.authFullNameLabel),
          controller: fullNameController,
          onChanged: (_) => onFieldChanged(SignUpFieldType.fullName),
          errorText: signUpState.fullNameError,
          isRequired: fullNameValidationRules.hasRequiredRule,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          validator: fullNameValidationRules.asValidator(
            resolveValidationMessage,
          ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          labelText: context.l10n.tr(AppLocaleKeys.authEmailLabel),
          controller: emailController,
          onChanged: (_) => onFieldChanged(SignUpFieldType.email),
          errorText: signUpState.emailError,
          isRequired: emailValidationRules.hasRequiredRule,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: emailValidationRules.asValidator(resolveValidationMessage),
        ),
        const SizedBox(height: 16),
        AppPasswordField(
          key: passwordFieldKey,
          labelText: context.l10n.tr(AppLocaleKeys.authPasswordLabel),
          controller: passwordController,
          focusNode: passwordFocusNode,
          onChanged: (_) => onPasswordChanged(),
          errorText: signUpState.passwordError,
          isRequired: passwordValidationRules.hasRequiredRule,
          textInputAction: TextInputAction.done,
          validator: passwordValidationRules.asValidator(
            resolveValidationMessage,
          ),
        ),
        SizedBox(
          key: passwordHintKey,
          child: PasswordRequirementsHint(
            currentPassword: passwordController.text,
            isFocused: signUpState.isPasswordFocused,
          ),
        ),
        const SizedBox(height: 16),
        AppPasswordField(
          controller: confirmPasswordController,
          labelText: context.l10n.tr(AppLocaleKeys.authConfirmPasswordLabel),
          isRequired: true,
          textInputAction: TextInputAction.done,
          validator: validateConfirmPassword,
        ),
      ],
    );
  }
}
