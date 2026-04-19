class ExternalSignInSuggestionOutputDto {
  const ExternalSignInSuggestionOutputDto({
    required this.profilePictureUrl,
    required this.username,
  });

  final String profilePictureUrl;
  final String username;

  factory ExternalSignInSuggestionOutputDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return ExternalSignInSuggestionOutputDto(
      profilePictureUrl: (json['profilePictureUrl'] as String?) ?? '',
      username: (json['username'] as String?) ?? '',
    );
  }
}
