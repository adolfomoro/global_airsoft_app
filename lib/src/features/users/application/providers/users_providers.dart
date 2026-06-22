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
import 'package:global_airsoft_app/src/features/users/application/services/user_account_service.dart';
import 'package:global_airsoft_app/src/features/users/application/services/user_profile_offline_photo_storage_service.dart';
import 'package:global_airsoft_app/src/features/users/application/services/user_profile_service.dart';
import 'package:global_airsoft_app/src/features/users/application/services/user_profile_storage_service.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_account_repository/user_account_repository.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_profile_repository/user_profile_repository.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_account_access_overview.dart';
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
        directFileUploadService: ref.watch(directFileUploadServiceProvider),
        fileContentTypeResolver: ref.watch(fileContentTypeResolverProvider),
      );
    });

final Provider<UserAccountRepository> userAccountRepositoryProvider =
    Provider<UserAccountRepository>((Ref ref) {
      final dioService = ref.watch(appDioServiceProvider);
      final localizationService = ref.watch(appLocalizationServiceProvider);
      return UserAccountRepository(
        dioService: dioService,
        localizationService: localizationService,
      );
    });

final Provider<UserAccountService> userAccountServiceProvider =
    Provider<UserAccountService>((Ref ref) {
      final repository = ref.watch(userAccountRepositoryProvider);
      return UserAccountService(repository: repository);
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

final currentUserPrivacySettingsProvider =
    FutureProvider.autoDispose<UserProfilePrivacySettings>((Ref ref) {
      return ref
          .watch(userProfileServiceProvider)
          .getCurrentUserPrivacySettings();
    });

final currentUserAccountAccessOverviewProvider =
    FutureProvider.autoDispose<UserAccountAccessOverview>((Ref ref) {
      return ref
          .watch(userAccountServiceProvider)
          .getCurrentUserAccessOverview();
    });

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

  @override
  Future<UserProfile> build() async {
    final UserProfile? cachedProfile = await _offlinePersistence
        .getCurrentUserProfile();
    if (cachedProfile != null) {
      unawaited(_refreshSilently());
      return cachedProfile;
    }

    return _fetchAndPersistRemoteProfile();
  }

  Future<UserProfile> reload({bool bypassThrottle = false}) async {
    final UserProfile? previousProfile = state.asData?.value;

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

    await reload(bypassThrottle: true);
    ref.read(currentUserProfileRefreshRequestProvider.notifier).clear();
    return true;
  }

  Future<void> clearCachedProfile() async {
    _reloadThrottle.reset();
    await _offlinePersistence.clearCurrentUserProfile();
  }

  Future<UserProfile> _fetchAndPersistRemoteProfile() async {
    final UserProfile remoteProfile = await _service.getCurrentUserProfile();
    final UserProfile persistedProfile = await _offlinePersistence
        .persistRemoteProfile(remoteProfile);
    _reloadThrottle.markSuccessfulReload();
    return persistedProfile;
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
