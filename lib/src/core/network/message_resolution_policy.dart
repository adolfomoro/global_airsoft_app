enum MessageOverrideBehavior { none, useAsFallback, preferOverride }

enum MessageOverrideProtection { allowOverride, lockFailureMessage }

enum MessagePresentationBehavior { featureManaged, alreadyPresentedUpstream }

final class MessageResolutionPolicy {
  const MessageResolutionPolicy({
    this.overrideProtection = MessageOverrideProtection.allowOverride,
    this.presentationBehavior = MessagePresentationBehavior.featureManaged,
  });

  final MessageOverrideProtection overrideProtection;
  final MessagePresentationBehavior presentationBehavior;

  bool get suppressesDuplicatePresentation {
    return presentationBehavior ==
        MessagePresentationBehavior.alreadyPresentedUpstream;
  }

  String? resolve({
    required String failureMessage,
    required bool isFailureFallbackMessage,
    String? overrideMessage,
    MessageOverrideBehavior overrideBehavior =
        MessageOverrideBehavior.useAsFallback,
  }) {
    final String normalizedFailureMessage = failureMessage.trim();
    final String normalizedOverrideMessage = overrideMessage?.trim() ?? '';

    if (overrideProtection == MessageOverrideProtection.lockFailureMessage) {
      if (normalizedFailureMessage.isNotEmpty) {
        return normalizedFailureMessage;
      }

      return normalizedOverrideMessage.isNotEmpty
          ? normalizedOverrideMessage
          : null;
    }

    switch (overrideBehavior) {
      case MessageOverrideBehavior.none:
        if (normalizedFailureMessage.isNotEmpty) {
          return normalizedFailureMessage;
        }

        return normalizedOverrideMessage.isNotEmpty
            ? normalizedOverrideMessage
            : null;
      case MessageOverrideBehavior.useAsFallback:
        final bool hasAuthoritativeFailureMessage =
            normalizedFailureMessage.isNotEmpty && !isFailureFallbackMessage;
        if (hasAuthoritativeFailureMessage) {
          return normalizedFailureMessage;
        }

        if (normalizedOverrideMessage.isNotEmpty) {
          return normalizedOverrideMessage;
        }

        return normalizedFailureMessage.isNotEmpty
            ? normalizedFailureMessage
            : null;
      case MessageOverrideBehavior.preferOverride:
        if (normalizedOverrideMessage.isNotEmpty) {
          return normalizedOverrideMessage;
        }

        return normalizedFailureMessage.isNotEmpty
            ? normalizedFailureMessage
            : null;
    }
  }
}
