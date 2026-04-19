final class GoogleAccountSetupArguments {
  const GoogleAccountSetupArguments({
    required this.challengeToken,
    required this.profilePictureUrl,
    required this.profileName,
  });

  final String challengeToken;
  final String profilePictureUrl;
  final String profileName;
}
