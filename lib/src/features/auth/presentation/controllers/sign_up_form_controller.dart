import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/forms/forms.dart' as app_forms;
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/validation/backend_validation_error_mapper.dart';
import 'package:global_airsoft_app/src/core/validation/validation_mapping_result.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/create_user_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/state/sign_up_form_state.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/validators/sign_up_form_validator.dart';
import 'package:global_airsoft_app/src/features/users/application/providers/current_user_profile_providers.dart';

final signUpFormControllerProvider =
    NotifierProvider.autoDispose<SignUpFormController, SignUpFormState>(
      SignUpFormController.new,
    );

final class SignUpFormController extends Notifier<SignUpFormState> {
  static const BackendValidationErrorMapper _validationErrorMapper =
      BackendValidationErrorMapper();
  static const SignUpFormValidator _validator = SignUpFormValidator();
  static const String _initialStringValue = '';

  @override
  SignUpFormState build() {
    return const SignUpFormState();
  }

  AppLocalizationService get _localizationService {
    return ref.read(appLocalizationServiceProvider);
  }

  void updateFullName(String value) {
    state = state.copyWith(
      fullName: _fieldChanged(state.fullName, value),
      generalError: null,
    );
  }

  void updateUsername(String value) {
    state = state.copyWith(
      username: _fieldChanged(state.username, value),
      generalError: null,
    );
  }

  void updateEmail(String value) {
    state = state.copyWith(
      email: _fieldChanged(state.email, value),
      generalError: null,
    );
  }

  void updatePassword(String value) {
    state = state.copyWith(
      password: _fieldChanged(state.password, value),
      confirmPassword: _clearConfirmPasswordError(state.confirmPassword),
      generalError: null,
    );

    if (state.confirmPassword.value.trim().isNotEmpty) {
      _refreshConfirmPasswordIssue();
    }
  }

  void updateConfirmPassword(String value) {
    state = state.copyWith(
      confirmPassword: _fieldChanged(state.confirmPassword, value),
      generalError: null,
    );

    _refreshConfirmPasswordIssue();
  }

  void reset() {
    state = const SignUpFormState();
  }

  Future<void> submit() async {
    if (state.isSubmitting) {
      return;
    }

    final AppLocalizationService localizationService = _localizationService;
    final SignUpFormValidationResult validationResult = _validator.validate(
      fullName: state.fullName.value,
      username: state.username.value,
      email: state.email.value,
      password: state.password.value,
      confirmPassword: state.confirmPassword.value,
    );

    state = state.copyWith(
      fullName: await _fieldValidated(
        state.fullName,
        validationResult.fullNameIssue,
        localizationService,
      ),
      username: await _fieldValidated(
        state.username,
        validationResult.usernameIssue,
        localizationService,
      ),
      email: await _fieldValidated(
        state.email,
        validationResult.emailIssue,
        localizationService,
      ),
      password: await _fieldValidated(
        state.password,
        validationResult.passwordIssue,
        localizationService,
      ),
      confirmPassword: await _fieldValidated(
        state.confirmPassword,
        validationResult.confirmPasswordIssue,
        localizationService,
      ),
      generalError: null,
      wasSubmitted: true,
    );

    if (!validationResult.isValid) {
      return;
    }

    state = state.copyWith(isSubmitting: true, generalError: null);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUp(
        fullName: state.trimmedFullName,
        username: state.trimmedUsername.toLowerCase(),
        email: state.trimmedEmail,
        password: state.password.value,
      );

      await _completeAuthenticatedSession();
      reset();
    } on AuthenticationException catch (error) {
      await _applyAuthenticationFailure(error);
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Unexpected signup failure.',
        error: error,
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        generalError: await localizationService.tr(
          AppLocaleKeys.authSignUpFailed,
        ),
      );
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  app_forms.FormFieldState<String> _fieldChanged(
    app_forms.FormFieldState<String> field,
    String value, {
    String? error,
  }) {
    return field.copyWith(
      value: value,
      error: error,
      isTouched: true,
      isDirty: value != _initialStringValue,
    );
  }

  Future<app_forms.FormFieldState<String>> _fieldValidated(
    app_forms.FormFieldState<String> field,
    SignUpValidationIssue? issue,
    AppLocalizationService localizationService,
  ) async {
    final String? error = issue == null
        ? null
        : await issue.resolve(localizationService);

    return field.copyWith(error: error, isTouched: true);
  }

  app_forms.FormFieldState<String> _clearConfirmPasswordError(
    app_forms.FormFieldState<String> confirmPasswordField,
  ) {
    return confirmPasswordField.clearError();
  }

  Future<void> _refreshConfirmPasswordIssue() async {
    final String password = state.password.value;
    final String confirmPassword = state.confirmPassword.value;
    final SignUpValidationIssue? issue = _validator.validateLiveConfirmPassword(
      password: password,
      confirmPassword: confirmPassword,
    );
    final String? error = issue == null
        ? null
        : await issue.resolve(_localizationService);

    if (password != state.password.value ||
        confirmPassword != state.confirmPassword.value) {
      return;
    }

    state = state.copyWith(
      confirmPassword: state.confirmPassword.copyWith(error: error),
    );
  }

  Future<void> _applyAuthenticationFailure(
    AuthenticationException error,
  ) async {
    final ValidationMappingResult mappedErrors = _validationErrorMapper.map(
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

    final String fallbackMessage = await _localizationService.tr(
      AppLocaleKeys.authSignUpFailed,
    );
    final String? message =
        error.message ?? _firstMeaningfulGlobalError(mappedErrors);

    state = state.copyWith(
      fullName: _applyBackendFieldError(
        state.fullName,
        mappedErrors.fieldErrors[CreateUserInputDto.fullNameField],
      ),
      username: _applyBackendFieldError(
        state.username,
        mappedErrors.fieldErrors[CreateUserInputDto.usernameField],
      ),
      email: _applyBackendFieldError(
        state.email,
        mappedErrors.fieldErrors[CreateUserInputDto.emailField],
      ),
      password: _applyBackendFieldError(
        state.password,
        mappedErrors.fieldErrors[CreateUserInputDto.passwordField],
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

  Future<void> _completeAuthenticatedSession() async {
    await ref
        .read(appLocaleControllerProvider.notifier)
        .forceApplyServerLocaleIfPending();
    ref.read(currentUserProfileRefreshRequestProvider.notifier).clear();
    ref.invalidate(currentUserProfileRefreshRequestProvider);
    ref.invalidate(currentUserProfileProvider);
    ref.read(isAuthenticatedProvider.notifier).setAuthenticated();
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
