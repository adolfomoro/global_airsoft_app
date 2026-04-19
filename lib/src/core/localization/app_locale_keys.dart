abstract final class AppLocaleKeys {
  static String withPluralSuffix({
    required String baseKey,
    required bool isSingular,
  }) {
    final String suffix = isSingular ? 'one' : 'other';
    return '$baseKey.$suffix';
  }

  static const String appTitle = 'app.title';
  static const String appStartupFailedTitle = 'app.startupFailedTitle';
  static const String appStartupFailedMessage = 'app.startupFailedMessage';
  static const String homeTitle = 'home.title';
  static const String homeMainLabel = 'home.mainLabel';
  static const String homeLogoutAction = 'home.logoutAction';
  static const String deviceRegistrationFailed = 'device.registrationFailed';
  static const String deviceRegistrationEmptyResponse =
      'device.registrationEmptyResponse';
  static const String deviceRegistrationInvalidPayloadFormat =
      'device.registrationInvalidPayloadFormat';
  static const String authLoginTitle = 'auth.loginTitle';
  static const String authLoginSubtitle = 'auth.loginSubtitle';
  static const String authLoginIdentifierLabel = 'auth.loginIdentifierLabel';
  static const String authLoginNoAccount = 'auth.loginNoAccount';
  static const String authGoogleContinueAction = 'auth.googleContinueAction';
  static const String authForgotPasswordAction = 'auth.forgotPasswordAction';
  static const String authSignInAction = 'auth.signInAction';
  static const String authGoogleSignInFailed = 'auth.googleSignInFailed';
  static const String authPasswordRecoveryTitle = 'auth.passwordRecoveryTitle';
  static const String authPasswordRecoveryHeading =
      'auth.passwordRecoveryHeading';
  static const String authPasswordRecoverySubtitle =
      'auth.passwordRecoverySubtitle';
  static const String authPasswordRecoverySendAction =
      'auth.passwordRecoverySendAction';
  static const String authPasswordRecoverySuccessTitle =
      'auth.passwordRecoverySuccessTitle';
  static const String authPasswordRecoverySuccessMessage =
      'auth.passwordRecoverySuccessMessage';
  static const String authSignUpHeading = 'auth.signUpHeading';
  static const String authSignUpSubtitle = 'auth.signUpSubtitle';
  static const String authSignUpAction = 'auth.signUpAction';
  static const String authBackToLoginAction = 'auth.backToLoginAction';
  static const String authFullNameLabel = 'auth.fullNameLabel';
  static const String authUsernameLabel = 'auth.usernameLabel';
  static const String authGoogleAccountSetupTitle =
      'auth.googleAccountSetupTitle';
  static const String authGoogleAccountSetupSubtitle =
      'auth.googleAccountSetupSubtitle';
  static const String authPasswordLabel = 'auth.passwordLabel';
  static const String authEmailLabel = 'auth.emailLabel';
  static const String authUsernameRestrictionHint =
      'auth.usernameRestrictionHint';
  static const String authConfirmPasswordLabel = 'auth.confirmPasswordLabel';
  static const String authConfirmPasswordRequired =
      'auth.confirmPasswordRequired';
  static const String authConfirmPasswordMismatch =
      'auth.confirmPasswordMismatch';
  static const String authPasswordRulesTitle = 'auth.passwordRulesTitle';
  static const String authPasswordRulesMinimumLength =
      'auth.passwordRulesMinimumLength';
  static const String authPasswordRulesLetterAndNumber =
      'auth.passwordRulesLetterAndNumber';
  static const String authPasswordRulesSpecialCharacter =
      'auth.passwordRulesSpecialCharacter';
  static const String authLoginFailed = 'auth.loginFailed';
  static const String authSignUpFailed = 'auth.signUpFailed';
  static const String authPasswordRecoveryFailed =
      'auth.passwordRecoveryFailed';
  static const String notificationPermissionPrePromptTitle =
      'notification.permissionPrePromptTitle';
  static const String notificationPermissionPrePromptSubtitle =
      'notification.permissionPrePromptSubtitle';
  static const String
  notificationPermissionPrePromptBenefitFriendRequestsTitle =
      'notification.permissionPrePromptBenefitFriendRequestsTitle';
  static const String
  notificationPermissionPrePromptBenefitFriendRequestsDescription =
      'notification.permissionPrePromptBenefitFriendRequestsDescription';
  static const String notificationPermissionPrePromptBenefitGamesTitle =
      'notification.permissionPrePromptBenefitGamesTitle';
  static const String notificationPermissionPrePromptBenefitGamesDescription =
      'notification.permissionPrePromptBenefitGamesDescription';
  static const String notificationPermissionPrePromptBenefitTeamsTitle =
      'notification.permissionPrePromptBenefitTeamsTitle';
  static const String notificationPermissionPrePromptBenefitTeamsDescription =
      'notification.permissionPrePromptBenefitTeamsDescription';
  static const String notificationPermissionAllow =
      'notification.permissionAllow';
  static const String notificationPermissionDismiss =
      'notification.permissionDismiss';
  static const String notificationPermissionDeniedTitle =
      'notification.permissionDeniedTitle';
  static const String notificationPermissionDeniedBody =
      'notification.permissionDeniedBody';
  static const String notificationPermissionOpenSettings =
      'notification.permissionOpenSettings';
  static const String notificationPermissionError =
      'notification.permissionError';
  static const String notificationChannelMessages =
      'notification.channel.messages';
  static const String notificationChannelMessagesDescription =
      'notification.channel.messagesDescription';
  static const String notificationChannelSocial = 'notification.channel.social';
  static const String notificationChannelSocialDescription =
      'notification.channel.socialDescription';
  static const String notificationChannelOthers = 'notification.channel.others';
  static const String notificationChannelOthersDescription =
      'notification.channel.othersDescription';
  static const String notificationPermissionStatus =
      'notification.permissionStatus';
  static const String validationRequired = 'validation.required';
  static const String validationMinLength = 'validation.minLength';
  static const String validationMaxLength = 'validation.maxLength';
  static const String validationPattern = 'validation.pattern';
  static const String validationFullNameComplete =
      'validation.fullNameComplete';
  static const String validationPasswordLetterAndNumber =
      'validation.passwordLetterAndNumber';
  static const String validationPasswordSpecialCharacter =
      'validation.passwordSpecialCharacter';
  static const String validationUsernameLowercaseOnly =
      'validation.usernameLowercaseOnly';
  static const String commonShowPassword = 'common.showPassword';
  static const String commonHidePassword = 'common.hidePassword';
}
