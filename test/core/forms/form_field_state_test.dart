import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/forms/forms.dart';

void main() {
  group('FormFieldState<T>', () {
    test('creates with valid initial state', () {
      const state = FormFieldState<String>(value: 'test');

      expect(state.value, 'test');
      expect(state.error, null);
      expect(state.isTouched, false);
      expect(state.isDirty, false);
      expect(state.isValid, true);
      expect(state.hasError, false);
    });

    test('copyWith updates fields selectively', () {
      const state = FormFieldState<String>(
        value: 'initial',
        error: 'error1',
        isTouched: true,
        isDirty: true,
      );

      final updated = state.copyWith(error: null);

      expect(updated.value, 'initial');
      expect(updated.error, null);
      expect(updated.isTouched, true);
      expect(updated.isDirty, true);
    });

    test('reset clears to initial state', () {
      const state = FormFieldState<String>(
        value: 'changed',
        error: 'error',
        isTouched: true,
        isDirty: true,
      );

      final reset = state.reset('initial');

      expect(reset.value, 'initial');
      expect(reset.error, null);
      expect(reset.isTouched, false);
      expect(reset.isDirty, false);
    });

    test('hasError returns true only when error is not null/empty', () {
      expect(
        const FormFieldState<String>(value: '', error: null).hasError,
        false,
      );
      expect(
        const FormFieldState<String>(value: '', error: '').hasError,
        false,
      );
      expect(
        const FormFieldState<String>(value: '', error: 'error').hasError,
        true,
      );
    });

    test('equality works correctly', () {
      const state1 = FormFieldState<String>(value: 'test', error: null);
      const state2 = FormFieldState<String>(value: 'test', error: null);
      const state3 = FormFieldState<String>(value: 'test', error: 'err');

      expect(state1, state2);
      expect(state1, isNot(state3));
    });
  });

  group('FormSubmissionState', () {
    test('creates with default state', () {
      const state = FormSubmissionState();

      expect(state.isSubmitting, false);
      expect(state.generalError, null);
      expect(state.wasSubmitted, false);
      expect(state.hasError, false);
    });

    test('copyWith updates fields', () {
      const state = FormSubmissionState(isSubmitting: true);

      final updated = state.copyWith(isSubmitting: false, generalError: 'error');

      expect(updated.isSubmitting, false);
      expect(updated.generalError, 'error');
      expect(updated.wasSubmitted, false);
    });

    test('hasError reflects general error state', () {
      expect(
        const FormSubmissionState(generalError: null).hasError,
        false,
      );
      expect(
        const FormSubmissionState(generalError: '').hasError,
        false,
      );
      expect(
        const FormSubmissionState(generalError: 'error').hasError,
        true,
      );
    });
  });

  group('FormFieldValidator<T>', () {
    test('NoOpFormFieldValidator accepts everything', () {
      final validator = NoOpFormFieldValidator<String>();

      expect(validator.validate(''), null);
      expect(validator.validate('test'), null);
      expect(validator.validate('anything'), null);
    });

    test('validates and updates state correctly', () {
      final validator = NoOpFormFieldValidator<String>();
      const state = FormFieldState<String>(
        value: 'test',
        error: 'old error',
      );

      final updated = validator.validateAndUpdate(state);

      expect(updated.value, 'test');
      expect(updated.error, null);
    });
  });

  group('FormFieldNotifier<T>', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('builds with initial value', () {
      final state = container.read(_testFieldProvider);

      expect(state.value, 'initial');
      expect(state.error, null);
    });

    test('setValue updates state and marks as touched/dirty', () {
      container.read(_testFieldProvider.notifier).setValue('new value');
      final state = container.read(_testFieldProvider);

      expect(state.value, 'new value');
      expect(state.isTouched, true);
      expect(state.isDirty, true);
    });

    test('setValue does not update if value is same', () {
      final notifier = container.read(_testFieldProvider.notifier);
      notifier.setValue('initial');
      final state = container.read(_testFieldProvider);

      // Should not mark as dirty if same value
      expect(state.isDirty, false);
      expect(state.isTouched, false);
    });

    test('markTouched marks field as touched', () {
      container.read(_testFieldProvider.notifier).markTouched();
      final state = container.read(_testFieldProvider);

      expect(state.isTouched, true);
    });

    test('setError sets error without changing value', () {
      container.read(_testFieldProvider.notifier).setError('new error');
      final state = container.read(_testFieldProvider);

      expect(state.value, 'initial');
      expect(state.error, 'new error');
    });

    test('clearError removes error', () {
      final notifier = container.read(_testFieldProvider.notifier);
      notifier.setError('error');
      notifier.clearError();
      final state = container.read(_testFieldProvider);

      expect(state.error, null);
    });

    test('validate checks current value and updates error', () {
      final notifier = container.read(_testFieldProvider.notifier);
      final isValid = notifier.validate();

      expect(isValid, true); // No error for 'initial'
      expect(container.read(_testFieldProvider).error, null);
    });

    test('reset clears to initial value', () {
      final notifier = container.read(_testFieldProvider.notifier);
      notifier.setValue('changed');
      notifier.markTouched();
      notifier.reset();

      final state = container.read(_testFieldProvider);
      expect(state.value, 'initial');
      expect(state.error, null);
      expect(state.isTouched, false);
      expect(state.isDirty, false);
    });
  });

  group('FormStateNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('builds with default state', () {
      final state = container.read(_testFormStateProvider);

      expect(state.isSubmitting, false);
      expect(state.generalError, null);
      expect(state.wasSubmitted, false);
    });

    test('setSubmitting updates loading state', () {
      container.read(_testFormStateProvider.notifier).setSubmitting(true);
      final state = container.read(_testFormStateProvider);

      expect(state.isSubmitting, true);
    });

    test('setError updates error', () {
      container.read(_testFormStateProvider.notifier).setError('new error');
      final state = container.read(_testFormStateProvider);

      expect(state.generalError, 'new error');
    });

    test('markSubmitted marks form as submitted', () {
      container.read(_testFormStateProvider.notifier).markSubmitted();
      final state = container.read(_testFormStateProvider);

      expect(state.wasSubmitted, true);
    });

    test('reset clears to initial state', () {
      final notifier = container.read(_testFormStateProvider.notifier);
      notifier.setSubmitting(true);
      notifier.setError('error');
      notifier.markSubmitted();
      notifier.reset();

      final state = container.read(_testFormStateProvider);
      expect(state.isSubmitting, false);
      expect(state.generalError, null);
      expect(state.wasSubmitted, false);
    });

    test('completeSubmission sets final state', () {
      final notifier = container.read(_testFormStateProvider.notifier);
      notifier.setSubmitting(true);
      notifier.completeSubmission(error: 'submission error');

      final state = container.read(_testFormStateProvider);
      expect(state.isSubmitting, false);
      expect(state.generalError, 'submission error');
      expect(state.wasSubmitted, true);
    });
  });
}

// Test implementations
final class _TestFieldNotifier extends FormFieldNotifier<String> {
  @override
  String get initialValue => 'initial';
}

final class _TestFormStateNotifier extends FormStateNotifier {}

// Test providers
final _testFieldProvider =
    NotifierProvider<_TestFieldNotifier, FormFieldState<String>>(
  () => _TestFieldNotifier(),
);

final _testFormStateProvider =
    NotifierProvider<_TestFormStateNotifier, FormSubmissionState>(
  () => _TestFormStateNotifier(),
);
