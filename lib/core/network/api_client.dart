import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<String> fetchHealthExample() async {
    final response = await _dio.get<Map<String, dynamic>>('/health');

    final data = response.data;
    if (data == null) {
      return 'Resposta vazia do servidor.';
    }

    final title = data['title'];
    if (title is String && title.isNotEmpty) {
      return title;
    }

    return data.toString();
  }
}
