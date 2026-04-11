abstract final class AppLocaleKeys {
  static String withPluralSuffix({
    required String baseKey,
    required bool isSingular,
  }) {
    final String suffix = isSingular ? 'one' : 'other';
    return '$baseKey.$suffix';
  }

  static const String appTitle = 'app.title';
  static const String homeTitle = 'home.title';
  static const String homeMainLabel = 'home.mainLabel';
  static const String homeLogoutAction = 'home.logoutAction';
  static const String authLoginTitle = 'auth.loginTitle';
  static const String authLoginSubtitle = 'auth.loginSubtitle';
  static const String authLoginContinueWith = 'auth.loginContinueWith';
    static const String authLoginIdentifierLabel = 'auth.loginIdentifierLabel';
  static const String authLoginNoAccount = 'auth.loginNoAccount';
  static const String authLoginSignUpAction = 'auth.loginSignUpAction';
  static const String authForgotPasswordAction = 'auth.forgotPasswordAction';
  static const String authSignInAction = 'auth.signInAction';
    static const String authSignInWithGoogle = 'auth.signInWithGoogle';
  static const String authPasswordRecoveryTitle = 'auth.passwordRecoveryTitle';
  static const String authPasswordRecoveryHeading =
      'auth.passwordRecoveryHeading';
  static const String authPasswordRecoverySubtitle =
      'auth.passwordRecoverySubtitle';
  static const String authPasswordRecoveryEmailLabel =
      'auth.passwordRecoveryEmailLabel';
  static const String authPasswordRecoveryEmailHint =
      'auth.passwordRecoveryEmailHint';
  static const String authPasswordRecoverySendAction =
      'auth.passwordRecoverySendAction';
  static const String authPasswordRecoverySuccessTitle =
      'auth.passwordRecoverySuccessTitle';
  static const String authPasswordRecoverySuccessMessage =
      'auth.passwordRecoverySuccessMessage';
  static const String authPasswordRecoverySuccessBackToLoginAction =
      'auth.passwordRecoverySuccessBackToLoginAction';
  static const String authSignUpTitle = 'auth.signUpTitle';
  static const String authSignUpHeading = 'auth.signUpHeading';
  static const String authSignUpSubtitle = 'auth.signUpSubtitle';
  static const String authSignUpAction = 'auth.signUpAction';
  static const String authBackToLoginAction = 'auth.backToLoginAction';
  static const String authUserNameLabel = 'auth.userNameLabel';
  static const String authUserNameHint = 'auth.userNameHint';
  static const String authPasswordLabel = 'auth.passwordLabel';
  static const String authEmailLabel = 'auth.emailLabel';
  static const String authEmailHint = 'auth.emailHint';
  static const String authUserNameRestrictionHint =
      'auth.userNameRestrictionHint';
  static const String authConfirmPasswordLabel = 'auth.confirmPasswordLabel';
  static const String authConfirmPasswordRequired =
      'auth.confirmPasswordRequired';
  static const String authConfirmPasswordMismatch =
      'auth.confirmPasswordMismatch';
  static const String authPasswordRulesTitle = 'auth.passwordRulesTitle';
  static const String authPasswordRulesLoading = 'auth.passwordRulesLoading';
  static const String authPasswordRulesMinimumLength =
      'auth.passwordRulesMinimumLength';
  static const String authPasswordRulesUniqueCharacters =
      'auth.passwordRulesUniqueCharacters';
  static const String authPasswordRulesRequireDigit =
      'auth.passwordRulesRequireDigit';
  static const String authPasswordRulesRequireLowercase =
      'auth.passwordRulesRequireLowercase';
  static const String authPasswordRulesRequireUppercase =
      'auth.passwordRulesRequireUppercase';
  static const String authPasswordRulesRequireNonAlphanumeric =
      'auth.passwordRulesRequireNonAlphanumeric';
  static const String authPasswordRulesNoAdditionalRequirements =
      'auth.passwordRulesNoAdditionalRequirements';
  static const String authPasswordRulesFailed = 'auth.passwordRulesFailed';
  static const String authPasswordRequirementsNotMet =
      'auth.passwordRequirementsNotMet';
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
  static const String notificationPermissionOpenSettingsDismiss =
      'notification.permissionOpenSettingsDismiss';
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
  static const String validationPasswordMinimumLength =
      'validation.passwordMinimumLength';
  static const String validationPasswordUniqueCharacters =
      'validation.passwordUniqueCharacters';
  static const String validationPasswordRequireDigit =
      'validation.passwordRequireDigit';
  static const String validationPasswordRequireLowercase =
      'validation.passwordRequireLowercase';
  static const String validationPasswordRequireUppercase =
      'validation.passwordRequireUppercase';
  static const String validationPasswordRequireNonAlphanumeric =
      'validation.passwordRequireNonAlphanumeric';
  static const String validationUserNameLowercaseOnly =
      'validation.userNameLowercaseOnly';
  static const String commonShowPassword = 'common.showPassword';
  static const String commonHidePassword = 'common.hidePassword';
}
