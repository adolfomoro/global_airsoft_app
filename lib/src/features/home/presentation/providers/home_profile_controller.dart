import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/features/users/application/providers/users_providers.dart';
import 'package:global_airsoft_app/src/features/users/application/services/user_profile_service.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_profile.dart';

final Provider<HomeProfileController> homeProfileControllerProvider =
    Provider<HomeProfileController>((Ref ref) {
      return HomeProfileController(ref);
    });

final class HomeProfileController {
  const HomeProfileController(this._ref);

  final Ref _ref;

  UserProfileService get _userProfileService => _ref.read(
    userProfileServiceProvider,
  );

  CurrentUserProfileController get _currentUserProfileController => _ref.read(
    currentUserProfileProvider.notifier,
  );

  Future<UserProfile> refreshProfile({bool bypassThrottle = false}) {
    return _currentUserProfileController.reload(
      bypassThrottle: bypassThrottle,
    );
  }

  Future<bool> reloadIfRefreshRequested() {
    return _currentUserProfileController.reloadIfRefreshRequested();
  }

  Future<void> uploadCurrentUserProfilePhoto(File file) async {
    await _userProfileService.uploadCurrentUserProfilePicture(file);
    await refreshProfile(bypassThrottle: true);
  }

  Future<void> deleteCurrentUserProfilePhoto() async {
    await _userProfileService.deleteCurrentUserProfilePicture();
    await refreshProfile(bypassThrottle: true);
  }
}