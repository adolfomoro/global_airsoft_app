import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_security_coordinator.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/auth_tokens.dart';

void main() {
  late AuthSecurityCoordinator coordinator;

  setUp(() {
    coordinator = AuthSecurityCoordinator();
  });

  tearDown(() {
    coordinator.reset();
  });

  test('reuses cached tokens without repeated storage reads', () async {
    int readerCalls = 0;
    final AuthTokens bootTokens = const AuthTokens(
      jwtToken: 'boot-jwt',
      refreshToken: 'boot-refresh',
    );

    coordinator.configure(
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
      showMessage: (String message, {Object? source}) async {},
      initialTokens: bootTokens,
      cacheInitialTokens: true,
    );

    final AuthTokens? first = await coordinator.readTokens();
    final AuthTokens? second = await coordinator.readTokens();

    expect(readerCalls, 0);
    expect(first?.jwtToken, 'boot-jwt');
    expect(second?.refreshToken, 'boot-refresh');

    final AuthTokens refreshedTokens = const AuthTokens(
      jwtToken: 'new-jwt',
      refreshToken: 'new-refresh',
    );
    await coordinator.saveTokens(refreshedTokens);

    final AuthTokens? afterSave = await coordinator.readTokens();
    expect(afterSave?.jwtToken, 'new-jwt');
    expect(readerCalls, 0);

    await coordinator.clearSession();

    final AuthTokens? afterClear = await coordinator.readTokens();
    expect(afterClear, isNull);
    expect(readerCalls, 0);
  });
}
