import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/storage/app_file_storage_service.dart';
import 'package:global_airsoft_app/src/core/storage/secure_storage_service.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_storage_service.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/auth_profile.dart';
import 'package:global_airsoft_app/src/features/users/application/services/current_user_profile_offline_persistence_service.dart';
import 'package:global_airsoft_app/src/features/users/application/services/user_profile_offline_photo_storage_service.dart';
import 'package:global_airsoft_app/src/features/users/application/services/user_profile_storage_service.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_profile.dart';

final class _InMemorySecureStorageService implements SecureStorageService {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> getString(String key) async {
    return values[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> clear() async {
    values.clear();
  }
}

final class _FakeDownloadHttpClientAdapter implements HttpClientAdapter {
  _FakeDownloadHttpClientAdapter({required this.bodyByUrl});

  final Map<String, List<int>> bodyByUrl;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();

    final List<int>? body = bodyByUrl[options.uri.toString()];
    if (body == null) {
      return ResponseBody.fromString('Not found', HttpStatus.notFound);
    }

    return ResponseBody.fromBytes(
      body,
      HttpStatus.ok,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['image/jpeg'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'user-profile-storage-test-',
    );
  });

  tearDown(() async {
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('stores current user profile metadata together with an offline photo', () async {
    final _InMemorySecureStorageService secureStorage =
        _InMemorySecureStorageService();
    final AuthStorageService authStorageService = AuthStorageService(
      secureStorage: secureStorage,
    );
    await authStorageService.saveProfile(
      const AuthProfile(userId: 'user-1', username: 'tester'),
    );

    final Dio dio = Dio();
    dio.httpClientAdapter = _FakeDownloadHttpClientAdapter(
      bodyByUrl: <String, List<int>>{
        'https://cdn.example.com/profile-large.jpg': <int>[1, 2, 3, 4],
      },
    );

    final UserProfileOfflinePhotoStorageService offlinePhotoStorageService =
        UserProfileOfflinePhotoStorageService(
          fileStorage: AppFileStorageService(
            rootDirectoryResolver: () async => tempDirectory,
          ),
          downloadClient: dio,
          logger: AppLogger.instance,
        );

    final UserProfileStorageService storageService = UserProfileStorageService(
      secureStorage: secureStorage,
      authStorageService: authStorageService,
      offlinePhotoStorageService: offlinePhotoStorageService,
      logger: AppLogger.instance,
    );
    final CurrentUserProfileOfflinePersistenceService persistenceService =
        CurrentUserProfileOfflinePersistenceService(
          storageService: storageService,
          offlinePhotoStorageService: offlinePhotoStorageService,
          logger: AppLogger.instance,
        );

    const UserProfile profile = UserProfile(
      id: 'user-1',
      username: 'tester',
      fullName: 'Test User',
      bio: 'Ready for offline mode',
      mediumProfilePictureUrl: 'https://cdn.example.com/profile-medium.jpg',
      largeProfilePictureUrl: 'https://cdn.example.com/profile-large.jpg',
    );

    final UserProfile persistedProfile = await persistenceService
        .persistRemoteProfile(profile);

    final String? rawProfile = await secureStorage.getString(
      'users.current_user_profile',
    );
    expect(rawProfile, isNotNull);
    expect(
      jsonDecode(rawProfile!) as Map<String, dynamic>,
      containsPair('username', 'tester'),
    );

    expect(persistedProfile.localProfilePicturePath, isNotEmpty);

    final UserProfile? cachedProfile =
        await persistenceService.getCurrentUserProfile();
    expect(cachedProfile, isNotNull);
    expect(cachedProfile!.username, 'tester');
    expect(cachedProfile.fullName, 'Test User');
    expect(cachedProfile.localProfilePicturePath, isNotEmpty);

    final File offlinePhoto = File(cachedProfile.localProfilePicturePath);
    expect(offlinePhoto.existsSync(), isTrue);
    expect(await offlinePhoto.readAsBytes(), <int>[1, 2, 3, 4]);
  });

  test('clears stored offline profile assets on profile cleanup', () async {
    final _InMemorySecureStorageService secureStorage =
        _InMemorySecureStorageService();
    final AuthStorageService authStorageService = AuthStorageService(
      secureStorage: secureStorage,
    );
    await authStorageService.saveProfile(
      const AuthProfile(userId: 'user-1', username: 'tester'),
    );

    final Dio dio = Dio();
    dio.httpClientAdapter = _FakeDownloadHttpClientAdapter(
      bodyByUrl: <String, List<int>>{
        'https://cdn.example.com/profile-large.jpg': <int>[9, 8, 7],
      },
    );

    final UserProfileOfflinePhotoStorageService offlinePhotoStorageService =
        UserProfileOfflinePhotoStorageService(
          fileStorage: AppFileStorageService(
            rootDirectoryResolver: () async => tempDirectory,
          ),
          downloadClient: dio,
          logger: AppLogger.instance,
        );

    final UserProfileStorageService storageService = UserProfileStorageService(
      secureStorage: secureStorage,
      authStorageService: authStorageService,
      offlinePhotoStorageService: offlinePhotoStorageService,
      logger: AppLogger.instance,
    );
    final CurrentUserProfileOfflinePersistenceService persistenceService =
        CurrentUserProfileOfflinePersistenceService(
          storageService: storageService,
          offlinePhotoStorageService: offlinePhotoStorageService,
          logger: AppLogger.instance,
        );

    await persistenceService.persistRemoteProfile(
      const UserProfile(
        id: 'user-1',
        username: 'tester',
        fullName: 'Test User',
        bio: '',
        mediumProfilePictureUrl: '',
        largeProfilePictureUrl: 'https://cdn.example.com/profile-large.jpg',
      ),
    );

    final UserProfile? cachedProfileBeforeClear =
        await persistenceService.getCurrentUserProfile();
    expect(cachedProfileBeforeClear, isNotNull);

    final File offlinePhoto = File(
      cachedProfileBeforeClear!.localProfilePicturePath,
    );
    expect(offlinePhoto.existsSync(), isTrue);

    await persistenceService.clearCurrentUserProfile();

    expect(
      await secureStorage.getString('users.current_user_profile'),
      isNull,
    );
    expect(
      await secureStorage.getString('users.current_user_profile_user_id'),
      isNull,
    );
    expect(offlinePhoto.existsSync(), isFalse);
  });

  test('replaces the stored profile photo with a new versioned local path', () async {
    final _InMemorySecureStorageService secureStorage =
        _InMemorySecureStorageService();
    final AuthStorageService authStorageService = AuthStorageService(
      secureStorage: secureStorage,
    );
    await authStorageService.saveProfile(
      const AuthProfile(userId: 'user-1', username: 'tester'),
    );

    final Dio dio = Dio();
    dio.httpClientAdapter = _FakeDownloadHttpClientAdapter(
      bodyByUrl: <String, List<int>>{
        'https://cdn.example.com/profile-large-v1.jpg': <int>[1, 1, 1],
        'https://cdn.example.com/profile-large-v2.jpg': <int>[2, 2, 2],
      },
    );

    final UserProfileOfflinePhotoStorageService offlinePhotoStorageService =
        UserProfileOfflinePhotoStorageService(
          fileStorage: AppFileStorageService(
            rootDirectoryResolver: () async => tempDirectory,
          ),
          downloadClient: dio,
          logger: AppLogger.instance,
        );

    final UserProfileStorageService storageService = UserProfileStorageService(
      secureStorage: secureStorage,
      authStorageService: authStorageService,
      offlinePhotoStorageService: offlinePhotoStorageService,
      logger: AppLogger.instance,
    );
    final CurrentUserProfileOfflinePersistenceService persistenceService =
        CurrentUserProfileOfflinePersistenceService(
          storageService: storageService,
          offlinePhotoStorageService: offlinePhotoStorageService,
          logger: AppLogger.instance,
        );

    final UserProfile firstProfile = await persistenceService.persistRemoteProfile(
      const UserProfile(
        id: 'user-1',
        username: 'tester',
        fullName: 'Test User',
        bio: '',
        mediumProfilePictureUrl: '',
        largeProfilePictureUrl: 'https://cdn.example.com/profile-large-v1.jpg',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));
    final UserProfile secondProfile = await persistenceService
        .persistRemoteProfile(
          const UserProfile(
            id: 'user-1',
            username: 'tester',
            fullName: 'Test User',
            bio: '',
            mediumProfilePictureUrl: '',
            largeProfilePictureUrl:
                'https://cdn.example.com/profile-large-v2.jpg',
          ),
        );

    expect(firstProfile.localProfilePicturePath, isNotEmpty);
    expect(secondProfile.localProfilePicturePath, isNotEmpty);
    expect(
      secondProfile.localProfilePicturePath,
      isNot(equals(firstProfile.localProfilePicturePath)),
    );

    final UserProfile? cachedProfile =
        await persistenceService.getCurrentUserProfile();
    expect(cachedProfile, isNotNull);
    expect(
      cachedProfile!.localProfilePicturePath,
      secondProfile.localProfilePicturePath,
    );
    expect(
      await File(cachedProfile.localProfilePicturePath).readAsBytes(),
      <int>[2, 2, 2],
    );
    expect(File(firstProfile.localProfilePicturePath).existsSync(), isFalse);
  });

  test(
    'refreshes offline profile photo when remote URL stays the same',
    () async {
      final _InMemorySecureStorageService secureStorage =
          _InMemorySecureStorageService();
      final AuthStorageService authStorageService = AuthStorageService(
        secureStorage: secureStorage,
      );
      await authStorageService.saveProfile(
        const AuthProfile(userId: 'user-1', username: 'tester'),
      );

      final Map<String, List<int>> bodyByUrl = <String, List<int>>{
        'https://cdn.example.com/profile-large-stable.jpg': <int>[7, 7, 7],
      };
      final Dio dio = Dio();
      dio.httpClientAdapter = _FakeDownloadHttpClientAdapter(
        bodyByUrl: bodyByUrl,
      );

      final UserProfileOfflinePhotoStorageService offlinePhotoStorageService =
          UserProfileOfflinePhotoStorageService(
            fileStorage: AppFileStorageService(
              rootDirectoryResolver: () async => tempDirectory,
            ),
            downloadClient: dio,
            logger: AppLogger.instance,
          );

      final UserProfileStorageService storageService = UserProfileStorageService(
        secureStorage: secureStorage,
        authStorageService: authStorageService,
        offlinePhotoStorageService: offlinePhotoStorageService,
        logger: AppLogger.instance,
      );
      final CurrentUserProfileOfflinePersistenceService persistenceService =
          CurrentUserProfileOfflinePersistenceService(
            storageService: storageService,
            offlinePhotoStorageService: offlinePhotoStorageService,
            logger: AppLogger.instance,
          );

      final UserProfile firstProfile = await persistenceService.persistRemoteProfile(
        const UserProfile(
          id: 'user-1',
          username: 'tester',
          fullName: 'Test User',
          bio: '',
          mediumProfilePictureUrl: '',
          largeProfilePictureUrl:
              'https://cdn.example.com/profile-large-stable.jpg',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 1));
      bodyByUrl['https://cdn.example.com/profile-large-stable.jpg'] = <int>[
        8,
        8,
        8,
      ];

      final UserProfile secondProfile = await persistenceService
          .persistRemoteProfile(
            const UserProfile(
              id: 'user-1',
              username: 'tester',
              fullName: 'Test User',
              bio: '',
              mediumProfilePictureUrl: '',
              largeProfilePictureUrl:
                  'https://cdn.example.com/profile-large-stable.jpg',
            ),
          );

      expect(firstProfile.localProfilePicturePath, isNotEmpty);
      expect(secondProfile.localProfilePicturePath, isNotEmpty);
      expect(
        secondProfile.localProfilePicturePath,
        isNot(equals(firstProfile.localProfilePicturePath)),
      );
      expect(
        await File(secondProfile.localProfilePicturePath).readAsBytes(),
        <int>[8, 8, 8],
      );
      expect(File(firstProfile.localProfilePicturePath).existsSync(), isFalse);
    },
  );

  test('deletes the local profile photo when the refreshed remote profile has no photo', () async {
    final _InMemorySecureStorageService secureStorage =
        _InMemorySecureStorageService();
    final AuthStorageService authStorageService = AuthStorageService(
      secureStorage: secureStorage,
    );
    await authStorageService.saveProfile(
      const AuthProfile(userId: 'user-1', username: 'tester'),
    );

    final Dio dio = Dio();
    dio.httpClientAdapter = _FakeDownloadHttpClientAdapter(
      bodyByUrl: <String, List<int>>{
        'https://cdn.example.com/profile-large.jpg': <int>[5, 5, 5],
      },
    );

    final UserProfileOfflinePhotoStorageService offlinePhotoStorageService =
        UserProfileOfflinePhotoStorageService(
          fileStorage: AppFileStorageService(
            rootDirectoryResolver: () async => tempDirectory,
          ),
          downloadClient: dio,
          logger: AppLogger.instance,
        );

    final UserProfileStorageService storageService = UserProfileStorageService(
      secureStorage: secureStorage,
      authStorageService: authStorageService,
      offlinePhotoStorageService: offlinePhotoStorageService,
      logger: AppLogger.instance,
    );
    final CurrentUserProfileOfflinePersistenceService persistenceService =
        CurrentUserProfileOfflinePersistenceService(
          storageService: storageService,
          offlinePhotoStorageService: offlinePhotoStorageService,
          logger: AppLogger.instance,
        );

    final UserProfile firstProfile = await persistenceService.persistRemoteProfile(
      const UserProfile(
        id: 'user-1',
        username: 'tester',
        fullName: 'Test User',
        bio: '',
        mediumProfilePictureUrl: '',
        largeProfilePictureUrl: 'https://cdn.example.com/profile-large.jpg',
      ),
    );
    expect(firstProfile.localProfilePicturePath, isNotEmpty);
    expect(File(firstProfile.localProfilePicturePath).existsSync(), isTrue);

    final UserProfile secondProfile = await persistenceService.persistRemoteProfile(
      const UserProfile(
        id: 'user-1',
        username: 'tester',
        fullName: 'Test User',
        bio: '',
        mediumProfilePictureUrl: '',
        largeProfilePictureUrl: '',
      ),
    );

    expect(secondProfile.localProfilePicturePath, isEmpty);
    expect(File(firstProfile.localProfilePicturePath).existsSync(), isFalse);

    final UserProfile? cachedProfile =
        await persistenceService.getCurrentUserProfile();
    expect(cachedProfile, isNotNull);
    expect(cachedProfile!.localProfilePicturePath, isEmpty);
    expect(cachedProfile.mediumProfilePictureUrl, isEmpty);
    expect(cachedProfile.largeProfilePictureUrl, isEmpty);
  });
}
