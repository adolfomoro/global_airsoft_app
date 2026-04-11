import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/features/device/data/constants/device_api_paths.dart';
import 'package:global_airsoft_app/src/features/device/data/exceptions/device_registration_exception.dart';
import 'package:global_airsoft_app/src/features/device/data/repositories/device_repository/dto/register_device_input_dto.dart';
import 'package:global_airsoft_app/src/features/device/data/repositories/device_repository/dto/register_device_output_dto.dart';

final class DeviceRepository {
  DeviceRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<RegisterDeviceOutputDto> registerDevice(
    RegisterDeviceInputDto input,
  ) async {
    try {
      final Response<Map<String, dynamic>> response = await _dio
          .put<Map<String, dynamic>>(
            DeviceApiPaths.registerDevice,
            data: input.toJson(),
          );

      final Map<String, dynamic>? responseData = response.data;
      if (responseData == null) {
        throw DeviceRegistrationException(
          message: 'Empty response while registering device.',
          statusCode: response.statusCode,
        );
      }

      return RegisterDeviceOutputDto.fromJson(responseData);
    } on DioException catch (exception) {
      final Object? error = exception.error;
      if (error is AbpApiException || error is ApiException) {
        rethrow;
      }

      throw DeviceRegistrationException(
        message: 'Failed to register device: ${exception.message}',
        statusCode: exception.response?.statusCode,
        cause: exception,
      );
    } on FormatException catch (exception) {
      throw DeviceRegistrationException(
        message: 'Invalid device registration payload format.',
        cause: exception,
      );
    }
  }
}
