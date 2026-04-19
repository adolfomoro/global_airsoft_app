import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';
import 'package:global_airsoft_app/src/core/network/http_status_code_extensions.dart';
import 'package:global_airsoft_app/src/features/auth/data/constants/auth_api_paths.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/create_user_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/create_user_output_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/google_sign_in_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/google_sign_in_response_output_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/request_password_recovery_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/user_login_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/user_login_output_dto.dart';

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

  Future<String> _passwordRecoveryFailedMessage() {
    return _localizationService.tr(AppLocaleKeys.authPasswordRecoveryFailed);
  }

  Future<String> _googleSignInFailedMessage() {
    return _localizationService.tr(AppLocaleKeys.authGoogleSignInFailed);
  }

  Future<T> _parseSuccessfulResponse<T>({
    required Response<dynamic> response,
    required T Function(Map<String, dynamic> json) fromJson,
    required Future<String> Function() failureMessageProvider,
  }) async {
    if (response.statusCode.isSuccessStatusCode &&
        response.data is Map<String, dynamic>) {
      return fromJson(response.data as Map<String, dynamic>);
    }

    final String localizedFailureMessage = await failureMessageProvider();
    throw AuthenticationException(
      failure: UnknownApiException(message: localizedFailureMessage),
      messageOverride: localizedFailureMessage,
    );
  }

  Future<Never> _throwLocalizedAuthenticationException({
    required Future<String> Function() failureMessageProvider,
    required ApiException error,
  }) async {
    final String localizedFailureMessage = await failureMessageProvider();

    if (error is AbpApiException) {
      throw AuthenticationException.fromAbpException(
        error,
        messageOverride: localizedFailureMessage,
      );
    }

    throw AuthenticationException.fromApiException(
      error,
      messageOverride: localizedFailureMessage,
    );
  }

  Future<Never> _throwLocalizedFailure({
    required Future<String> Function() failureMessageProvider,
  }) async {
    final String localizedFailureMessage = await failureMessageProvider();

    throw AuthenticationException(
      failure: UnknownApiException(message: localizedFailureMessage),
      messageOverride: localizedFailureMessage,
    );
  }

  Future<UserLoginOutputDto> login(UserLoginInputDto input) async {
    try {
      final Response<dynamic> response = await _dioService.post<dynamic>(
        AuthApiPaths.signIn,
        data: input.toJson(),
      );

      return _parseSuccessfulResponse(
        response: response,
        fromJson: UserLoginOutputDto.fromJson,
        failureMessageProvider: _loginFailedMessage,
      );
    } on AbpApiException catch (error) {
      await _throwLocalizedAuthenticationException(
        failureMessageProvider: _loginFailedMessage,
        error: error,
      );
    } on ApiException catch (error) {
      await _throwLocalizedAuthenticationException(
        failureMessageProvider: _loginFailedMessage,
        error: error,
      );
    } on DioException {
      await _throwLocalizedFailure(failureMessageProvider: _loginFailedMessage);
    }
  }

  Future<CreateUserOutputDto> signUp(CreateUserInputDto input) async {
    try {
      final Response<dynamic> response = await _dioService.post<dynamic>(
        AuthApiPaths.signUp,
        data: input.toJson(),
      );

      return _parseSuccessfulResponse(
        response: response,
        fromJson: CreateUserOutputDto.fromJson,
        failureMessageProvider: _signUpFailedMessage,
      );
    } on AbpApiException catch (error) {
      await _throwLocalizedAuthenticationException(
        failureMessageProvider: _signUpFailedMessage,
        error: error,
      );
    } on ApiException catch (error) {
      await _throwLocalizedAuthenticationException(
        failureMessageProvider: _signUpFailedMessage,
        error: error,
      );
    } on DioException {
      await _throwLocalizedFailure(
        failureMessageProvider: _signUpFailedMessage,
      );
    }
  }

  Future<GoogleSignInResponseOutputDto> signInWithGoogle(
    GoogleSignInInputDto input,
  ) async {
    try {
      final Response<dynamic> response = await _dioService.post<dynamic>(
        AuthApiPaths.signInGoogle,
        data: input.toJson(),
      );

      return _parseSuccessfulResponse(
        response: response,
        fromJson: GoogleSignInResponseOutputDto.fromJson,
        failureMessageProvider: _googleSignInFailedMessage,
      );
    } on AbpApiException catch (error) {
      await _throwLocalizedAuthenticationException(
        failureMessageProvider: _googleSignInFailedMessage,
        error: error,
      );
    } on ApiException catch (error) {
      await _throwLocalizedAuthenticationException(
        failureMessageProvider: _googleSignInFailedMessage,
        error: error,
      );
    } on DioException {
      await _throwLocalizedFailure(
        failureMessageProvider: _googleSignInFailedMessage,
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

      await _throwLocalizedFailure(
        failureMessageProvider: _passwordRecoveryFailedMessage,
      );
    } on AbpApiException catch (error) {
      await _throwLocalizedAuthenticationException(
        failureMessageProvider: _passwordRecoveryFailedMessage,
        error: error,
      );
    } on ApiException catch (error) {
      await _throwLocalizedAuthenticationException(
        failureMessageProvider: _passwordRecoveryFailedMessage,
        error: error,
      );
    } on DioException {
      await _throwLocalizedFailure(
        failureMessageProvider: _passwordRecoveryFailedMessage,
      );
    }
  }
}
