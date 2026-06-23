import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:global_airsoft_app/src/app/routing/app_route_paths.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/forms/forms.dart' as app_forms;
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_page_header.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_button.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_form_padding.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/controllers/login_form_controller.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/app_login_field.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/app_password_field.dart';

class LoginFormView extends ConsumerStatefulWidget {
  const LoginFormView({super.key});

  @override
  ConsumerState<LoginFormView> createState() => _LoginFormViewState();
}

class _LoginFormViewState extends ConsumerState<LoginFormView> {
  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      loginFormControllerProvider.select((state) => state.generalError),
      (String? previous, String? next) {
        if (next == null || next == previous || !context.mounted) {
          return;
        }

        context.showErrorSnackBar(next);
      },
    );

    return SingleChildScrollView(
      child: Form(
        child: AutofillGroup(
          child: AppFormPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: AppDimensions.spacingXl),
                const _LoginHeaderSection(),
                const SizedBox(height: 40),
                const _LoginInput(),
                const SizedBox(height: 16),
                const _PasswordInput(),
                const Align(
                  alignment: Alignment.centerRight,
                  child: _ForgotPasswordButton(),
                ),
                const SizedBox(height: AppDimensions.spacingXl),
                _SubmitButton(onSubmit: _submitCredentials),
                const SizedBox(height: 12),
                _GoogleSignInButton(onSubmit: _submitGoogle),
                const SizedBox(height: 18),
                const _SignUpLinkSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitCredentials() async {
    FocusScope.of(context).unfocus();
    await ref.read(loginFormControllerProvider.notifier).submitCredentials();
  }

  Future<void> _submitGoogle() async {
    FocusScope.of(context).unfocus();

    final GoogleAccountSetupNavigationData? navigationData = await ref
        .read(loginFormControllerProvider.notifier)
        .submitGoogle();

    if (!mounted || navigationData == null) {
      return;
    }

    await Navigator.of(context).pushNamed(
      AppRoutePaths.googleAccountSetup,
      arguments: (
        challengeToken: navigationData.challengeToken,
        profilePictureUrl: navigationData.profilePictureUrl,
        profileName: navigationData.profileName,
      ),
    );
  }
}

class _LoginHeaderSection extends StatelessWidget {
  const _LoginHeaderSection();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const SizedBox(height: 40),
        AppPageHeader(
          title: context.l10n.tr(AppLocaleKeys.appTitle),
          subtitle: context.l10n.tr(AppLocaleKeys.authLoginSubtitle),
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
                  Icons.track_changes_rounded,
                  color: colorScheme.primary,
                  size: 30,
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
        ),
      ],
    );
  }
}

class _LoginInput extends ConsumerStatefulWidget {
  const _LoginInput();

  @override
  ConsumerState<_LoginInput> createState() => _LoginInputState();
}

class _LoginInputState extends ConsumerState<_LoginInput> {
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
      loginFormControllerProvider.select((state) => state.login),
    );
    final bool wasSubmitted = ref.watch(
      loginFormControllerProvider.select((state) => state.wasSubmitted),
    );
    final bool enabled = !ref.watch(
      loginFormControllerProvider.select((state) => state.isSubmitting),
    );

    _syncControllerValue(_controller, field.value);

    return AppLoginField(
      controller: _controller,
      errorText: _fieldErrorText(field, wasSubmitted),
      enabled: enabled,
      isRequired: true,
      onChanged: ref.read(loginFormControllerProvider.notifier).updateLogin,
      onFieldSubmitted: (_) {
        FocusScope.of(context).nextFocus();
      },
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
      loginFormControllerProvider.select((state) => state.password),
    );
    final bool wasSubmitted = ref.watch(
      loginFormControllerProvider.select((state) => state.wasSubmitted),
    );
    final bool enabled = !ref.watch(
      loginFormControllerProvider.select((state) => state.isSubmitting),
    );

    _syncControllerValue(_controller, field.value);

    return AppPasswordField(
      labelText: context.l10n.tr(AppLocaleKeys.authPasswordLabel),
      controller: _controller,
      errorText: _fieldErrorText(field, wasSubmitted),
      enabled: enabled,
      isRequired: true,
      autofillHints: const <String>[AutofillHints.password],
      onChanged: ref.read(loginFormControllerProvider.notifier).updatePassword,
      onFieldSubmitted: (_) {
        if (enabled) {
          _submit(context);
        }
      },
    );
  }

  Future<void> _submit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    await ref.read(loginFormControllerProvider.notifier).submitCredentials();
  }
}

class _ForgotPasswordButton extends ConsumerWidget {
  const _ForgotPasswordButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSubmitting = ref.watch(
      loginFormControllerProvider.select((state) => state.isSubmitting),
    );

    return TextButton(
      onPressed: isSubmitting
          ? null
          : () {
              Navigator.of(context).pushNamed(AppRoutePaths.passwordRecovery);
            },
      child: Text(context.l10n.tr(AppLocaleKeys.authForgotPasswordAction)),
    );
  }
}

class _SubmitButton extends ConsumerWidget {
  const _SubmitButton({required this.onSubmit});

  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool canSubmit = ref.watch(
      loginFormControllerProvider.select((state) => state.canSubmitCredentials),
    );
    final bool isSubmitting = ref.watch(
      loginFormControllerProvider.select(
        (state) => state.isCredentialsSubmitting,
      ),
    );

    return AppButton(
      label: context.l10n.tr(AppLocaleKeys.authSignInAction),
      onPressed: canSubmit ? onSubmit : null,
      isLoading: isSubmitting,
    );
  }
}

class _GoogleSignInButton extends ConsumerWidget {
  const _GoogleSignInButton({required this.onSubmit});

  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool canSubmit = ref.watch(
      loginFormControllerProvider.select((state) => state.canSubmitGoogle),
    );
    final bool isSubmitting = ref.watch(
      loginFormControllerProvider.select((state) => state.isGoogleSubmitting),
    );

    return AppButton(
      label: context.l10n.tr(AppLocaleKeys.authGoogleContinueAction),
      onPressed: canSubmit ? onSubmit : null,
      variant: AppButtonVariant.secondary,
      iconWidget: const FaIcon(FontAwesomeIcons.google),
      isLoading: isSubmitting,
    );
  }
}

class _SignUpLinkSection extends ConsumerWidget {
  const _SignUpLinkSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSubmitting = ref.watch(
      loginFormControllerProvider.select((state) => state.isSubmitting),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          context.l10n.tr(AppLocaleKeys.authLoginNoAccount),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: isSubmitting
              ? null
              : () {
                  Navigator.of(context).pushNamed(AppRoutePaths.signUp);
                },
          child: Text(context.l10n.tr(AppLocaleKeys.authSignUpAction)),
        ),
      ],
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
