import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/constants/auth_api_paths.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/user_login_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/user_login_output_dto.dart';

final class AuthRepository {
  const AuthRepository({required AppDioService dioService})
    : _dioService = dioService;

  final AppDioService _dioService;

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

      throw AuthenticationException(
        failure: const UnknownApiException(
          message: 'Invalid login response format',
        ),
      );
    } on AbpApiException catch (error) {
      throw AuthenticationException.fromAbpException(error);
    } on ApiException catch (error) {
      throw AuthenticationException.fromApiException(error);
    }
  }
}
