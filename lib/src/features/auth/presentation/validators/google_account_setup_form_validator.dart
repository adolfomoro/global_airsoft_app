import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/validation/validation.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/username_validation.dart';

final class GoogleAccountSetupValidationIssue {
  const GoogleAccountSetupValidationIssue.validation(this.failure);

  final ValidationFailure failure;

  Future<String> resolve(AppLocalizationService localizationService) {
    return localizationService.trArgs(
      failure.messageKey,
      args: failure.arguments,
    );
  }
}

final class GoogleAccountSetupValidationResult {
  const GoogleAccountSetupValidationResult({this.usernameIssue});

  final GoogleAccountSetupValidationIssue? usernameIssue;

  bool get isValid => usernameIssue == null;
}

final class GoogleAccountSetupFormValidator {
  const GoogleAccountSetupFormValidator();

  static final ValidationRuleSet _usernameRules = UsernameValidation.rules;

  static bool isUsernameValid(String value) {
    return _usernameRules.validate(value) == null;
  }

  GoogleAccountSetupValidationResult validate({required String username}) {
    return GoogleAccountSetupValidationResult(
      usernameIssue: _validateRuleSet(
        _usernameRules,
        username.trim().toLowerCase(),
      ),
    );
  }

  GoogleAccountSetupValidationIssue? _validateRuleSet(
    ValidationRuleSet rules,
    String value,
  ) {
    final ValidationFailure? failure = rules.validate(value);
    if (failure == null) {
      return null;
    }

    return GoogleAccountSetupValidationIssue.validation(failure);
  }
}
