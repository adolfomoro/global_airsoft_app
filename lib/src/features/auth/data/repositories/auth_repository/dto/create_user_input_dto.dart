final class CreateUserInputDto {
  const CreateUserInputDto({
    required this.userName,
    required this.email,
    required this.password,
  });

  static const String userNameField = 'userName';
  static const String emailField = 'email';
  static const String passwordField = 'password';

  final String userName;
  final String email;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      userNameField: userName,
      emailField: email,
      passwordField: password,
    };
  }
}
