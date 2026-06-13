import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/features/files/application/services/direct_file_upload_service.dart';
import 'package:global_airsoft_app/src/features/files/data/repositories/direct_file_upload_repository.dart';

final Provider<DirectFileUploadRepository> directFileUploadRepositoryProvider =
    Provider<DirectFileUploadRepository>((Ref ref) {
      return DirectFileUploadRepository(
        storageClient: ref.watch(externalDioClientProvider),
      );
    });

final Provider<DirectFileUploadService> directFileUploadServiceProvider =
    Provider<DirectFileUploadService>((Ref ref) {
      return DirectFileUploadService(
        repository: ref.watch(directFileUploadRepositoryProvider),
      );
    });
