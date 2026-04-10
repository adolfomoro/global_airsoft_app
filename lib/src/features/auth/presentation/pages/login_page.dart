import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/widgets/app_button.dart';
import 'package:global_airsoft_app/src/app/widgets/app_text_field.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
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

  String? _validateLogin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Login is required';
    }
    if (value.length < 3) {
      return 'Login must be at least 3 characters';
    }
    if (value.length > 256) {
      return 'Login cannot exceed 256 characters';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    setState(() {
      _loginError = _validateLogin(_loginController.text);
      _passwordError = _validatePassword(_passwordController.text);
      _isLoading = false;
    });

    if (_loginError != null || _passwordError != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthService authService = ref.read(authServiceProvider);
      await authService.login(_loginController.text, _passwordController.text);

      if (mounted) {
        ref.invalidate(isAuthenticatedProvider);
      }
    } on AuthenticationException catch (error) {
      if (mounted) {
        setState(() {
          _loginError = error.message;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      if (mounted) {
        const String message = 'Login failed. Please try again.';
        setState(() {
          _loginError = message;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(message), backgroundColor: Colors.red),
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
              AppTextField(
                labelText: 'Username or Email',
                hintText: 'Enter your login',
                controller: _loginController,
                prefixIcon: const Icon(Icons.person),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              if (_loginError != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _loginError!,
                  style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              AppTextField(
                labelText: 'Password',
                hintText: 'Enter your password',
                controller: _passwordController,
                obscureText: true,
                prefixIcon: const Icon(Icons.lock),
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
              ),
              if (_passwordError != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _passwordError!,
                  style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                ),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: 'Sign In',
                onPressed: _isLoading ? null : _handleLogin,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Sign In with Google',
                onPressed: _isLoading ? null : () {},
                variant: AppButtonVariant.secondary,
                icon: Icons.g_translate,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Don't have an account? ",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : () {},
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
