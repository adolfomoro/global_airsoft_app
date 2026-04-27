import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/network/abp_error_response.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/auth_security_handled_exception.dart';
import 'package:global_airsoft_app/src/core/network/message_resolution_policy.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';

void main() {
  test(
    'keeps security interceptor message locked even with feature override',
    () {
      final AuthenticationException exception =
          AuthenticationException.fromApiException(
            AuthSecurityHandledException(
              message: 'Backend security change message.',
              statusCode: 401,
              code: 'GlobalAirsoft:Auth:AccessTokenInvalid',
              validationErrors: <AbpValidationError>[],
            ),
            messageOverride: 'Localized login failed message.',
          );

      expect(exception.failure, isA<AuthSecurityHandledException>());
      expect(exception.message, 'Backend security change message.');
    },
  );

  test('prefers backend message for regular API failures by default', () {
    final AuthenticationException exception =
        AuthenticationException.fromApiException(
          UnauthorizedApiException(
            message: 'Backend login failure.',
            statusCode: 401,
            validationErrors: <AbpValidationError>[],
          ),
          messageOverride: 'Localized login failed message.',
        );

    expect(exception.message, 'Backend login failure.');
  });

  test('uses feature override when failure message is only a fallback', () {
    final AuthenticationException exception =
        AuthenticationException.fromApiException(
          UnknownApiException(
            message: 'Connection error while calling API.',
            isFallbackMessage: true,
            validationErrors: <AbpValidationError>[],
          ),
          messageOverride: 'Localized login failed message.',
        );

    expect(exception.message, 'Localized login failed message.');
  });

  test('uses feature override for validation api exceptions', () {
    final AuthenticationException exception =
        AuthenticationException.fromApiException(
          ValidationApiException(
            message: 'Server validation summary that should stay hidden.',
            statusCode: 400,
            validationErrors: <AbpValidationError>[],
          ),
          messageOverride: 'Localized login failed message.',
        );

    expect(exception.message, 'Localized login failed message.');
  });

  test('never surfaces backend validation summary without override', () {
    final AuthenticationException exception =
        AuthenticationException.fromApiException(
          ValidationApiException(
            message: 'Server validation summary that should stay hidden.',
            statusCode: 400,
            validationErrors: <AbpValidationError>[],
          ),
        );

    expect(exception.message, isNull);
  });

  test('allows future features to explicitly prefer override messages', () {
    final AuthenticationException exception =
        AuthenticationException.fromApiException(
          ForbiddenApiException(
            message: 'Backend says access denied.',
            statusCode: 403,
            validationErrors: <AbpValidationError>[],
          ),
          messageOverride: 'Frontend-specific permission message.',
          messageOverrideBehavior: MessageOverrideBehavior.preferOverride,
        );

    expect(exception.message, 'Frontend-specific permission message.');
  });
}
