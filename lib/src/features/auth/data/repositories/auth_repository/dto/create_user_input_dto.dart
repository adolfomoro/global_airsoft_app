final class CreateUserInputDto {
  const CreateUserInputDto({
    required this.fullName,
    required this.username,
    required this.email,
    required this.password,
  });

  static const String fullNameField = 'fullName';
  static const String usernameField = 'username';
  static const String emailField = 'email';
  static const String passwordField = 'password';

  final String fullName;
  final String username;
  final String email;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      fullNameField: fullName,
      usernameField: username,
      emailField: email,
      passwordField: password,
    };
  }
}
