/// Validadores de form reutilizáveis para evitar duplicação
abstract final class FormValidators {
  static const int minUsernameLength = 3;
  static const int minPasswordLength = 6;

  static const String usernameEmptyError = 'Informe seu usuario.';
  static const String usernameTooShortError =
      'Usuario deve ter no minimo $minUsernameLength caracteres.';

  static const String passwordEmptyError = 'Informe sua senha.';
  static const String passwordTooShortError =
      'Senha deve ter no minimo $minPasswordLength caracteres.';

  static const String emailInvalidError = 'Email invalido.';
  static const String emailEmptyError = 'Informe seu email.';

  /// Valida username
  static String? validateUsername(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return usernameEmptyError;
    }
    if (text.length < minUsernameLength) {
      return usernameTooShortError;
    }
    return null;
  }

  /// Valida password
  static String? validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return passwordEmptyError;
    }
    if (text.length < minPasswordLength) {
      return passwordTooShortError;
    }
    return null;
  }

  /// Valida email
  static String? validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return emailEmptyError;
    }
    // Simple email validation regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(text)) {
      return emailInvalidError;
    }
    return null;
  }
}
