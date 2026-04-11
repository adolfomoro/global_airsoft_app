import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/widgets/app_button.dart';
import 'package:global_airsoft_app/src/app/widgets/app_google_sign_in_button.dart';
import 'package:global_airsoft_app/src/app/widgets/app_login_field.dart';
import 'package:global_airsoft_app/src/app/widgets/app_password_field.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/validation/backend_validation_error_mapper.dart';
import 'package:global_airsoft_app/src/core/validation/validation.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/user_login_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const BackendValidationErrorMapper _validationErrorMapper =
      BackendValidationErrorMapper();
  static const ValidationRuleSet _loginValidationRules =
      ValidationRuleSet(<ValidationRule>[
        RequiredValidationRule(),
        MinLengthValidationRule(3),
        MaxLengthValidationRule(256),
      ]);
  static const ValidationRuleSet _passwordValidationRules = ValidationRuleSet(
    <ValidationRule>[RequiredValidationRule()],
  );
  static void _noopAction() {}

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _loginController;
  late TextEditingController _passwordController;
  String? _loginError;
  String? _passwordError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loginController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLoginChanged(String _) {
    if (_loginError == null) {
      return;
    }

    setState(() {
      _loginError = null;
    });
  }

  void _handlePasswordChanged(String _) {
    if (_passwordError == null) {
      return;
    }

    setState(() {
      _passwordError = null;
    });
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loginError = null;
      _passwordError = null;
    });

    final FormState? formState = _formKey.currentState;
    if (!(formState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthService authService = ref.read(authServiceProvider);
      await authService.login(_loginController.text, _passwordController.text);

      if (mounted) {
        ref.read(isAuthenticatedProvider.notifier).setAuthenticated();
      }
    } on AuthenticationException catch (error) {
      if (mounted) {
        final ValidationMappingResult mappedErrors = _validationErrorMapper.map(
          exception: error.failure,
          targetFields: const <String>{
            UserLoginInputDto.loginField,
            UserLoginInputDto.passwordField,
          },
          memberAliases: const <String, String>{
            UserLoginInputDto.loginField: UserLoginInputDto.loginField,
            UserLoginInputDto.passwordField: UserLoginInputDto.passwordField,
          },
        );

        final String? mappedLoginError =
            mappedErrors.fieldErrors[UserLoginInputDto.loginField];
        final String? mappedPasswordError =
            mappedErrors.fieldErrors[UserLoginInputDto.passwordField];
        setState(() {
          _loginError = mappedLoginError;
          _passwordError = mappedPasswordError;
        });

        final String fallbackMessage = context.l10n.tr(
          AppLocaleKeys.authLoginFailed,
        );
        final String message = error.message ?? fallbackMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.tr(AppLocaleKeys.authLoginFailed)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 48),
                Text(
                  'Sign In',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AppLoginField(
                  controller: _loginController,
                  errorText: _loginError,
                  onChanged: _handleLoginChanged,
                  isRequired: _loginValidationRules.hasRequiredRule,
                  validator: _loginValidationRules.asValidator(
                    (ValidationFailure failure) => context.l10n.trArgs(
                      failure.messageKey,
                      args: failure.arguments,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppPasswordField(
                  controller: _passwordController,
                  errorText: _passwordError,
                  onChanged: _handlePasswordChanged,
                  isRequired: _passwordValidationRules.hasRequiredRule,
                  validator: _passwordValidationRules.asValidator(
                    (ValidationFailure failure) => context.l10n.trArgs(
                      failure.messageKey,
                      args: failure.arguments,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Sign In',
                  onPressed: _isLoading ? null : _handleLogin,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
                AppGoogleSignInButton(
                  onPressed: _isLoading ? null : _noopAction,
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: 'Sign Up',
                  variant: AppButtonVariant.secondary,
                  onPressed: _isLoading ? null : _noopAction,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
