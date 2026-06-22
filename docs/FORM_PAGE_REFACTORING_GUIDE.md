# Form Page Refactoring Pattern

This guide shows how to refactor any form page to use the production-grade Riverpod form state architecture.

## Architecture Overview

### Core Infrastructure (Ready to Use)
- **`FormFieldState<T>`** - Immutable state for a single field (value, error, isTouched, isDirty)
- **`FormFieldNotifier<T>`** - Base class for field state management
- **`FormSubmissionState`** - Track form-wide submission (isSubmitting, generalError, wasSubmitted)
- **`FormStateNotifier`** - Base class for form submission state
- **`StringFormFieldNotifier`** - Pre-configured for String fields

### Performance
- **`.select()`** - Granular observers: widgets rebuild ONLY when their specific value changes
- **No `setState()`** - All state via Riverpod providers
- **Consumer separation** - Each input area is its own widget
- **Logic extraction** - Submission logic in separate classes

---

## Step-by-Step: Refactoring a Form Page

### 1. Create Form Providers File

Create `lib/src/features/auth/presentation/providers/your_form_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/forms/forms.dart' as app_forms;

// Step 1: Create field notifiers (one per field)
final class YourFieldNotifier extends app_forms.StringFormFieldNotifier {
  @override
  String get initialValue => '';
}

// Step 2: Create form submission notifier
final class YourFormStateNotifier extends app_forms.FormStateNotifier {}

// Step 3: Create providers for each field and form state
final yourFieldProvider = NotifierProvider<YourFieldNotifier, app_forms.FormFieldState<String>>(
  () => YourFieldNotifier(),
);

final yourFormStateProvider = NotifierProvider<YourFormStateNotifier, app_forms.FormSubmissionState>(
  () => YourFormStateNotifier(),
);

// Step 4: Create value/error/validation selectors
final yourValueProvider = Provider<String>((ref) {
  return ref.watch(yourFieldProvider).value;
});

final yourErrorProvider = Provider<String?>((ref) {
  return ref.watch(yourFieldProvider).error;
});

final yourIsValidProvider = Provider<bool>((ref) {
  return ref.watch(yourFieldProvider).isValid;
});

// Step 5: Create form-wide selectors
final yourFormIsValidProvider = Provider<bool>((ref) {
  // Combine all field validations
  return ref.watch(yourIsValidProvider);
});

final yourSubmitEnabledProvider = Provider<bool>((ref) {
  final isValid = ref.watch(yourFormIsValidProvider);
  final isSubmitting = ref.watch(yourFormStateProvider).isSubmitting;
  return isValid && !isSubmitting;
});
```

### 2. Create Page v2 File

Create `lib/src/features/auth/presentation/pages/your_page_v2.dart`:

```dart
class YourPage extends ConsumerWidget {
  const YourPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _YourFieldConsumer(),  // Separate Consumer widget per field
            _SubmitButtonConsumer(),
          ],
        ),
      ),
    );
  }
}
```

### 3. Create Field Consumer Widgets

For **simple fields** (text inputs):

```dart
class _YourFieldConsumer extends ConsumerStatefulWidget {
  const _YourFieldConsumer();

  @override
  ConsumerState<_YourFieldConsumer> createState() => _YourFieldConsumerState();
}

class _YourFieldConsumerState extends ConsumerState<_YourFieldConsumer> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ONLY watch what you need
    final value = ref.watch(yourValueProvider);
    final error = ref.watch(yourErrorProvider);
    final isSubmitting = ref.watch(yourFormStateProvider).isSubmitting;

    // Sync controller with provider state
    if (_controller.text != value) {
      _controller.text = value;
    }

    return AppTextField(
      controller: _controller,
      errorText: error,
      onChanged: (newValue) {
        // Update provider when user types
        ref.read(yourFieldProvider.notifier).setValue(newValue);
      },
      onFieldSubmitted: (_) {
        if (!isSubmitting) {
          _YourSubmissionLogic.submit(context, ref);
        }
      },
      enabled: !isSubmitting,
    );
  }
}
```

### 4. Create Submit Button Consumer

```dart
class _SubmitButtonConsumer extends ConsumerWidget {
  const _SubmitButtonConsumer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(yourFormStateProvider).isSubmitting;
    final isEnabled = ref.watch(yourSubmitEnabledProvider);

    return AppButton(
      label: 'Submit',
      onPressed: !isEnabled ? null : () => _YourSubmissionLogic.submit(context, ref),
      isLoading: isSubmitting,
    );
  }
}
```

### 5. Create Submission Logic Class

Extract all submission logic:

```dart
abstract final class _YourSubmissionLogic {
  static const BackendValidationErrorMapper _errorMapper = BackendValidationErrorMapper();

  static Future<void> submit(BuildContext context, WidgetRef ref) async {
    FocusScope.of(context).unfocus();

    // Clear previous errors
    ref.read(yourFieldProvider.notifier).clearError();
    ref.read(yourFormStateProvider.notifier).setError(null);

    // Validate
    final isValid = ref.read(yourFieldProvider.notifier).validate();
    if (!isValid) return;

    // Get values
    final value = ref.read(yourValueProvider);

    // Mark as submitting
    ref.read(yourFormStateProvider.notifier).setSubmitting(true);

    try {
      final service = ref.read(yourServiceProvider);
      await service.yourMethod(value);
      
      if (!context.mounted) return;
      // Handle success
      Navigator.of(context).pop();
    } on YourException catch (error) {
      if (context.mounted) {
        ref.read(yourFieldProvider.notifier).setError(error.message);
        context.showErrorSnackBar(error.message);
      }
    } finally {
      if (context.mounted) {
        ref.read(yourFormStateProvider.notifier).setSubmitting(false);
      }
    }
  }
}
```

---

## Key Principles

### ✅ DO

- ✅ Create **one ConsumerStatefulWidget per input area** for TextEditingController management
- ✅ Use **`.select()` via Provider selectors** to watch only what's needed
- ✅ **Extract logic to separate classes** (keep consumers clean)
- ✅ **Validate before submission** using notifier's `.validate()` method
- ✅ **Clear errors before resubmitting** to prevent stale error display
- ✅ Use **`FormFieldState<T>` for type safety** (immutable, equatable)
- ✅ Test providers and logic separately from UI

### ❌ DON'T

- ❌ Use `setState()` - use providers instead
- ❌ Watch entire form state when you only need one field
- ❌ Keep logic in Consumer widgets - extract to separate classes
- ❌ Create global TextEditingControllers - manage locally in ConsumerStatefulWidget
- ❌ Skip error clearing - always clear before new submission
- ❌ Assume field values - always read from providers
- ❌ Forget to check `context.mounted` before navigating

---

## Example: Complete Simple Form

Here's a complete minimal example:

**Providers:**
```dart
final class EmailFieldNotifier extends StringFormFieldNotifier {
  @override
  String get initialValue => '';
}

final emailFieldProvider = NotifierProvider<EmailFieldNotifier, FormFieldState<String>>(
  () => EmailFieldNotifier(),
);

final emailValueProvider = Provider<String>((ref) => 
  ref.watch(emailFieldProvider).value
);

final emailErrorProvider = Provider<String?>((ref) => 
  ref.watch(emailFieldProvider).error
);

final emailSubmitEnabledProvider = Provider<bool>((ref) {
  final valid = ref.watch(emailFieldProvider).isValid;
  return valid; // Simplified for example
});
```

**Page:**
```dart
class SimpleFormPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          _EmailInput(),
          _SubmitButton(),
        ],
      ),
    );
  }
}

class _EmailInput extends ConsumerStatefulWidget {
  @override
  ConsumerState<_EmailInput> createState() => _EmailInputState();
}

class _EmailInputState extends ConsumerState<_EmailInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(emailValueProvider);
    final error = ref.watch(emailErrorProvider);

    if (_controller.text != value) {
      _controller.text = value;
    }

    return TextField(
      controller: _controller,
      onChanged: (v) => ref.read(emailFieldProvider.notifier).setValue(v),
      decoration: InputDecoration(errorText: error),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _SubmitButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(emailSubmitEnabledProvider);
    
    return ElevatedButton(
      onPressed: enabled ? () => _submit(context, ref) : null,
      child: const Text('Submit'),
    );
  }

  void _submit(BuildContext context, WidgetRef ref) async {
    final email = ref.read(emailValueProvider);
    // Do API call...
  }
}
```

---

## Testing

```dart
test('email provider works', () {
  final container = ProviderContainer();
  
  container.read(emailFieldProvider.notifier).setValue('test@example.com');
  
  expect(container.read(emailValueProvider), 'test@example.com');
  expect(container.read(emailErrorProvider), null);
});
```

---

## File Structure

```
lib/src/features/auth/presentation/
├── providers/
│   ├── login_form_providers.dart       # ✅ Already done
│   ├── sign_up_form_providers.dart     # ✅ Already done
│   ├── password_recovery_form_providers.dart  # ✅ Already done
│   ├── your_form_providers.dart        # 👈 Create per new form
│   └── form_providers_template.dart    # Reference
│
├── pages/
│   ├── login_page_v2.dart              # ✅ Already done
│   ├── sign_up_page_v2.dart            # 🔄 To do
│   ├── password_recovery_page_v2.dart  # ✅ Already done
│   └── your_page_v2.dart               # 👈 Create per new form
```

---

## Next Steps

1. **For each new form page:**
   - Create `your_form_providers.dart` using the template
   - Create `your_page_v2.dart` using the Consumer pattern
   - Add tests for providers

2. **Replace originals:**
   - Once tests pass, replace old page with v2
   - Delete old providers and local state management

3. **Performance:**
   - Use DevTools to verify rebuild counts
   - `.select()` should prevent unnecessary rebuilds
