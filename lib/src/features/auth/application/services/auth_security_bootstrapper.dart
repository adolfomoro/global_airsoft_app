import 'package:global_airsoft_app/src/core/storage/key_value_store.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_security_coordinator.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_storage_service.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/auth_tokens.dart';

final class AuthSecurityBootstrapper {
  AuthSecurityBootstrapper({
    required AuthSecurityCoordinator coordinator,
    required AuthStorageService authStorageService,
    required KeyValueStore keyValueStore,
    required Future<void> Function() clearLocalSessionData,
    required void Function() setUnauthenticated,
  }) : _coordinator = coordinator,
       _authStorageService = authStorageService,
       _keyValueStore = keyValueStore,
       _clearLocalSessionData = clearLocalSessionData,
       _setUnauthenticated = setUnauthenticated;

  static const String _userIdBackupKey = 'user_id_for_backup';

  final AuthSecurityCoordinator _coordinator;
  final AuthStorageService _authStorageService;
  final KeyValueStore _keyValueStore;
  final Future<void> Function() _clearLocalSessionData;
  final void Function() _setUnauthenticated;

  void configure({
    required AuthTokens? initialTokens,
    required AuthTokensRefresher refreshTokens,
    required AuthMessageTranslator translateMessage,
    required AuthMessagePresenter showMessage,
  }) {
    _coordinator.configure(
      getTokens: _authStorageService.getTokens,
      saveTokens: _authStorageService.saveTokens,
      initialTokens: initialTokens,
      cacheInitialTokens: true,
      clearSession: () async {
        await _authStorageService.clearAll();
        await _keyValueStore.remove(_userIdBackupKey);
        await _clearLocalSessionData();
        _setUnauthenticated();
      },
      refreshTokens: refreshTokens,
      translateMessage: translateMessage,
      showMessage: showMessage,
    );
  }
}
