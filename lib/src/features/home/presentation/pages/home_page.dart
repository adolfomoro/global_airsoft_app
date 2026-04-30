import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/widgets/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/app/widgets/app_button.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isLogoutLoading = false;

  Future<void> _submitLogout() async {
    if (_isLogoutLoading) {
      return;
    }

    setState(() {
      _isLogoutLoading = true;
    });

    try {
      await ref.read(authServiceProvider).logout();
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Logout failed.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }

      final String fallbackMessage = context.l10n.tr(
        AppLocaleKeys.homeLogoutErrorMessage,
      );
      final String message = error is AuthenticationException
          ? (error.message ?? fallbackMessage)
          : fallbackMessage;
      context.showErrorSnackBar(message, source: error);
    } finally {
      if (mounted) {
        setState(() {
          _isLogoutLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(context.l10n.tr(AppLocaleKeys.homeTitle)),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isLogoutLoading ? null : _submitLogout,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              context.l10n.tr(AppLocaleKeys.homeMainLabel),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: AppButton(
                label: context.l10n.tr(AppLocaleKeys.homeLogoutAction),
                onPressed: _isLogoutLoading ? null : _submitLogout,
                isLoading: _isLogoutLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
