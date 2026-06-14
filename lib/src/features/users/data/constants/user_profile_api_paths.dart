abstract final class UserProfileApiPaths {
  static const String currentUserProfile = '/users/me';
  static const String updateCurrentUserProfile = '/users/me/profile';
  static const String currentUserProfilePicture = '/users/me/profile-picture';
  static const String currentUserProfilePictureUploadUrl =
      '/users/me/profile-picture/upload-url';
  static String currentUserProfilePictureUploadComplete(
    String uploadSessionId,
  ) {
    return '/users/me/profile-picture/uploads/$uploadSessionId/complete';
  }

  static String currentUserProfilePictureUploadStatus(String uploadSessionId) {
    return '/users/me/profile-picture/uploads/$uploadSessionId/status';
  }

  static const String currentUserProfilePictureMedium =
      '/users/me/profile-picture/url/medium';
  static const String currentUserProfilePictureLarge =
      '/users/me/profile-picture/url/large';
  static const String currentUserPrivacySettings = '/users/me/privacy';
  static const String updateCurrentUserPrivacySettings = '/users/me/privacy';

  UserProfileApiPaths._();
}
