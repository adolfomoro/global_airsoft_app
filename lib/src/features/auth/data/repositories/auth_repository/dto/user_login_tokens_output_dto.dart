final class UserLoginTokensOutputDto {
  const UserLoginTokensOutputDto({
    required this.jwtToken,
    required this.refreshToken,
  });

  final String jwtToken;
  final String refreshToken;

  factory UserLoginTokensOutputDto.fromJson(Map<String, dynamic> json) {
    return UserLoginTokensOutputDto(
      jwtToken: (json['jwtToken'] as String?)?.trim() ?? '',
      refreshToken: (json['refreshToken'] as String?)?.trim() ?? '',
    );
  }

  Map<String, String> toJson() {
    return <String, String>{'jwtToken': jwtToken, 'refreshToken': refreshToken};
  }
}
