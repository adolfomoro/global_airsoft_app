import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/core/widgets/inputs/app_password_input.dart';

import '../../../../core/widgets/index.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/validation/form_validators.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../providers/login_controller.dart';

class _DividerWithText extends StatelessWidget {
  const _DividerWithText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    try {
      await ref
          .read(loginControllerProvider.notifier)
          .login(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
          );
    } catch (_) {
      if (!mounted) {
        return;
      }
      SnackBarHelper.showError(context, 'Falha ao efetuar login.');
      return;
    }

    if (!mounted) {
      return;
    }

    SnackBarHelper.showSuccess(context, 'Login enviado (exemplo).');
  }

  Future<void> _submitGoogle() async {
    try {
      await ref.read(loginControllerProvider.notifier).loginWithGoogle();
    } catch (_) {
      if (!mounted) {
        return;
      }
      SnackBarHelper.showError(context, 'Falha ao efetuar login com Google.');
      return;
    }

    if (!mounted) {
      return;
    }

    SnackBarHelper.showSuccess(context, 'Login com Google acionado (exemplo).');
  }

  void _register() {
    SnackBarHelper.showInfo(context, 'Fluxo de registro em construcao.');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
      loginControllerProvider.select((state) => state.isLoading),
    );
    final loadingSource = ref.watch(
      loginControllerProvider.select((state) => state.loadingSource),
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextInput(
            controller: _usernameController,
            label: 'Usuario',
            hint: 'Digite seu usuario',
            textInputAction: TextInputAction.next,
            validator: FormValidators.validateUsername,
          ),
          AppSpacing.sizedBoxVerticalMd,
          AppPasswordInput(
            controller: _passwordController,
            label: 'Senha',
            hint: 'Digite sua senha',
            textInputAction: TextInputAction.done,
            validator: FormValidators.validatePassword,
          ),
          AppSpacing.sizedBoxVerticalXl,
          AppElevatedButton(
            onPressed: _submit,
            label: 'Entrar',
            isLoading: loadingSource == LoginSource.traditional,
            disabled: isLoading,
          ),
          AppSpacing.sizedBoxVerticalXl,
          const _DividerWithText(text: 'ou'),
          AppSpacing.sizedBoxVerticalXl,
          GoogleSignInButton(
            onPressed: _submitGoogle,
            isLoading: loadingSource == LoginSource.google,
            disabled: isLoading && loadingSource != LoginSource.google,
          ),
          AppSpacing.sizedBoxVerticalMd,
          AppOutlinedButton(
            onPressed: _register,
            label: 'Registrar',
            disabled: isLoading,
          ),
        ],
      ),
    );
  }
}
