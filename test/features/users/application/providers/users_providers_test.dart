import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/features/users/application/providers/users_providers.dart';

void main() {
  test('profile refresh request provider toggles pending state explicitly', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(currentUserProfileRefreshRequestProvider), isFalse);

    container
        .read(currentUserProfileRefreshRequestProvider.notifier)
        .requestRefresh();

    expect(container.read(currentUserProfileRefreshRequestProvider), isTrue);

    container.read(currentUserProfileRefreshRequestProvider.notifier).clear();

    expect(container.read(currentUserProfileRefreshRequestProvider), isFalse);
  });
}
