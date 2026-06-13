import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/message_resolution_policy.dart';

final class UserProfileException implements Exception, ApiExceptionSource {
  UserProfileException({
    required this.failure,
    this.messageOverride,
    this.messageOverrideBehavior = MessageOverrideBehavior.useAsFallback,
  });

  final ApiException failure;
  final String? messageOverride;
  final MessageOverrideBehavior messageOverrideBehavior;

  @override
  ApiException get apiException => failure;

  String? get message {
    return failure.resolveMessage(
      overrideMessage: messageOverride,
      overrideBehavior: messageOverrideBehavior,
    );
  }

  factory UserProfileException.fromApiException(
    ApiException error, {
    String? messageOverride,
    MessageOverrideBehavior messageOverrideBehavior =
        MessageOverrideBehavior.useAsFallback,
  }) {
    return UserProfileException(
      failure: error.toTypedException(),
      messageOverride: messageOverride,
      messageOverrideBehavior: messageOverrideBehavior,
    );
  }

  factory UserProfileException.fromAbpException(
    AbpApiException error, {
    String? messageOverride,
    MessageOverrideBehavior messageOverrideBehavior =
        MessageOverrideBehavior.useAsFallback,
  }) {
    return UserProfileException(
      failure: error.toTypedException(),
      messageOverride: messageOverride,
      messageOverrideBehavior: messageOverrideBehavior,
    );
  }

  @override
  String toString() => message ?? '';
}
