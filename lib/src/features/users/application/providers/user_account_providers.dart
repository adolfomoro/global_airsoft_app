import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/features/users/application/providers/current_user_profile_providers.dart';
import 'package:global_airsoft_app/src/features/users/application/services/user_account_service.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_account_repository/user_account_repository.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_account_access_overview.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_profile_privacy_settings.dart';

final Provider<UserAccountRepository> userAccountRepositoryProvider =
    Provider<UserAccountRepository>((Ref ref) {
      final dioService = ref.watch(appDioServiceProvider);
      final localizationService = ref.watch(appLocalizationServiceProvider);
      return UserAccountRepository(
        dioService: dioService,
        localizationService: localizationService,
      );
    });

final Provider<UserAccountService> userAccountServiceProvider =
    Provider<UserAccountService>((Ref ref) {
      final repository = ref.watch(userAccountRepositoryProvider);
      return UserAccountService(repository: repository);
    });

final currentUserPrivacySettingsProvider =
    FutureProvider.autoDispose<UserProfilePrivacySettings>((Ref ref) {
      return ref
          .watch(userProfileServiceProvider)
          .getCurrentUserPrivacySettings();
    });

final currentUserAccountAccessOverviewProvider =
    FutureProvider.autoDispose<UserAccountAccessOverview>((Ref ref) {
      return ref
          .watch(userAccountServiceProvider)
          .getCurrentUserAccessOverview();
    });
