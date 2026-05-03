import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/features/users/application/services/user_profile_service.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_profile_repository/user_profile_repository.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_profile.dart';

final Provider<UserProfileRepository> userProfileRepositoryProvider =
    Provider<UserProfileRepository>((Ref ref) {
      final dioService = ref.watch(appDioServiceProvider);
      final localizationService = ref.watch(appLocalizationServiceProvider);
      return UserProfileRepository(
        dioService: dioService,
        localizationService: localizationService,
      );
    });

final Provider<UserProfileService> userProfileServiceProvider =
    Provider<UserProfileService>((Ref ref) {
      final repository = ref.watch(userProfileRepositoryProvider);
      return UserProfileService(
        repository: repository,
        logger: AppLogger.instance,
      );
    });

final FutureProvider<UserProfile> currentUserProfileProvider =
    FutureProvider<UserProfile>((Ref ref) async {
      final service = ref.watch(userProfileServiceProvider);
      return service.getCurrentUserProfile();
    });

final Provider<CurrentUserProfileController>
currentUserProfileControllerProvider = Provider<CurrentUserProfileController>((
  Ref ref,
) {
  return CurrentUserProfileController(ref);
});

final class CurrentUserProfileController {
  const CurrentUserProfileController(this._ref);

  final Ref _ref;

  Future<UserProfile> load() {
    return _ref.read(currentUserProfileProvider.future);
  }

  Future<UserProfile> reload() {
    _ref.invalidate(currentUserProfileProvider);
    return _ref.read(currentUserProfileProvider.future);
  }
}
