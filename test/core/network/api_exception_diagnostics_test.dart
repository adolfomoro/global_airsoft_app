import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/api_exception_diagnostics.dart';

void main() {
  test('extracts correlation id from response headers', () {
    final Headers headers = Headers.fromMap(<String, List<String>>{
      'X-Correlation-Id': <String>['corr-789'],
    });

    expect(
      ApiException.extractCorrelationIdFromHeaders(headers),
      'corr-789',
    );
  });

  test('formats user message with correlation id for unexpected failures', () {
    expect(
      ApiExceptionDiagnostics.formatMessageForDisplay(
        'Unexpected backend error.',
        source: const UnknownApiException(
          message: 'Unexpected backend error.',
          correlationId: 'corr-456',
          isUnexpectedFailure: true,
        ),
      ),
      'Unexpected backend error.\n'
      '${ApiExceptionDiagnostics.correlationIdLabel}: corr-456',
    );
  });

  test('builds structured log attributes for unexpected failures', () {
    final Map<String, Object?> attributes =
        ApiExceptionDiagnostics.buildLogAttributes(
          const NotImplementedApiException(
            message: 'Feature not implemented.',
            statusCode: 501,
            code: 'Feature:NotReady',
            correlationId: 'corr-999',
            isUnexpectedFailure: true,
          ),
          requestOptions: RequestOptions(
            path: '/v1/example',
            method: 'POST',
          ),
        );

    expect(attributes['correlation_id'], 'corr-999');
    expect(attributes['http_status_code'], 501);
    expect(attributes['api_error_code'], 'Feature:NotReady');
    expect(attributes['http_method'], 'POST');
    expect(attributes['http_path'], '/v1/example');
    expect(attributes['api_is_unexpected_failure'], isTrue);
  });
}
