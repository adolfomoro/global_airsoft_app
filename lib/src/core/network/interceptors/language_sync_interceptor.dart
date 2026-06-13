import 'package:dio/dio.dart';

final class LanguageSyncInterceptor extends Interceptor {
  static const String _acceptLanguageHeader = 'Accept-Language';
  static const String _contentLanguageHeader = 'content-language';
  static const String _contentLanguageHeaderCompact = 'contentlanguage';

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
      options.headers[_acceptLanguageHeader] = language;
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    await _syncContentLanguage(response.headers);
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    await _syncContentLanguage(err.response?.headers);
    handler.next(err);
  }

  Future<void> _syncContentLanguage(Headers? headers) {
    return _onContentLanguage(_resolveContentLanguage(headers));
  }

  String? _resolveContentLanguage(Headers? headers) {
    if (headers == null) {
      return null;
    }

    return headers.value(_contentLanguageHeaderCompact) ??
        headers.value(_contentLanguageHeader);
  }
}
