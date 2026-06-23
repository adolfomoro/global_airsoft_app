import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/routing/app_route_paths.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/forms/forms.dart' as app_forms;
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_button.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_form_padding.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_text_field.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/controllers/password_recovery_form_controller.dart';

class PasswordRecoveryFormView extends ConsumerStatefulWidget {
  const PasswordRecoveryFormView({super.key});

  @override
  ConsumerState<PasswordRecoveryFormView> createState() =>
      _PasswordRecoveryFormViewState();
}

class _PasswordRecoveryFormViewState
    extends ConsumerState<PasswordRecoveryFormView> {
  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      passwordRecoveryFormControllerProvider.select(
        (state) => state.generalError,
      ),
      (String? previous, String? next) {
        if (next == null || next == previous || !context.mounted) {
          return;
        }

        context.showErrorSnackBar(next);
      },
    );

    return SingleChildScrollView(
      child: AppFormPadding(
        padding: AppFormPadding.standardScrollablePagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: AppDimensions.spacingXl),
            const _EmailInput(),
            const SizedBox(height: AppDimensions.spacingXl),
            _SubmitButton(onSubmit: _submit),
            const SizedBox(height: AppDimensions.spacingXl),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final String? email = await ref
        .read(passwordRecoveryFormControllerProvider.notifier)
        .submit();

    if (!mounted || email == null) {
      return;
    }

    await Navigator.of(context).pushReplacementNamed(
      AppRoutePaths.passwordRecoverySuccess,
      arguments: email,
    );
  }
}

class _EmailInput extends ConsumerStatefulWidget {
  const _EmailInput();

  @override
  ConsumerState<_EmailInput> createState() => _EmailInputState();
}

class _EmailInputState extends ConsumerState<_EmailInput> {
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
    final field = ref.watch(
      passwordRecoveryFormControllerProvider.select((state) => state.email),
    );
    final bool wasSubmitted = ref.watch(
      passwordRecoveryFormControllerProvider.select(
        (state) => state.wasSubmitted,
      ),
    );
    final bool enabled = !ref.watch(
      passwordRecoveryFormControllerProvider.select(
        (state) => state.isSubmitting,
      ),
    );

    _syncControllerValue(_controller, field.value);

    return AppTextField(
      labelText: context.l10n.tr(AppLocaleKeys.authEmailLabel),
      controller: _controller,
      errorText: _fieldErrorText(field, wasSubmitted),
      enabled: enabled,
      onChanged: ref
          .read(passwordRecoveryFormControllerProvider.notifier)
          .updateEmail,
      onFieldSubmitted: (_) {
        if (enabled) {
          _submit();
        }
      },
      isRequired: true,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.send,
      autofillHints: const <String>[AutofillHints.email],
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final String? email = await ref
        .read(passwordRecoveryFormControllerProvider.notifier)
        .submit();

    if (!mounted || email == null) {
      return;
    }

    await Navigator.of(context).pushReplacementNamed(
      AppRoutePaths.passwordRecoverySuccess,
      arguments: email,
    );
  }
}

class _SubmitButton extends ConsumerWidget {
  const _SubmitButton({required this.onSubmit});

  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool canSubmit = ref.watch(
      passwordRecoveryFormControllerProvider.select((state) => state.canSubmit),
    );
    final bool isSubmitting = ref.watch(
      passwordRecoveryFormControllerProvider.select(
        (state) => state.isSubmitting,
      ),
    );

    return AppButton(
      label: context.l10n.tr(AppLocaleKeys.authPasswordRecoverySendAction),
      onPressed: canSubmit ? onSubmit : null,
      isLoading: isSubmitting,
    );
  }
}

void _syncControllerValue(TextEditingController controller, String value) {
  if (controller.text == value) {
    return;
  }

  controller.value = controller.value.copyWith(
    text: value,
    selection: TextSelection.collapsed(offset: value.length),
    composing: TextRange.empty,
  );
}

String? _fieldErrorText(
  app_forms.FormFieldState<String> field,
  bool wasSubmitted,
) {
  if (field.error == null) {
    return null;
  }

  return field.shouldShowError || wasSubmitted ? field.error : null;
}
