import 'package:global_airsoft_app/src/features/auth/data/exceptions/google_sign_in_exception.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in;

final class GoogleSignInService {
  GoogleSignInService({required String serverClientId})
    : _googleSignIn = google_sign_in.GoogleSignIn.instance {
    _initializationFuture ??= _initialize(serverClientId.trim());
  }

  static Future<void>? _initializationFuture;

  final google_sign_in.GoogleSignIn _googleSignIn;

  static Future<void> _initialize(String serverClientId) async {
    if (serverClientId.isEmpty) {
      return;
    }

    await google_sign_in.GoogleSignIn.instance.initialize(
      serverClientId: serverClientId,
    );
  }

  Future<String?> requestIdToken() async {
    final Future<void> initializationFuture =
        _initializationFuture ?? Future<void>.value();
    await initializationFuture;

    try {
      final google_sign_in.GoogleSignInAccount account = await _googleSignIn
          .authenticate();
      final google_sign_in.GoogleSignInAuthentication authentication =
          account.authentication;
      final String? idToken = authentication.idToken;
      if (idToken == null || idToken.trim().isEmpty) {
        throw const GoogleSignInException(
          'Google sign-in did not provide an ID token.',
        );
      }

      return idToken.trim();
    } on google_sign_in.GoogleSignInException catch (error) {
      if (error.code == google_sign_in.GoogleSignInExceptionCode.canceled) {
        return null;
      }

      throw GoogleSignInException(
        error.description?.trim().isNotEmpty == true
            ? error.description!.trim()
            : 'Google sign-in failed.',
      );
    }
  }
}
