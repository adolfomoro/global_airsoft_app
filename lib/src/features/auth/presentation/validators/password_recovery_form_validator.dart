import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/validation/validation.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/email_validation.dart';

final class PasswordRecoveryValidationIssue {
  const PasswordRecoveryValidationIssue.validation(this.failure);

  final ValidationFailure failure;

  Future<String> resolve(AppLocalizationService localizationService) {
    return localizationService.trArgs(
      failure.messageKey,
      args: failure.arguments,
    );
  }
}

final class PasswordRecoveryFormValidationResult {
  const PasswordRecoveryFormValidationResult({this.emailIssue});

  final PasswordRecoveryValidationIssue? emailIssue;

  bool get isValid => emailIssue == null;
}

final class PasswordRecoveryFormValidator {
  const PasswordRecoveryFormValidator();

  static final ValidationRuleSet _emailRules = EmailValidation.rules;

  static bool isEmailValid(String value) {
    return _emailRules.validate(value) == null;
  }

  PasswordRecoveryFormValidationResult validate({required String email}) {
    return PasswordRecoveryFormValidationResult(
      emailIssue: _validateRuleSet(_emailRules, email.trim()),
    );
  }

  PasswordRecoveryValidationIssue? _validateRuleSet(
    ValidationRuleSet rules,
    String value,
  ) {
    final ValidationFailure? failure = rules.validate(value);
    if (failure == null) {
      return null;
    }

    return PasswordRecoveryValidationIssue.validation(failure);
  }
}
