final class GoogleSignInException implements Exception {
  const GoogleSignInException([this.message]);

  final String? message;

  @override
  String toString() {
    final String? currentMessage = message;
    if (currentMessage == null || currentMessage.isEmpty) {
      return 'GoogleSignInException';
    }

    return 'GoogleSignInException: $currentMessage';
  }
}
