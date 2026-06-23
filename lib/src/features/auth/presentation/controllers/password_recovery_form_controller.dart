import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/forms/forms.dart' as app_forms;
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/validation/backend_validation_error_mapper.dart';
import 'package:global_airsoft_app/src/core/validation/validation_mapping_result.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/request_password_recovery_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/state/password_recovery_form_state.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/validators/password_recovery_form_validator.dart';

final passwordRecoveryFormControllerProvider =
    NotifierProvider.autoDispose<
      PasswordRecoveryFormController,
      PasswordRecoveryFormState
    >(PasswordRecoveryFormController.new);

final class PasswordRecoveryFormController
    extends Notifier<PasswordRecoveryFormState> {
  static const BackendValidationErrorMapper _validationErrorMapper =
      BackendValidationErrorMapper();
  static const PasswordRecoveryFormValidator _validator =
      PasswordRecoveryFormValidator();
  static const String _initialStringValue = '';

  @override
  PasswordRecoveryFormState build() {
    return const PasswordRecoveryFormState();
  }

  AppLocalizationService get _localizationService {
    return ref.read(appLocalizationServiceProvider);
  }

  void updateEmail(String value) {
    state = state.copyWith(
      email: _fieldChanged(state.email, value),
      generalError: null,
    );
  }

  void reset() {
    state = const PasswordRecoveryFormState();
  }

  Future<String?> submit() async {
    if (state.isSubmitting) {
      return null;
    }

    final AppLocalizationService localizationService = _localizationService;
    final PasswordRecoveryFormValidationResult validationResult = _validator
        .validate(email: state.email.value);

    state = state.copyWith(
      email: await _fieldValidated(
        state.email,
        validationResult.emailIssue,
        localizationService,
      ),
      generalError: null,
      wasSubmitted: true,
    );

    if (!validationResult.isValid) {
      return null;
    }

    state = state.copyWith(isSubmitting: true, generalError: null);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.requestPasswordRecovery(state.trimmedEmail);
      return state.trimmedEmail;
    } on AuthenticationException catch (error) {
      await _applyFailure(error);
      return null;
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Unexpected password recovery failure.',
        error: error,
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        generalError: await localizationService.tr(
          AppLocaleKeys.authPasswordRecoveryFailed,
        ),
      );
      return null;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  app_forms.FormFieldState<String> _fieldChanged(
    app_forms.FormFieldState<String> field,
    String value,
  ) {
    return field.copyWith(
      value: value,
      error: null,
      isTouched: true,
      isDirty: value != _initialStringValue,
    );
  }

  Future<app_forms.FormFieldState<String>> _fieldValidated(
    app_forms.FormFieldState<String> field,
    PasswordRecoveryValidationIssue? issue,
    AppLocalizationService localizationService,
  ) async {
    final String? error = issue == null
        ? null
        : await issue.resolve(localizationService);

    return field.copyWith(error: error, isTouched: true);
  }

  Future<void> _applyFailure(AuthenticationException error) async {
    final ValidationMappingResult mappedErrors = _validationErrorMapper.map(
      exception: error.failure,
      targetFields: const <String>{RequestPasswordRecoveryInputDto.emailField},
      memberAliases: const <String, String>{
        'email': RequestPasswordRecoveryInputDto.emailField,
      },
    );

    final String fallbackMessage = await _localizationService.tr(
      AppLocaleKeys.authPasswordRecoveryFailed,
    );
    final String? message =
        error.message ?? _firstMeaningfulGlobalError(mappedErrors);

    state = state.copyWith(
      email: _applyBackendFieldError(
        state.email,
        mappedErrors.fieldErrors[RequestPasswordRecoveryInputDto.emailField],
      ),
      generalError: message ?? fallbackMessage,
      wasSubmitted: true,
    );
  }

  app_forms.FormFieldState<String> _applyBackendFieldError(
    app_forms.FormFieldState<String> field,
    String? error,
  ) {
    if (error == null) {
      return field;
    }

    return field.copyWith(error: error, isTouched: true);
  }

  String? _firstMeaningfulGlobalError(ValidationMappingResult mappedErrors) {
    for (final String value in mappedErrors.globalErrors) {
      final String trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return null;
  }
}
