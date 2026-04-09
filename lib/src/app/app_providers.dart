import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';

final Provider<AppConfig> appConfigProvider = Provider<AppConfig>(
  (Ref ref) => AppConfig.fromDartDefines(),
);

final Provider<AppDioService> appDioServiceProvider = Provider<AppDioService>((
  Ref ref,
) {
  final AppConfig config = ref.watch(appConfigProvider);
  return AppDioService.create(config: config, logger: AppLogger.instance);
});

final Provider<Dio> appDioClientProvider = Provider<Dio>(
  (Ref ref) => ref.watch(appDioServiceProvider).client,
);
