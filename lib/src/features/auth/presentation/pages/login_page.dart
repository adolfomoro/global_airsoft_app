import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/app_gradient_background.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/login_form_view.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AppGradientBackground(
        animateOnFirstBuild: true,
        animationId: 'login-page-initial-background-fade',
        child: SafeArea(child: const LoginFormView()),
      ),
    );
  }
}
