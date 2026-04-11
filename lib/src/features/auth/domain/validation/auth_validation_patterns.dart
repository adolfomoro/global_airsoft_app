final class AuthValidationPatterns {
  AuthValidationPatterns._();

  static final RegExp emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
}
