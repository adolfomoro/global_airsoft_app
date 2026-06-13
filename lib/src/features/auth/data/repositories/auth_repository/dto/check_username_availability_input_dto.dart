final class CheckUsernameAvailabilityInputDto {
  const CheckUsernameAvailabilityInputDto({required this.userName});

  static const String userNameField = 'UserName';

  final String userName;

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{userNameField: userName};
  }
}
