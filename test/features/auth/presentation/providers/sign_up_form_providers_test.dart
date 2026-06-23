import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/controllers/login_form_controller.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/controllers/password_recovery_form_controller.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/controllers/sign_up_form_controller.dart';

void main() {
  group('SignUpFormControllerProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initializes all fields with empty values', () {
      final state = container.read(signUpFormControllerProvider);

      expect(state.fullName.value, '');
      expect(state.username.value, '');
      expect(state.email.value, '');
      expect(state.password.value, '');
      expect(state.confirmPassword.value, '');
    });

    test('initializes all fields without errors', () {
      final state = container.read(signUpFormControllerProvider);

      expect(state.fullName.error, null);
      expect(state.username.error, null);
      expect(state.email.error, null);
      expect(state.password.error, null);
      expect(state.confirmPassword.error, null);
    });

    test('updateFullName updates field value', () {
      container
          .read(signUpFormControllerProvider.notifier)
          .updateFullName('John Doe');

      expect(container.read(signUpFormControllerProvider).fullName.value, 'John Doe');
    });

    test('passwordsMatch is true for matching passwords', () {
      final notifier = container.read(signUpFormControllerProvider.notifier);

      notifier.updatePassword('password123');
      notifier.updateConfirmPassword('password123');

      expect(container.read(signUpFormControllerProvider).passwordsMatch, true);
    });

    test('passwordsMatch is false for different passwords', () {
      final notifier = container.read(signUpFormControllerProvider.notifier);

      notifier.updatePassword('password123');
      notifier.updateConfirmPassword('different');

      expect(container.read(signUpFormControllerProvider).passwordsMatch, false);
    });

    test('form is invalid initially', () {
      expect(container.read(signUpFormControllerProvider).isValid, false);
    });

    test('submit is disabled when form is invalid', () {
      expect(container.read(signUpFormControllerProvider).canSubmit, false);
    });

    test('form becomes valid only when all values satisfy the rules', () {
      final notifier = container.read(signUpFormControllerProvider.notifier);

      notifier.updateFullName('John Doe');
      notifier.updateUsername('john.doe');
      notifier.updateEmail('john@example.com');
      notifier.updatePassword('Abcdef1!');
      notifier.updateConfirmPassword('Abcdef1!');

      final state = container.read(signUpFormControllerProvider);
      expect(state.isValid, true);
      expect(state.canSubmit, true);
    });

    test('route-scoped state resets after last listener is closed', () async {
      final subscription = container.listen<String>(
        signUpFormControllerProvider.select((state) => state.fullName.value),
        (_, _) {},
      );

      container
          .read(signUpFormControllerProvider.notifier)
          .updateFullName('Persistent Name');

      expect(container.read(signUpFormControllerProvider).fullName.value, 'Persistent Name');

      subscription.close();
      await container.pump();

      final state = container.read(signUpFormControllerProvider);
      expect(state.fullName.value, '');
      expect(state.fullName.error, null);
    });
  });

  group('LoginFormControllerProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initializes with empty login and password', () {
      final state = container.read(loginFormControllerProvider);

      expect(state.login.value, '');
      expect(state.password.value, '');
      expect(state.canSubmitCredentials, false);
      expect(state.canSubmitGoogle, true);
    });

    test('credentials submit becomes enabled only with valid values', () {
      final notifier = container.read(loginFormControllerProvider.notifier);

      notifier.updateLogin('user@example.com');
      notifier.updatePassword('secret123');

      final state = container.read(loginFormControllerProvider);
      expect(state.isValid, true);
      expect(state.canSubmitCredentials, true);
    });

    test('route-scoped state resets after last listener is closed', () async {
      final subscription = container.listen<String>(
        loginFormControllerProvider.select((state) => state.login.value),
        (_, _) {},
      );

      container
          .read(loginFormControllerProvider.notifier)
          .updateLogin('user@example.com');

      expect(container.read(loginFormControllerProvider).login.value, 'user@example.com');

      subscription.close();
      await container.pump();

      final state = container.read(loginFormControllerProvider);
      expect(state.login.value, '');
      expect(state.login.error, null);
    });
  });

  group('PasswordRecoveryFormControllerProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('email field initializes with empty string', () {
      expect(container.read(passwordRecoveryFormControllerProvider).email.value, '');
    });

    test('email has no error initially', () {
      expect(container.read(passwordRecoveryFormControllerProvider).email.error, null);
    });

    test('updateEmail updates email value', () {
      container
          .read(passwordRecoveryFormControllerProvider.notifier)
          .updateEmail('user@example.com');

      expect(container.read(passwordRecoveryFormControllerProvider).email.value, 'user@example.com');
    });

    test('form is invalid initially', () {
      expect(container.read(passwordRecoveryFormControllerProvider).isValid, false);
    });

    test('submit becomes enabled only with valid email', () {
      container
          .read(passwordRecoveryFormControllerProvider.notifier)
          .updateEmail('user@example.com');

      final state = container.read(passwordRecoveryFormControllerProvider);
      expect(state.isValid, true);
      expect(state.canSubmit, true);
    });

    test('route-scoped state resets after last listener is closed', () async {
      final subscription = container.listen<String>(
        passwordRecoveryFormControllerProvider.select((state) => state.email.value),
        (_, _) {},
      );

      container
          .read(passwordRecoveryFormControllerProvider.notifier)
          .updateEmail('user@example.com');

      expect(container.read(passwordRecoveryFormControllerProvider).email.value, 'user@example.com');

      subscription.close();
      await container.pump();

      final state = container.read(passwordRecoveryFormControllerProvider);
      expect(state.email.value, '');
      expect(state.email.error, null);
    });
  });
}
