import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';
import 'package:global_airsoft_app/src/core/network/http_status_code_extensions.dart';
import 'package:global_airsoft_app/src/features/auth/data/constants/auth_api_paths.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/create_user_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/create_user_output_dto.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/password_validation_rules_output_dto.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/request_password_recovery_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/user_login_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/user_login_output_dto.dart';

final class AuthRepository {
  const AuthRepository({
    required AppDioService dioService,
    required AppLocalizationService localizationService,
  }) : _dioService = dioService,
       _localizationService = localizationService;

  final AppDioService _dioService;
  final AppLocalizationService _localizationService;

  Future<String> _loginFailedMessage() {
    return _localizationService.tr(AppLocaleKeys.authLoginFailed);
  }

  Future<String> _signUpFailedMessage() {
    return _localizationService.tr(AppLocaleKeys.authSignUpFailed);
  }

  Future<String> _passwordRulesFailedMessage() {
    return _localizationService.tr(AppLocaleKeys.authPasswordRulesFailed);
  }

  Future<String> _passwordRecoveryFailedMessage() {
    return _localizationService.tr(AppLocaleKeys.authPasswordRecoveryFailed);
  }

  Future<UserLoginOutputDto> login(UserLoginInputDto input) async {
    try {
      final Response<dynamic> response = await _dioService.post<dynamic>(
        AuthApiPaths.signIn,
        data: input.toJson(),
      );

      if (response.statusCode.isSuccessStatusCode && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          return UserLoginOutputDto.fromJson(
            response.data as Map<String, dynamic>,
          );
        }
      }

      final String localizedFailureMessage = await _loginFailedMessage();
      throw AuthenticationException(
        failure: UnknownApiException(message: localizedFailureMessage),
        messageOverride: localizedFailureMessage,
      );
    } on AbpApiException catch (error) {
      final String localizedFailureMessage = await _loginFailedMessage();
      throw AuthenticationException.fromAbpException(
        error,
        messageOverride: localizedFailureMessage,
      );
    } on ApiException catch (error) {
      final String localizedFailureMessage = await _loginFailedMessage();
      throw AuthenticationException.fromApiException(
        error,
        messageOverride: localizedFailureMessage,
      );
    }
  }

  Future<CreateUserOutputDto> signUp(CreateUserInputDto input) async {
    try {
      final Response<dynamic> response = await _dioService.post<dynamic>(
        AuthApiPaths.signUp,
        data: input.toJson(),
      );

      if (response.statusCode.isSuccessStatusCode &&
          response.data is Map<String, dynamic>) {
        return CreateUserOutputDto.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      final String localizedFailureMessage = await _signUpFailedMessage();
      throw AuthenticationException(
        failure: UnknownApiException(message: localizedFailureMessage),
        messageOverride: localizedFailureMessage,
      );
    } on AbpApiException catch (error) {
      final String localizedFailureMessage = await _signUpFailedMessage();
      throw AuthenticationException.fromAbpException(
        error,
        messageOverride: localizedFailureMessage,
      );
    } on ApiException catch (error) {
      final String localizedFailureMessage = await _signUpFailedMessage();
      throw AuthenticationException.fromApiException(
        error,
        messageOverride: localizedFailureMessage,
      );
    }
  }

  Future<PasswordValidationRulesOutputDto> getPasswordValidationRules() async {
    try {
      final Response<dynamic> response = await _dioService.get<dynamic>(
        AuthApiPaths.passwordRules,
      );

      if (response.statusCode.isSuccessStatusCode &&
          response.data is Map<String, dynamic>) {
        return PasswordValidationRulesOutputDto.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      final String localizedFailureMessage =
          await _passwordRulesFailedMessage();
      throw AuthenticationException(
        failure: UnknownApiException(message: localizedFailureMessage),
        messageOverride: localizedFailureMessage,
      );
    } on AbpApiException catch (error) {
      final String localizedFailureMessage =
          await _passwordRulesFailedMessage();
      throw AuthenticationException.fromAbpException(
        error,
        messageOverride: localizedFailureMessage,
      );
    } on ApiException catch (error) {
      final String localizedFailureMessage =
          await _passwordRulesFailedMessage();
      throw AuthenticationException.fromApiException(
        error,
        messageOverride: localizedFailureMessage,
      );
    }
  }

  Future<void> requestPasswordRecovery(
    RequestPasswordRecoveryInputDto input,
  ) async {
    try {
      final Response<dynamic> response = await _dioService.post<dynamic>(
        AuthApiPaths.passwordRecovery,
        data: input.toJson(),
      );

      if (response.statusCode.isSuccessStatusCode) {
        return;
      }

      final String localizedFailureMessage =
          await _passwordRecoveryFailedMessage();
      throw AuthenticationException(
        failure: UnknownApiException(message: localizedFailureMessage),
        messageOverride: localizedFailureMessage,
      );
    } on AbpApiException catch (error) {
      final String localizedFailureMessage =
          await _passwordRecoveryFailedMessage();
      throw AuthenticationException.fromAbpException(
        error,
        messageOverride: localizedFailureMessage,
      );
    } on ApiException catch (error) {
      final String localizedFailureMessage =
          await _passwordRecoveryFailedMessage();
      throw AuthenticationException.fromApiException(
        error,
        messageOverride: localizedFailureMessage,
      );
    }
  }
}
