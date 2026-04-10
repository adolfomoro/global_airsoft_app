final class UserLoginInputDto {
  const UserLoginInputDto({required this.login, required this.password});

  final String login;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'login': login, 'password': password};
  }
}
