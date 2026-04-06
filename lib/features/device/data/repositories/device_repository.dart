import 'package:dio/dio.dart';

import '../constants/device_api_paths.dart';
import '../../domain/models/register_device_input_dto.dart';
import '../../domain/models/register_device_output_dto.dart';

class DeviceRepository {
  DeviceRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<RegisterDeviceOutputDto> registerDevice(
    RegisterDeviceInputDto input,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        DeviceApiPaths.registerDevice,
        data: input.toJson(),
      );

      if (response.data == null) {
        throw Exception('Resposta vazia do servidor ao registrar dispositivo');
      }

      return RegisterDeviceOutputDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception('Erro ao registrar dispositivo: ${e.message}');
    }
  }
}
