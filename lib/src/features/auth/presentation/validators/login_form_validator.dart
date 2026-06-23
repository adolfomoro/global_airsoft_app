import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/validation/validation.dart';

final class LoginValidationIssue {
  const LoginValidationIssue.validation(this.failure);

  final ValidationFailure failure;

  Future<String> resolve(AppLocalizationService localizationService) {
    return localizationService.trArgs(
      failure.messageKey,
      args: failure.arguments,
    );
  }
}

final class LoginFormValidationResult {
  const LoginFormValidationResult({this.loginIssue, this.passwordIssue});

  final LoginValidationIssue? loginIssue;
  final LoginValidationIssue? passwordIssue;

  bool get isValid => loginIssue == null && passwordIssue == null;
}

final class LoginFormValidator {
  const LoginFormValidator();

  static final ValidationRuleSet _loginRules = ValidationRuleSet(
    <ValidationRule>[RequiredValidationRule()],
  );
  static final ValidationRuleSet _passwordRules = ValidationRuleSet(
    <ValidationRule>[RequiredValidationRule()],
  );

  static bool isLoginValid(String value) {
    return _loginRules.validate(value) == null;
  }

  static bool isPasswordValid(String value) {
    return _passwordRules.validate(value) == null;
  }

  LoginFormValidationResult validate({
    required String login,
    required String password,
  }) {
    return LoginFormValidationResult(
      loginIssue: _validateRuleSet(_loginRules, login.trim()),
      passwordIssue: _validateRuleSet(_passwordRules, password),
    );
  }

  LoginValidationIssue? _validateRuleSet(
    ValidationRuleSet rules,
    String value,
  ) {
    final ValidationFailure? failure = rules.validate(value);
    if (failure == null) {
      return null;
    }

    return LoginValidationIssue.validation(failure);
  }
}
