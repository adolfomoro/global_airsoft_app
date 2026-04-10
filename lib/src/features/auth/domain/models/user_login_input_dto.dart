final class UserLoginInputDto {
  const UserLoginInputDto({required this.login, required this.password});

  static const String loginField = 'login';
  static const String passwordField = 'password';

  final String login;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{loginField: login, passwordField: password};
  }
}
