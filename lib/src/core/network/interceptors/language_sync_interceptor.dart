import 'package:dio/dio.dart';

final class LanguageSyncInterceptor extends Interceptor {
  LanguageSyncInterceptor({
    required String Function() getDeviceLanguage,
    required Future<void> Function(String? contentLanguage) onContentLanguage,
  }) : _getDeviceLanguage = getDeviceLanguage,
       _onContentLanguage = onContentLanguage;

  final String Function() _getDeviceLanguage;
  final Future<void> Function(String? contentLanguage) _onContentLanguage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String language = _getDeviceLanguage().trim();
    if (language.isNotEmpty) {
      options.headers['Accept-Language'] = language;
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    await _onContentLanguage(_resolveContentLanguage(response.headers));
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final Headers? headers = err.response?.headers;
    await _onContentLanguage(_resolveContentLanguage(headers));
    handler.next(err);
  }

  String? _resolveContentLanguage(Headers? headers) {
    if (headers == null) {
      return null;
    }

    final String? contentLanguage =
        headers.value('contentlanguage') ?? headers.value('content-language');
    return contentLanguage;
  }
}
