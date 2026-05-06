import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';
import 'package:global_airsoft_app/src/core/network/http_status_code_extensions.dart';
import 'package:global_airsoft_app/src/core/network/message_resolution_policy.dart';
import 'package:global_airsoft_app/src/features/users/data/constants/user_account_api_paths.dart';
import 'package:global_airsoft_app/src/features/users/data/exceptions/user_account_exception.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_account_repository/dto/user_account_access_overview_output_dto.dart';

final class UserAccountRepository {
  const UserAccountRepository({
    required AppDioService dioService,
    required AppLocalizationService localizationService,
  }) : _dioService = dioService,
       _localizationService = localizationService;

  final AppDioService _dioService;
  final AppLocalizationService _localizationService;

  Future<String> _accessOverviewLoadFailedMessage() {
    return _localizationService.tr(
      AppLocaleKeys.homeAccountAccessLoadFailedMessage,
    );
  }

  Future<UserAccountAccessOverviewOutputDto>
  getCurrentUserAccessOverview() async {
    try {
      final Response<dynamic> response = await _dioService.get<dynamic>(
        UserAccountApiPaths.currentUserAccessOverview,
      );

      if (response.statusCode.isSuccessStatusCode &&
          response.data is Map<String, dynamic>) {
        return UserAccountAccessOverviewOutputDto.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      await _throwLocalizedFailure(
        failureMessageProvider: _accessOverviewLoadFailedMessage,
      );
    } on AbpApiException catch (error) {
      await _throwLocalizedUserAccountException(error: error);
    } on ApiException catch (error) {
      await _throwLocalizedUserAccountException(error: error);
    } on DioException {
      await _throwLocalizedFailure(
        failureMessageProvider: _accessOverviewLoadFailedMessage,
      );
    }
  }

  Future<Never> _throwLocalizedUserAccountException({
    required ApiException error,
  }) async {
    final String localizedFailureMessage =
        await _accessOverviewLoadFailedMessage();
    final MessageOverrideBehavior overrideBehavior =
        error is ValidationApiException
        ? MessageOverrideBehavior.useAsFallback
        : MessageOverrideBehavior.preferOverride;

    if (error is AbpApiException) {
      throw UserAccountException.fromAbpException(
        error,
        messageOverride: localizedFailureMessage,
        messageOverrideBehavior: overrideBehavior,
      );
    }

    throw UserAccountException.fromApiException(
      error,
      messageOverride: localizedFailureMessage,
      messageOverrideBehavior: overrideBehavior,
    );
  }

  Future<Never> _throwLocalizedFailure({
    required Future<String> Function() failureMessageProvider,
  }) async {
    final String localizedFailureMessage = await failureMessageProvider();

    throw UserAccountException(
      failure: UnknownApiException(message: localizedFailureMessage),
      messageOverride: localizedFailureMessage,
    );
  }
}
