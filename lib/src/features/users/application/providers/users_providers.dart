import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/network/constants/app_network_headers.dart';
import 'package:global_airsoft_app/src/core/storage/storage_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/users/application/services/current_user_profile_offline_persistence_service.dart';
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
      return UserProfileService(repository: repository);
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

final Provider<Dio> userProfileOfflineDownloadClientProvider = Provider<Dio>((
  Ref ref,
) {
  final config = ref.watch(appConfigProvider);
  return Dio(
    BaseOptions(
      connectTimeout: Duration(milliseconds: config.connectTimeoutMs),
      receiveTimeout: Duration(milliseconds: config.receiveTimeoutMs),
      sendTimeout: Duration(milliseconds: config.sendTimeoutMs),
      headers: <String, Object>{
        Headers.acceptHeader: 'image/*,*/*',
        AppNetworkHeaders.userAgentHeader: AppNetworkHeaders.userAgentValue,
      },
    ),
  );
});

final Provider<UserProfileOfflinePhotoStorageService>
userProfileOfflinePhotoStorageServiceProvider =
    Provider<UserProfileOfflinePhotoStorageService>((Ref ref) {
      final fileStorage = ref.watch(appFileStorageServiceProvider);
      final downloadClient = ref.watch(
        userProfileOfflineDownloadClientProvider,
      );
      return UserProfileOfflinePhotoStorageService(
        fileStorage: fileStorage,
        downloadClient: downloadClient,
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
  UserProfileService get _service => ref.read(userProfileServiceProvider);
  CurrentUserProfileOfflinePersistenceService get _offlinePersistence =>
      ref.read(currentUserProfileOfflinePersistenceServiceProvider);
  AppLogger get _logger => AppLogger.instance;

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

  Future<bool> reloadIfRefreshRequested() async {
    if (!ref.read(currentUserProfileRefreshRequestProvider)) {
      return false;
    }

    await reload();
    ref.read(currentUserProfileRefreshRequestProvider.notifier).clear();
    return true;
  }

  Future<void> clearCachedProfile() {
    return _offlinePersistence.clearCurrentUserProfile();
  }

  Future<UserProfile> _fetchAndPersistRemoteProfile() async {
    final UserProfile remoteProfile = await _service.getCurrentUserProfile();
    return _offlinePersistence.persistRemoteProfile(remoteProfile);
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
