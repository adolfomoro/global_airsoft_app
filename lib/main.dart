import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app.dart';
import 'package:global_airsoft_app/src/app/bootstrap.dart';

Future<void> main() async {
  await bootstrap(builder: () => const ProviderScope(child: App()));
}
