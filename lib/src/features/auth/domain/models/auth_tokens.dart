class AuthTokens {
  const AuthTokens({required this.jwtToken, required this.refreshToken});

  final String jwtToken;
  final String refreshToken;

  Map<String, dynamic> toJson() => {
    'jwtToken': jwtToken,
    'refreshToken': refreshToken,
  };

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    jwtToken: (json['jwtToken'] as String?)?.trim() ?? '',
    refreshToken: (json['refreshToken'] as String?)?.trim() ?? '',
  );
}
