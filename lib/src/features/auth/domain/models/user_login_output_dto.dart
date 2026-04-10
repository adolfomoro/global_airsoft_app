final class UserLoginOutputDto {
  const UserLoginOutputDto({
    required this.jwtToken,
    required this.refreshToken,
  });

  final String jwtToken;
  final String refreshToken;

  factory UserLoginOutputDto.fromJson(Map<String, dynamic> json) {
    return UserLoginOutputDto(
      jwtToken: (json['jwtToken'] as String?) ?? '',
      refreshToken: (json['refreshToken'] as String?) ?? '',
    );
  }

  Map<String, String> toJson() {
    return <String, String>{'jwtToken': jwtToken, 'refreshToken': refreshToken};
  }
}
