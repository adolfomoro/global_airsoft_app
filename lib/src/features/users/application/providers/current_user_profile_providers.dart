import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/storage/storage_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/files/application/providers/file_upload_providers.dart';
import 'package:global_airsoft_app/src/features/users/application/services/current_user_profile_offline_persistence_service.dart';
import 'package:global_airsoft_app/src/features/users/application/services/current_user_profile_reload_throttle.dart';
import 'package:global_airsoft_app/src/features/users/application/services/user_profile_offline_photo_storage_service.dart';
import 'package:global_airsoft_app/src/features/users/application/services/user_profile_service.dart';
import 'package:global_airsoft_app/src/features/users/application/services/user_profile_storage_service.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_profile_repository/user_profile_repository.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_profile.dart';

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
        directFileUploadService: ref.watch(directFileUploadServiceProvider),
        fileContentTypeResolver: ref.watch(fileContentTypeResolverProvider),
      );
    });

final Provider<UserProfileStorageService> userProfileStorageServiceProvider =
    Provider<UserProfileStorageService>((Ref ref) {
      final secureStorage = ref.watch(secureStorageServiceProvider);
      final authStorageService = ref.watch(authStorageServiceProvider);
      final offlinePhotoStorageService = ref.watch(
        userProfileOfflinePhotoStorageServiceProvider,
      );
      return UserProfileStorageService(
        secureStorage: secureStorage,
        authStorageService: authStorageService,
        offlinePhotoStorageService: offlinePhotoStorageService,
        logger: AppLogger.instance,
      );
    });

final Provider<UserProfileOfflinePhotoStorageService>
userProfileOfflinePhotoStorageServiceProvider =
    Provider<UserProfileOfflinePhotoStorageService>((Ref ref) {
      final fileStorage = ref.watch(appFileStorageServiceProvider);
      return UserProfileOfflinePhotoStorageService(
        fileStorage: fileStorage,
        downloadClient: ref.watch(externalDioClientProvider),
        logger: AppLogger.instance,
      );
    });

final Provider<CurrentUserProfileOfflinePersistenceService>
currentUserProfileOfflinePersistenceServiceProvider =
    Provider<CurrentUserProfileOfflinePersistenceService>((Ref ref) {
      final storageService = ref.watch(userProfileStorageServiceProvider);
      final offlinePhotoStorageService = ref.watch(
        userProfileOfflinePhotoStorageServiceProvider,
      );
      return CurrentUserProfileOfflinePersistenceService(
        storageService: storageService,
        offlinePhotoStorageService: offlinePhotoStorageService,
        logger: AppLogger.instance,
      );
    });

final AsyncNotifierProvider<CurrentUserProfileController, UserProfile>
currentUserProfileProvider =
    AsyncNotifierProvider<CurrentUserProfileController, UserProfile>(
      CurrentUserProfileController.new,
    );

final NotifierProvider<CurrentUserProfileRefreshRequestNotifier, bool>
currentUserProfileRefreshRequestProvider =
    NotifierProvider<CurrentUserProfileRefreshRequestNotifier, bool>(
      CurrentUserProfileRefreshRequestNotifier.new,
    );

class CurrentUserProfileController extends AsyncNotifier<UserProfile> {
  static const Duration _reloadThrottleInterval = Duration(seconds: 10);

  UserProfileService get _service => ref.read(userProfileServiceProvider);
  CurrentUserProfileOfflinePersistenceService get _offlinePersistence =>
      ref.read(currentUserProfileOfflinePersistenceServiceProvider);
  AppLogger get _logger => AppLogger.instance;
  final CurrentUserProfileReloadThrottle _reloadThrottle =
      CurrentUserProfileReloadThrottle(minInterval: _reloadThrottleInterval);
  Future<UserProfile>? _inFlightReload;

  bool get _isAuthenticated => ref.read(isAuthenticatedProvider);

  @override
  Future<UserProfile> build() async {
    final bool isAuthenticated = ref.watch(isAuthenticatedProvider);
    final UserProfile? cachedProfile = await _offlinePersistence
        .getCurrentUserProfile();

    if (!isAuthenticated) {
      _reloadThrottle.reset();
      return _signedOutSnapshot(cachedProfile ?? state.asData?.value);
    }

    if (cachedProfile != null) {
      unawaited(_refreshSilently());
      return cachedProfile;
    }

    return _fetchAndPersistRemoteProfile();
  }

  Future<UserProfile> reload({bool bypassThrottle = false}) async {
    final UserProfile? previousProfile = state.asData?.value;

    if (!_isAuthenticated) {
      final UserProfile? cachedProfile = await _offlinePersistence
          .getCurrentUserProfile();
      return _signedOutSnapshot(cachedProfile ?? previousProfile);
    }

    if (!bypassThrottle &&
        previousProfile != null &&
        _reloadThrottle.shouldThrottleReload()) {
      return previousProfile;
    }

    final Future<UserProfile>? inFlightReload = _inFlightReload;
    if (inFlightReload != null) {
      return inFlightReload;
    }

    final Future<UserProfile> reloadFuture =
        _performReload(previousProfile: previousProfile);
    _inFlightReload = reloadFuture;

    try {
      return await reloadFuture;
    } finally {
      if (identical(_inFlightReload, reloadFuture)) {
        _inFlightReload = null;
      }
    }
  }

  Future<UserProfile> _performReload({
    required UserProfile? previousProfile,
  }) async {
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

  Future<bool> reloadIfRefreshRequested() async {
    if (!ref.read(currentUserProfileRefreshRequestProvider)) {
      return false;
    }

    if (!_isAuthenticated) {
      ref.read(currentUserProfileRefreshRequestProvider.notifier).clear();
      return false;
    }

    try {
      await reload(bypassThrottle: true);
      return true;
    } finally {
      ref.read(currentUserProfileRefreshRequestProvider.notifier).clear();
    }
  }

  Future<void> clearCachedProfile() async {
    _reloadThrottle.reset();
    _inFlightReload = null;
    await _offlinePersistence.clearCurrentUserProfile();
    if (ref.mounted) {
      state = AsyncData<UserProfile>(_signedOutSnapshot(state.asData?.value));
    }
  }

  Future<UserProfile> _fetchAndPersistRemoteProfile() async {
    if (!_isAuthenticated) {
      final UserProfile? cachedProfile = await _offlinePersistence
          .getCurrentUserProfile();
      return _signedOutSnapshot(cachedProfile ?? state.asData?.value);
    }

    final UserProfile remoteProfile = await _service.getCurrentUserProfile();

    if (!_isAuthenticated) {
      return _signedOutSnapshot(state.asData?.value);
    }

    final UserProfile persistedProfile = await _offlinePersistence
        .persistRemoteProfile(remoteProfile);
    _reloadThrottle.markSuccessfulReload();
    return persistedProfile;
  }

  Future<void> _refreshSilently() async {
    if (!_isAuthenticated) {
      return;
    }

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

  UserProfile _signedOutSnapshot(UserProfile? source) {
    if (source != null) {
      return source.copyWith(
        mediumProfilePictureUrl: '',
        largeProfilePictureUrl: '',
        localProfilePicturePath: '',
      );
    }

    return const UserProfile(
      id: '',
      username: '',
      fullName: '',
      bio: '',
      mediumProfilePictureUrl: '',
      largeProfilePictureUrl: '',
    );
  }
}

class CurrentUserProfileRefreshRequestNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void requestRefresh() {
    if (state) {
      return;
    }

    state = true;
  }

  void clear() {
    if (!state) {
      return;
    }

    state = false;
  }
}
