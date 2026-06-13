import 'package:dio/dio.dart';

import 'package:global_airsoft_app/src/core/network/multipart_upload_util.dart';

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
  final MultipartFile? profilePictureFile;

  FormData toJson() {
    return MultipartUploadUtil.createFormData(<String, dynamic>{
      challengeTokenField: challengeToken,
      usernameField: username,
      if (profilePictureFile != null)
        profilePictureFileField: profilePictureFile,
    });
  }
}
