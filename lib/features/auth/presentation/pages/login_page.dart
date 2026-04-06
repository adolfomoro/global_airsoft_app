import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 900
                ? 520.0
                : double.infinity;
            final isLargeScreen = constraints.maxWidth > 600;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? 24.0 : 4.0,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: _LoginContent(),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginContent extends StatelessWidget {
  const _LoginContent();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'GLOBAL ',
                style: textTheme.headlineSmall?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              TextSpan(
                text: 'AIRSOFT',
                style: textTheme.headlineSmall?.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Acesse sua conta para continuar.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Comunidade global de jogadores, times e eventos.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: AppColors.accentGray),
        ),
        const SizedBox(height: 24),
        Container(
          width: 420,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.outline,
                AppColors.secondary.withValues(alpha: 0.5),
                AppColors.outline,
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: const LoginForm(),
        ),
      ],
    );
  }
}
