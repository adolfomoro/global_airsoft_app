import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/widgets/app_button.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).logout();
              if (context.mounted) {
                ref.invalidate(isAuthenticatedProvider);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('main', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: AppButton(
                label: 'Logout',
                onPressed: () async {
                  await ref.read(authServiceProvider).logout();
                  if (context.mounted) {
                    ref.invalidate(isAuthenticatedProvider);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
