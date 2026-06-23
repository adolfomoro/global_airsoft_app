import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/forms/forms.dart' as app_forms;
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/validation/backend_validation_error_mapper.dart';
import 'package:global_airsoft_app/src/core/validation/validation_mapping_result.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/google_sign_in_exception.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/user_login_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/state/login_form_state.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/validators/login_form_validator.dart';
import 'package:global_airsoft_app/src/features/users/application/providers/current_user_profile_providers.dart';

final loginFormControllerProvider =
    NotifierProvider.autoDispose<LoginFormController, LoginFormState>(
      LoginFormController.new,
    );

final class GoogleAccountSetupNavigationData {
  const GoogleAccountSetupNavigationData({
    required this.challengeToken,
    required this.profilePictureUrl,
    required this.profileName,
  });

  final String challengeToken;
  final String? profilePictureUrl;
  final String profileName;
}

final class LoginFormController extends Notifier<LoginFormState> {
  static const BackendValidationErrorMapper _validationErrorMapper =
      BackendValidationErrorMapper();
  static const LoginFormValidator _validator = LoginFormValidator();
  static const String _initialStringValue = '';

  @override
  LoginFormState build() {
    return const LoginFormState();
  }

  AppLocalizationService get _localizationService {
    return ref.read(appLocalizationServiceProvider);
  }

  void updateLogin(String value) {
    state = state.copyWith(
      login: _fieldChanged(state.login, value),
      generalError: null,
    );
  }

  void updatePassword(String value) {
    state = state.copyWith(
      password: _fieldChanged(state.password, value),
      generalError: null,
    );
  }

  void reset() {
    state = const LoginFormState();
  }

  Future<void> submitCredentials() async {
    if (state.isSubmitting) {
      return;
    }

    final AppLocalizationService localizationService = _localizationService;
    final LoginFormValidationResult validationResult = _validator.validate(
      login: state.login.value,
      password: state.password.value,
    );

    state = state.copyWith(
      login: await _fieldValidated(
        state.login,
        validationResult.loginIssue,
        localizationService,
      ),
      password: await _fieldValidated(
        state.password,
        validationResult.passwordIssue,
        localizationService,
      ),
      generalError: null,
      wasSubmitted: true,
    );

    if (!validationResult.isValid) {
      return;
    }

    state = state.copyWith(
      activeSubmission: LoginSubmissionType.credentials,
      generalError: null,
    );

    try {
      final authService = ref.read(authServiceProvider);
      await authService.login(state.trimmedLogin, state.password.value);
      await _completeAuthenticatedSession();
    } on AuthenticationException catch (error) {
      await _applyCredentialFailure(error);
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Unexpected login failure.',
        error: error,
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        generalError: await localizationService.tr(
          AppLocaleKeys.authLoginFailed,
        ),
      );
    } finally {
      state = state.copyWith(activeSubmission: null);
    }
  }

  Future<GoogleAccountSetupNavigationData?> submitGoogle() async {
    if (state.isSubmitting) {
      return null;
    }

    state = state.copyWith(
      activeSubmission: LoginSubmissionType.google,
      generalError: null,
    );

    try {
      final googleSignInService = ref.read(googleSignInServiceProvider);
      final String? idToken = await googleSignInService.requestIdToken();

      if (idToken == null) {
        return null;
      }

      final authService = ref.read(authServiceProvider);
      final response = await authService.signInWithGoogle(idToken);

      if (response.userExists) {
        await _completeAuthenticatedSession();
        return null;
      }

      final suggestion = response.suggestion;
      if (suggestion == null) {
        throw const GoogleSignInException(
          'Google sign-in returned no profile suggestion.',
        );
      }

      return GoogleAccountSetupNavigationData(
        challengeToken: response.challengeToken ?? '',
        profilePictureUrl: suggestion.profilePictureUrl,
        profileName: suggestion.username,
      );
    } on AuthenticationException catch (error) {
      await _applyGoogleFailure(error);
      return null;
    } on GoogleSignInException {
      state = state.copyWith(
        generalError: await _localizationService.tr(
          AppLocaleKeys.authGoogleSignInFailed,
        ),
      );
      return null;
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Unexpected Google sign-in failure.',
        error: error,
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        generalError: await _localizationService.tr(
          AppLocaleKeys.authGoogleSignInFailed,
        ),
      );
      return null;
    } finally {
      state = state.copyWith(activeSubmission: null);
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
    LoginValidationIssue? issue,
    AppLocalizationService localizationService,
  ) async {
    final String? error = issue == null
        ? null
        : await issue.resolve(localizationService);

    return field.copyWith(error: error, isTouched: true);
  }

  Future<void> _applyCredentialFailure(AuthenticationException error) async {
    final ValidationMappingResult mappedErrors = _validationErrorMapper.map(
      exception: error.failure,
      targetFields: const <String>{
        UserLoginInputDto.loginField,
        UserLoginInputDto.passwordField,
      },
      memberAliases: const <String, String>{
        UserLoginInputDto.loginField: UserLoginInputDto.loginField,
        UserLoginInputDto.passwordField: UserLoginInputDto.passwordField,
      },
    );

    final String fallbackMessage = await _localizationService.tr(
      AppLocaleKeys.authLoginFailed,
    );
    final String? message =
        error.message ?? _firstMeaningfulGlobalError(mappedErrors);

    state = state.copyWith(
      login: _applyBackendFieldError(
        state.login,
        mappedErrors.fieldErrors[UserLoginInputDto.loginField],
      ),
      password: _applyBackendFieldError(
        state.password,
        mappedErrors.fieldErrors[UserLoginInputDto.passwordField],
      ),
      generalError: message ?? fallbackMessage,
      wasSubmitted: true,
    );
  }

  Future<void> _applyGoogleFailure(AuthenticationException error) async {
    final ValidationMappingResult mappedErrors = _validationErrorMapper.map(
      exception: error.failure,
      targetFields: const <String>{},
    );

    final String fallbackMessage = await _localizationService.tr(
      AppLocaleKeys.authGoogleSignInFailed,
    );
    final String? message =
        error.message ?? _firstMeaningfulGlobalError(mappedErrors);

    state = state.copyWith(generalError: message ?? fallbackMessage);
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
