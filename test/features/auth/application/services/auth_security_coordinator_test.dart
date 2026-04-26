import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_security_coordinator.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/auth_tokens.dart';

void main() {
  tearDown(() {
    AuthSecurityCoordinator.instance.reset();
  });

  test('reuses cached tokens without repeated storage reads', () async {
    int readerCalls = 0;
    final AuthTokens bootTokens = const AuthTokens(
      jwtToken: 'boot-jwt',
      refreshToken: 'boot-refresh',
    );

    AuthSecurityCoordinator.instance.configure(
      getTokens: () async {
        readerCalls += 1;
        return bootTokens;
      },
      saveTokens: (AuthTokens tokens) async {},
      clearSession: () async {},
      refreshTokens: (String refreshToken) async {
        return bootTokens;
      },
      translateMessage: (String key) async => key,
      showMessage: (String message) async {},
      initialTokens: bootTokens,
      cacheInitialTokens: true,
    );

    final AuthTokens? first = await AuthSecurityCoordinator.instance
        .readTokens();
    final AuthTokens? second = await AuthSecurityCoordinator.instance
        .readTokens();

    expect(readerCalls, 0);
    expect(first?.jwtToken, 'boot-jwt');
    expect(second?.refreshToken, 'boot-refresh');

    final AuthTokens refreshedTokens = const AuthTokens(
      jwtToken: 'new-jwt',
      refreshToken: 'new-refresh',
    );
    await AuthSecurityCoordinator.instance.saveTokens(refreshedTokens);

    final AuthTokens? afterSave = await AuthSecurityCoordinator.instance
        .readTokens();
    expect(afterSave?.jwtToken, 'new-jwt');
    expect(readerCalls, 0);

    await AuthSecurityCoordinator.instance.clearSession();

    final AuthTokens? afterClear = await AuthSecurityCoordinator.instance
        .readTokens();
    expect(afterClear, isNull);
    expect(readerCalls, 0);
  });
}
