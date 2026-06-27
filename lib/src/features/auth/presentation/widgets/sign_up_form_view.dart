import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/forms/forms.dart' as app_forms;
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_page_header.dart';
import 'package:global_airsoft_app/src/core/widgets/app_feedback_message.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_button.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_form_padding.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_password_field.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_text_field.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/controllers/sign_up_form_controller.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/password_requirements_hint.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/username_availability_field.dart';

class SignUpFormView extends ConsumerStatefulWidget {
  const SignUpFormView({super.key});

  @override
  ConsumerState<SignUpFormView> createState() => _SignUpFormViewState();
}

class _SignUpFormViewState extends ConsumerState<SignUpFormView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      signUpFormControllerProvider.select((state) => state.generalError),
      (String? previous, String? next) {
        if (next == null || next.isEmpty || next == previous) {
          return;
        }

        _scrollToTop();
      },
    );

    return SingleChildScrollView(
      controller: _scrollController,
      child: AutofillGroup(
        child: AppFormPadding(
          padding: AppFormPadding.standardScrollablePagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: AppDimensions.spacingXl),
              const _SignUpHeaderSection(),
              const SizedBox(height: AppDimensions.spacingXl),
              const _FormErrorMessage(),
              const _FullNameInput(),
              const SizedBox(height: AppDimensions.spacingLg),
              const _UsernameInput(),
              const SizedBox(height: AppDimensions.spacingLg),
              const _EmailInput(),
              const SizedBox(height: AppDimensions.spacingLg),
              const _PasswordInput(),
              const SizedBox(height: AppDimensions.spacingLg),
              const _ConfirmPasswordInput(),
              const SizedBox(height: AppDimensions.spacingXl),
              _SubmitButton(onSubmit: _submit),
              const SizedBox(height: AppDimensions.spacingMd),
              const _BackToLoginButton(),
              const SizedBox(height: AppDimensions.spacingXl),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref.read(signUpFormControllerProvider.notifier).submit();
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }
}

class _SignUpHeaderSection extends StatelessWidget {
  const _SignUpHeaderSection();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return AppPageHeader(
      title: context.l10n.tr(AppLocaleKeys.authSignUpHeading),
      subtitle: context.l10n.tr(AppLocaleKeys.authSignUpSubtitle),
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      leading: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Icon(
              Icons.person_add_alt_1_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'GA',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormErrorMessage extends ConsumerWidget {
  const _FormErrorMessage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? generalError = ref.watch(
      signUpFormControllerProvider.select((state) => state.generalError),
    );

    if (generalError == null || generalError.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingLg),
      child: AppFeedbackMessage.error(
        message: generalError
      ),
    );
  }
}

class _FullNameInput extends ConsumerStatefulWidget {
  const _FullNameInput();

  @override
  ConsumerState<_FullNameInput> createState() => _FullNameInputState();
}

class _FullNameInputState extends ConsumerState<_FullNameInput> {
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
      signUpFormControllerProvider.select((state) => state.fullName),
    );
    final bool wasSubmitted = ref.watch(
      signUpFormControllerProvider.select((state) => state.wasSubmitted),
    );
    final bool enabled = !ref.watch(
      signUpFormControllerProvider.select((state) => state.isSubmitting),
    );

    _syncControllerValue(_controller, field.value);

    return AppTextField(
      labelText: context.l10n.tr(AppLocaleKeys.authFullNameLabel),
      controller: _controller,
      errorText: _fieldErrorText(field, wasSubmitted),
      enabled: enabled,
      isRequired: true,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.name],
      textCapitalization: TextCapitalization.words,
      onChanged: ref.read(signUpFormControllerProvider.notifier).updateFullName,
    );
  }
}

class _UsernameInput extends ConsumerStatefulWidget {
  const _UsernameInput();

  @override
  ConsumerState<_UsernameInput> createState() => _UsernameInputState();
}

class _UsernameInputState extends ConsumerState<_UsernameInput> {
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
      signUpFormControllerProvider.select((state) => state.username),
    );
    final bool wasSubmitted = ref.watch(
      signUpFormControllerProvider.select((state) => state.wasSubmitted),
    );
    final bool enabled = !ref.watch(
      signUpFormControllerProvider.select((state) => state.isSubmitting),
    );

    _syncControllerValue(_controller, field.value);

    return UsernameAvailabilityField(
      controller: _controller,
      errorText: _fieldErrorText(field, wasSubmitted),
      enabled: enabled,
      onChanged: ref.read(signUpFormControllerProvider.notifier).updateUsername,
      onAvailabilityChanged: ref
          .read(signUpFormControllerProvider.notifier)
          .updateUsernameAvailabilityStatus,
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
      signUpFormControllerProvider.select((state) => state.email),
    );
    final bool wasSubmitted = ref.watch(
      signUpFormControllerProvider.select((state) => state.wasSubmitted),
    );
    final bool enabled = !ref.watch(
      signUpFormControllerProvider.select((state) => state.isSubmitting),
    );

    _syncControllerValue(_controller, field.value);

    return AppTextField(
      labelText: context.l10n.tr(AppLocaleKeys.authEmailLabel),
      controller: _controller,
      errorText: _fieldErrorText(field, wasSubmitted),
      enabled: enabled,
      isRequired: true,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.email],
      onChanged: ref.read(signUpFormControllerProvider.notifier).updateEmail,
    );
  }
}

class _PasswordInput extends ConsumerStatefulWidget {
  const _PasswordInput();

  @override
  ConsumerState<_PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends ConsumerState<_PasswordInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = ref.watch(
      signUpFormControllerProvider.select((state) => state.password),
    );
    final bool wasSubmitted = ref.watch(
      signUpFormControllerProvider.select((state) => state.wasSubmitted),
    );
    final bool enabled = !ref.watch(
      signUpFormControllerProvider.select((state) => state.isSubmitting),
    );

    _syncControllerValue(_controller, field.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppPasswordField(
          labelText: context.l10n.tr(AppLocaleKeys.authPasswordLabel),
          controller: _controller,
          focusNode: _focusNode,
          errorText: _fieldErrorText(field, wasSubmitted),
          enabled: enabled,
          isRequired: true,
          textInputAction: TextInputAction.next,
          autofillHints: const <String>[AutofillHints.newPassword],
          onChanged: (String value) {
            ref
                .read(signUpFormControllerProvider.notifier)
                .updatePassword(value);
          },
        ),
        ListenableBuilder(
          listenable: _focusNode,
          builder: (BuildContext context, Widget? _) {
            return PasswordRequirementsHint(
              currentPassword: field.value,
              isFocused: _focusNode.hasFocus,
            );
          },
        ),
      ],
    );
  }
}

class _ConfirmPasswordInput extends ConsumerStatefulWidget {
  const _ConfirmPasswordInput();

  @override
  ConsumerState<_ConfirmPasswordInput> createState() =>
      _ConfirmPasswordInputState();
}

class _ConfirmPasswordInputState extends ConsumerState<_ConfirmPasswordInput> {
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
      signUpFormControllerProvider.select((state) => state.confirmPassword),
    );
    final bool wasSubmitted = ref.watch(
      signUpFormControllerProvider.select((state) => state.wasSubmitted),
    );
    final bool isSubmitting = ref.watch(
      signUpFormControllerProvider.select((state) => state.isSubmitting),
    );

    _syncControllerValue(_controller, field.value);

    return AppPasswordField(
      labelText: context.l10n.tr(AppLocaleKeys.authConfirmPasswordLabel),
      controller: _controller,
      errorText: _fieldErrorText(field, wasSubmitted),
      enabled: !isSubmitting,
      textInputAction: TextInputAction.send,
      autofillHints: const <String>[AutofillHints.newPassword],
      onChanged: (String value) {
        ref
            .read(signUpFormControllerProvider.notifier)
            .updateConfirmPassword(value);
      },
      onFieldSubmitted: (_) {
        if (!isSubmitting) {
          ref.read(signUpFormControllerProvider.notifier).submit();
        }
      },
    );
  }
}

class _SubmitButton extends ConsumerWidget {
  const _SubmitButton({required this.onSubmit});

  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool canSubmit = ref.watch(
      signUpFormControllerProvider.select((state) => state.canSubmit),
    );
    final bool isSubmitting = ref.watch(
      signUpFormControllerProvider.select((state) => state.isSubmitting),
    );

    return AppButton(
      label: context.l10n.tr(AppLocaleKeys.authSignUpAction),
      onPressed: canSubmit ? onSubmit : null,
      isLoading: isSubmitting,
    );
  }
}

class _BackToLoginButton extends ConsumerWidget {
  const _BackToLoginButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSubmitting = ref.watch(
      signUpFormControllerProvider.select((state) => state.isSubmitting),
    );

    return Center(
      child: TextButton(
        onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
        child: Text(context.l10n.tr(AppLocaleKeys.authBackToLoginAction)),
      ),
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
