abstract final class UserProfileApiPaths {
  static const String currentUserProfile = '/users/me';
  static const String currentUserProfilePicture = '/users/me/profile-picture';
  static const String currentUserProfilePictureMedium =
      '/users/me/profile-picture/url/medium';
  static const String currentUserProfilePictureLarge =
      '/users/me/profile-picture/url/large';
  static const String currentUserPrivacySettings = '/users/me/privacy';
  static const String updateCurrentUserPrivacySettings = '/users/me/privacy';

  UserProfileApiPaths._();
}
