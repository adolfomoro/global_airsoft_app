import 'package:global_airsoft_app/src/core/media/profile_photo.dart';

final class HomeProfileViewData {
  const HomeProfileViewData({
    required this.displayName,
    required this.username,
    required this.profilePhoto,
  });

  final String displayName;
  final String username;
  final ProfilePhoto profilePhoto;
}
