import 'dart:io';

class ExternalSignUpConfirmInputDto {
  const ExternalSignUpConfirmInputDto({
    required this.challengeToken,
    required this.username,
    this.profilePictureFile,
  });

  static const String challengeTokenField = 'challengeToken';
  static const String usernameField = 'username';
  static const String profilePictureFileField = 'profilePictureFile';

  final String challengeToken;
  final String username;
  final File? profilePictureFile;

  bool get hasProfilePicture => profilePictureFile != null;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      challengeTokenField: challengeToken,
      usernameField: username,
    };
  }
}
