import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/validation/full_name_validation.dart';
import 'package:global_airsoft_app/src/core/validation/validation.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/email_validation.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/password_validation_policy.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/username_validation.dart';

final class SignUpValidationIssue {
  const SignUpValidationIssue.validation(this.failure) : localizationKey = null;

  const SignUpValidationIssue.localization(this.localizationKey)
    : failure = null;

  final ValidationFailure? failure;
  final String? localizationKey;

  Future<String> resolve(AppLocalizationService localizationService) async {
    final ValidationFailure? validationFailure = failure;
    if (validationFailure != null) {
      return localizationService.trArgs(
        validationFailure.messageKey,
        args: validationFailure.arguments,
      );
    }

    return localizationService.tr(localizationKey!);
  }
}

final class SignUpFormValidationResult {
  const SignUpFormValidationResult({
    this.fullNameIssue,
    this.usernameIssue,
    this.emailIssue,
    this.passwordIssue,
    this.confirmPasswordIssue,
  });

  final SignUpValidationIssue? fullNameIssue;
  final SignUpValidationIssue? usernameIssue;
  final SignUpValidationIssue? emailIssue;
  final SignUpValidationIssue? passwordIssue;
  final SignUpValidationIssue? confirmPasswordIssue;

  bool get isValid =>
      fullNameIssue == null &&
      usernameIssue == null &&
      emailIssue == null &&
      passwordIssue == null &&
      confirmPasswordIssue == null;
}

final class SignUpFormValidator {
  const SignUpFormValidator();

  static final ValidationRuleSet _fullNameRules = FullNameValidation.rules;
  static final ValidationRuleSet _usernameRules = UsernameValidation.rules;
  static final ValidationRuleSet _emailRules = EmailValidation.rules;
  static final ValidationRuleSet _passwordRules =
      PasswordValidationPolicy.rules;

  static bool isFullNameValid(String value) {
    return _fullNameRules.validate(value) == null;
  }

  static bool isUsernameValid(String value) {
    return _usernameRules.validate(value) == null;
  }

  static bool isEmailValid(String value) {
    return _emailRules.validate(value) == null;
  }

  static bool isPasswordValid(String value) {
    return _passwordRules.validate(value) == null;
  }

  static bool isConfirmPasswordFilled(String value) {
    return value.trim().isNotEmpty;
  }

  static bool doPasswordsMatch({
    required String password,
    required String confirmPassword,
  }) {
    return password.isNotEmpty && password == confirmPassword;
  }

  SignUpFormValidationResult validate({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    return SignUpFormValidationResult(
      fullNameIssue: _validateRuleSet(_fullNameRules, fullName.trim()),
      usernameIssue: _validateRuleSet(_usernameRules, username.trim()),
      emailIssue: _validateRuleSet(_emailRules, email.trim()),
      passwordIssue: _validateRuleSet(_passwordRules, password),
      confirmPasswordIssue: validateLiveConfirmPassword(
        password: password,
        confirmPassword: confirmPassword,
        requireValue: true,
      ),
    );
  }

  SignUpValidationIssue? validateLiveConfirmPassword({
    required String password,
    required String confirmPassword,
    bool requireValue = false,
  }) {
    if (requireValue && !isConfirmPasswordFilled(confirmPassword)) {
      return const SignUpValidationIssue.localization(
        AppLocaleKeys.authConfirmPasswordRequired,
      );
    }

    if (confirmPassword.trim().isEmpty) {
      return null;
    }

    if (!doPasswordsMatch(
      password: password,
      confirmPassword: confirmPassword,
    )) {
      return const SignUpValidationIssue.localization(
        AppLocaleKeys.authConfirmPasswordMismatch,
      );
    }

    return null;
  }

  SignUpValidationIssue? _validateRuleSet(
    ValidationRuleSet rules,
    String value,
  ) {
    final ValidationFailure? failure = rules.validate(value);
    if (failure == null) {
      return null;
    }

    return SignUpValidationIssue.validation(failure);
  }
}
