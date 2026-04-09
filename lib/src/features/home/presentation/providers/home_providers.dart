import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';

final Provider<String> startupEnvironmentLabelProvider = Provider<String>((
  Ref ref,
) {
  final String environment = ref.watch(appConfigProvider).environment.label;
  return 'Environment: $environment';
});
