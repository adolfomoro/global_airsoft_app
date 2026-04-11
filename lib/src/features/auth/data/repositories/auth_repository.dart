import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/constants/auth_api_paths.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
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

  Future<UserLoginOutputDto> login(UserLoginInputDto input) async {
    try {
      final Response<dynamic> response = await _dioService.post<dynamic>(
        AuthApiPaths.signIn,
        data: input.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          return UserLoginOutputDto.fromJson(
            response.data as Map<String, dynamic>,
          );
        }
      }

      final String localizedFailureMessage = await _localizationService.tr(
        AppLocaleKeys.authLoginFailed,
      );
      throw AuthenticationException(
        failure: UnknownApiException(message: localizedFailureMessage),
        messageOverride: localizedFailureMessage,
      );
    } on AbpApiException catch (error) {
      final String localizedFailureMessage = await _localizationService.tr(
        AppLocaleKeys.authLoginFailed,
      );
      throw AuthenticationException.fromAbpException(
        error,
        messageOverride: localizedFailureMessage,
      );
    } on ApiException catch (error) {
      final String localizedFailureMessage = await _localizationService.tr(
        AppLocaleKeys.authLoginFailed,
      );
      throw AuthenticationException.fromApiException(
        error,
        messageOverride: localizedFailureMessage,
      );
    }
  }
}
