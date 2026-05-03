import 'package:global_airsoft_app/src/core/media/profile_photo.dart';

final class HomeProfileViewData {
  const HomeProfileViewData({
    required this.username,
    required this.fullName,
    required this.bio,
    required this.profilePhoto,
  });

  final String username;
  final String fullName;
  final String bio;
  final ProfilePhoto profilePhoto;
}
