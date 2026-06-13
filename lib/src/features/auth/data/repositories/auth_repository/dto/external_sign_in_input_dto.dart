class ExternalSignInInputDto {
  const ExternalSignInInputDto({required this.idToken});

  final String idToken;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'idToken': idToken};
  }
}
