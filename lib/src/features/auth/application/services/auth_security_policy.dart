import 'package:global_airsoft_app/src/features/auth/domain/constants/auth_security_error_codes.dart';

enum AuthSecurityAction {
  passThrough,
  refreshAndRetry,
  logoutSecurityChange,
  logoutSessionEnded,
  showPermissionDenied,
  showTooManyAttempts,
  showServerUnavailable,
}

final class AuthSecurityPolicy {
  const AuthSecurityPolicy();

  AuthSecurityAction resolve({
    required int? statusCode,
    required String? code,
    required bool isRefreshRequest,
  }) {
    if (isRefreshRequest) {
      return AuthSecurityAction.logoutSessionEnded;
    }

    if (_isAccessTokenExpired(statusCode: statusCode, code: code)) {
      return AuthSecurityAction.refreshAndRetry;
    }

    if (_isSecurityInvalid(statusCode: statusCode, code: code)) {
      return _isSessionEndedCode(code)
          ? AuthSecurityAction.logoutSessionEnded
          : AuthSecurityAction.logoutSecurityChange;
    }

    if (_isAccessForbidden(statusCode: statusCode, code: code)) {
      return AuthSecurityAction.showPermissionDenied;
    }

    if (statusCode == 429) {
      return AuthSecurityAction.showTooManyAttempts;
    }

    if (statusCode != null && statusCode >= 500) {
      return AuthSecurityAction.showServerUnavailable;
    }

    if (statusCode == 401) {
      return AuthSecurityAction.logoutSecurityChange;
    }

    return AuthSecurityAction.passThrough;
  }

  bool _isAccessTokenExpired({
    required int? statusCode,
    required String? code,
  }) {
    return statusCode == 401 &&
        code == AuthSecurityErrorCodes.accessTokenExpired;
  }

  bool _isSecurityInvalid({required int? statusCode, required String? code}) {
    if (statusCode != 401) {
      return false;
    }

    if (code == AuthSecurityErrorCodes.accessTokenInvalid ||
        code == AuthSecurityErrorCodes.sessionInvalid ||
        code == AuthSecurityErrorCodes.authRequired ||
        code == AuthSecurityErrorCodes.sessionEnded ||
        code == AuthSecurityErrorCodes.refreshTokenInvalid ||
        code == AuthSecurityErrorCodes.refreshTokenExpired ||
        code == AuthSecurityErrorCodes.sessionExpired) {
      return true;
    }

    return code == null;
  }

  bool _isAccessForbidden({required int? statusCode, required String? code}) {
    return statusCode == 403 && code == AuthSecurityErrorCodes.accessForbidden;
  }

  bool _isSessionEndedCode(String? code) {
    return code == AuthSecurityErrorCodes.sessionEnded ||
        code == AuthSecurityErrorCodes.refreshTokenInvalid ||
        code == AuthSecurityErrorCodes.refreshTokenExpired ||
        code == AuthSecurityErrorCodes.sessionExpired;
  }
}
