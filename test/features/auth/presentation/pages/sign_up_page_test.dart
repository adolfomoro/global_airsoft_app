import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/pages/sign_up_page.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/username_availability_field.dart';

void main() {
  test('sign-up form notifier clears nullable field errors', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final SignUpFormNotifier notifier = container.read(
      signUpFormStateProvider.notifier,
    );

    notifier.setFieldError(SignUpFieldType.fullName, 'invalid-name');
    notifier.setFieldError(SignUpFieldType.username, 'invalid-username');
    notifier.setFieldError(SignUpFieldType.email, 'invalid-email');
    notifier.setFieldError(SignUpFieldType.password, 'invalid-password');

    notifier.clearFieldError(SignUpFieldType.username);

    SignUpFormState state = container.read(signUpFormStateProvider);
    expect(state.fullNameError, 'invalid-name');
    expect(state.usernameError, isNull);
    expect(state.emailError, 'invalid-email');
    expect(state.passwordError, 'invalid-password');

    notifier.clearErrors();

    state = container.read(signUpFormStateProvider);
    expect(state.fullNameError, isNull);
    expect(state.usernameError, isNull);
    expect(state.emailError, isNull);
    expect(state.passwordError, isNull);
  });

  test('sign-up form state copyWith can explicitly clear nullable fields', () {
    const SignUpFormState initialState = SignUpFormState(
      fullNameError: 'name-error',
      usernameError: 'username-error',
      emailError: 'email-error',
      passwordError: 'password-error',
      usernameAvailabilityStatus: UsernameAvailabilityStatus.unavailable,
      isLoading: true,
      isPasswordFocused: true,
      hasRevealedPasswordHint: true,
    );

    final SignUpFormState updatedState = initialState.copyWith(
      fullNameError: null,
      usernameError: null,
      emailError: null,
      passwordError: null,
      isLoading: false,
      isPasswordFocused: false,
      hasRevealedPasswordHint: false,
    );

    expect(updatedState.fullNameError, isNull);
    expect(updatedState.usernameError, isNull);
    expect(updatedState.emailError, isNull);
    expect(updatedState.passwordError, isNull);
    expect(
      updatedState.usernameAvailabilityStatus,
      initialState.usernameAvailabilityStatus,
    );
    expect(updatedState.isLoading, isFalse);
    expect(updatedState.isPasswordFocused, isFalse);
    expect(updatedState.hasRevealedPasswordHint, isFalse);
  });
}
