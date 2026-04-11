final class RequestPasswordRecoveryInputDto {
  const RequestPasswordRecoveryInputDto({required this.email});

  static const String emailField = 'email';

  final String email;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{emailField: email};
  }
}
