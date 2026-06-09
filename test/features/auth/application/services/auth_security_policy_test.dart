import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_security_policy.dart';
import 'package:global_airsoft_app/src/features/auth/domain/constants/auth_security_error_codes.dart';

void main() {
  const AuthSecurityPolicy policy = AuthSecurityPolicy();

  test('requires unauthorized status to refresh expired access token', () {
    expect(
      policy.resolve(
        statusCode: 401,
        code: AuthSecurityErrorCodes.accessTokenExpired,
        isRefreshRequest: false,
      ),
      AuthSecurityAction.refreshAndRetry,
    );

    expect(
      policy.resolve(
        statusCode: 500,
        code: AuthSecurityErrorCodes.accessTokenExpired,
        isRefreshRequest: false,
      ),
      AuthSecurityAction.showServerUnavailable,
    );
  });

  test('logs out immediately for unauthorized security failures', () {
    expect(
      policy.resolve(
        statusCode: 401,
        code: AuthSecurityErrorCodes.accessTokenInvalid,
        isRefreshRequest: false,
      ),
      AuthSecurityAction.logoutSecurityChange,
    );

    expect(
      policy.resolve(
        statusCode: 401,
        code: AuthSecurityErrorCodes.sessionExpired,
        isRefreshRequest: false,
      ),
      AuthSecurityAction.logoutSessionEnded,
    );
  });

  test('requires documented forbidden code for permission message', () {
    expect(
      policy.resolve(
        statusCode: 403,
        code: AuthSecurityErrorCodes.accessForbidden,
        isRefreshRequest: false,
      ),
      AuthSecurityAction.showPermissionDenied,
    );

    expect(
      policy.resolve(
        statusCode: 403,
        code: 'GlobalAirsoft:GenericForbidden',
        isRefreshRequest: false,
      ),
      AuthSecurityAction.passThrough,
    );
  });

  test('maps refresh request failures to session ended logout', () {
    expect(
      policy.resolve(
        statusCode: 500,
        code: 'GlobalAirsoft:AnyError',
        isRefreshRequest: true,
      ),
      AuthSecurityAction.logoutSessionEnded,
    );
  });

  test('maps rate limit and server failures to user-facing messages', () {
    expect(
      policy.resolve(statusCode: 429, code: null, isRefreshRequest: false),
      AuthSecurityAction.showTooManyAttempts,
    );

    expect(
      policy.resolve(statusCode: 503, code: null, isRefreshRequest: false),
      AuthSecurityAction.showServerUnavailable,
    );
  });
}
