import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/features/device/data/constants/device_api_paths.dart';
import 'package:global_airsoft_app/src/features/device/data/exceptions/device_registration_exception.dart';
import 'package:global_airsoft_app/src/features/device/data/repositories/device_repository/dto/register_device_input_dto.dart';
import 'package:global_airsoft_app/src/features/device/data/repositories/device_repository/dto/register_device_output_dto.dart';

final class DeviceRepository {
  DeviceRepository({
    required Dio dio,
    required AppLocalizationService localizationService,
  }) : _dio = dio,
       _localizationService = localizationService;

  final Dio _dio;
  final AppLocalizationService _localizationService;

  Future<String> _registrationFailedMessage() {
    return _localizationService.tr(AppLocaleKeys.deviceRegistrationFailed);
  }

  Future<String> _emptyResponseMessage() {
    return _localizationService.tr(
      AppLocaleKeys.deviceRegistrationEmptyResponse,
    );
  }

  Future<String> _invalidPayloadMessage() {
    return _localizationService.tr(
      AppLocaleKeys.deviceRegistrationInvalidPayloadFormat,
    );
  }

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
        final String localizedMessage = await _emptyResponseMessage();
        throw DeviceRegistrationException(
          message: localizedMessage,
          statusCode: response.statusCode,
        );
      }

      return RegisterDeviceOutputDto.fromJson(responseData);
    } on DioException catch (exception) {
      final Object? error = exception.error;
      if (error is AbpApiException || error is ApiException) {
        rethrow;
      }

      final String localizedMessage = await _registrationFailedMessage();
      throw DeviceRegistrationException(
        message: localizedMessage,
        statusCode: exception.response?.statusCode,
        cause: exception,
      );
    } on FormatException catch (exception) {
      final String localizedMessage = await _invalidPayloadMessage();
      throw DeviceRegistrationException(
        message: localizedMessage,
        cause: exception,
      );
    }
  }
}
