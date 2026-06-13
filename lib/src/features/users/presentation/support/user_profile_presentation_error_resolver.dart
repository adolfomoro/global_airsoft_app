import 'package:flutter/widgets.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/message_resolution_policy.dart';
import 'package:global_airsoft_app/src/features/users/data/exceptions/user_profile_exception.dart';

String resolveUserProfilePresentationErrorMessage(
  BuildContext context,
  Object error,
) {
  if (error is UserProfileException) {
    return error.message ??
        context.l10n.tr(AppLocaleKeys.homeProfileLoadFailedMessage);
  }

  if (error is ApiExceptionSource) {
    return error.apiException.resolveMessage(
          overrideMessage: context.l10n.tr(
            AppLocaleKeys.homeProfileLoadFailedMessage,
          ),
          overrideBehavior: MessageOverrideBehavior.useAsFallback,
        ) ??
        context.l10n.tr(AppLocaleKeys.homeProfileLoadFailedMessage);
  }

  return context.l10n.tr(AppLocaleKeys.homeProfileLoadFailedMessage);
}
