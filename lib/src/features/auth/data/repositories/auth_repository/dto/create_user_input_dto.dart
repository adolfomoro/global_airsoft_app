final class CreateUserInputDto {
  const CreateUserInputDto({
    required this.username,
    required this.fullName,
    required this.email,
    required this.password,
  });

  static const String usernameField = 'username';
  static const String fullNameField = 'fullName';
  static const String emailField = 'email';
  static const String passwordField = 'password';

  final String username;
  final String fullName;
  final String email;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      usernameField: username,
      fullNameField: fullName,
      emailField: email,
      passwordField: password,
    };
  }
}
