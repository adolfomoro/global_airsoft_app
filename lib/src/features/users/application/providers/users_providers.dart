import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/storage/storage_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/users/application/services/user_profile_service.dart';
import 'package:global_airsoft_app/src/features/users/application/services/user_profile_storage_service.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_profile_repository/user_profile_repository.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_profile.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_profile_privacy_settings.dart';

final Provider<UserProfileRepository> userProfileRepositoryProvider =
    Provider<UserProfileRepository>((Ref ref) {
      final dioService = ref.watch(appDioServiceProvider);
      final localizationService = ref.watch(appLocalizationServiceProvider);
      return UserProfileRepository(
        dioService: dioService,
        localizationService: localizationService,
      );
    });

final Provider<UserProfileService> userProfileServiceProvider =
    Provider<UserProfileService>((Ref ref) {
      final repository = ref.watch(userProfileRepositoryProvider);
      return UserProfileService(
        repository: repository,
        logger: AppLogger.instance,
      );
    });

final Provider<UserProfileStorageService> userProfileStorageServiceProvider =
    Provider<UserProfileStorageService>((Ref ref) {
      final secureStorage = ref.watch(secureStorageServiceProvider);
      final authStorageService = ref.watch(authStorageServiceProvider);
      return UserProfileStorageService(
        secureStorage: secureStorage,
        authStorageService: authStorageService,
        logger: AppLogger.instance,
      );
    });

final AsyncNotifierProvider<CurrentUserProfileController, UserProfile>
currentUserProfileProvider =
    AsyncNotifierProvider<CurrentUserProfileController, UserProfile>(
      CurrentUserProfileController.new,
    );

final currentUserPrivacySettingsProvider =
    FutureProvider.autoDispose<UserProfilePrivacySettings>((Ref ref) {
      return ref.watch(userProfileServiceProvider).getCurrentUserPrivacySettings();
    });

final NotifierProvider<CurrentUserProfileRefreshRequestNotifier, bool>
currentUserProfileRefreshRequestProvider =
    NotifierProvider<CurrentUserProfileRefreshRequestNotifier, bool>(
      CurrentUserProfileRefreshRequestNotifier.new,
    );

class CurrentUserProfileController extends AsyncNotifier<UserProfile> {
  UserProfileService get _service => ref.read(userProfileServiceProvider);
  UserProfileStorageService get _storage =>
      ref.read(userProfileStorageServiceProvider);
  AppLogger get _logger => AppLogger.instance;

  @override
  Future<UserProfile> build() async {
    final UserProfile? cachedProfile = await _storage.getCurrentUserProfile();
    if (cachedProfile != null) {
      unawaited(_refreshSilently());
      return cachedProfile;
    }

    return _fetchAndPersistRemoteProfile();
  }

  Future<UserProfile> reload() async {
    final UserProfile? previousProfile = state.asData?.value;

    try {
      final UserProfile remoteProfile = await _fetchAndPersistRemoteProfile();
      if (ref.mounted) {
        state = AsyncData<UserProfile>(remoteProfile);
      }
      return remoteProfile;
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = previousProfile != null
            ? AsyncData<UserProfile>(previousProfile)
            : AsyncError<UserProfile>(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> clearCachedProfile() {
    return _storage.clearCurrentUserProfile();
  }

  Future<UserProfile> _fetchAndPersistRemoteProfile() async {
    final UserProfile remoteProfile = await _service.getCurrentUserProfile();
    await _storage.saveCurrentUserProfile(remoteProfile);
    return remoteProfile;
  }

  Future<void> _refreshSilently() async {
    try {
      final UserProfile remoteProfile = await _fetchAndPersistRemoteProfile();
      if (ref.mounted) {
        state = AsyncData<UserProfile>(remoteProfile);
      }
    } catch (error, stackTrace) {
      _logger.debug(
        'Silent current user profile refresh failed. Keeping cached profile.',
      );
      _logger.error(
        'Current user profile silent refresh failed.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

class CurrentUserProfileRefreshRequestNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void requestRefresh() {
    state = true;
  }

  void clear() {
    state = false;
  }
}
