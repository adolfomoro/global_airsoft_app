import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/bootstrap/app_bootstrap_providers.dart';
import 'package:global_airsoft_app/src/core/storage/app_file_storage_service.dart';
import 'package:global_airsoft_app/src/core/storage/key_value_store.dart';
import 'package:global_airsoft_app/src/core/storage/secure_storage_service.dart';
import 'package:global_airsoft_app/src/core/storage/shared_prefs_key_value_store.dart';

export 'package:global_airsoft_app/src/core/storage/shared_prefs_key_value_store.dart';

final Provider<SecureStorageService> secureStorageServiceProvider =
    Provider<SecureStorageService>(
      (Ref ref) {
        final bootstrapData = ref.watch(appBootstrapDataProvider);
        return bootstrapData.secureStorageService;
      },
    );

/// Provides the KeyValueStore interface (abstraction).
final Provider<KeyValueStore> keyValueStoreProvider =
    Provider<KeyValueStore>(
      (Ref ref) {
        final bootstrapData = ref.watch(appBootstrapDataProvider);
        return bootstrapData.keyValueStore;
      },
    );

/// Provides the SharedPrefsKeyValueStore implementation (concrete type).
final Provider<SharedPrefsKeyValueStore> sharedPrefsKeyValueStoreProvider =
    Provider<SharedPrefsKeyValueStore>(
      (Ref ref) {
        final bootstrapData = ref.watch(appBootstrapDataProvider);
        // Safe cast since bootstrap creates SharedPrefsKeyValueStore instance
        return bootstrapData.keyValueStore as SharedPrefsKeyValueStore;
      },
    );

final Provider<AppFileStorageService> appFileStorageServiceProvider =
    Provider<AppFileStorageService>((Ref ref) {
      return AppFileStorageService();
    });
