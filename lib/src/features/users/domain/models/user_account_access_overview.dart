enum UserAccountContactStatus { verified, unverified, notConfigured, unknown }

enum UserAccountLoginMethodType { password, google, apple, unknown }

enum UserAccountLoginMethodStatus {
  active,
  notConfigured,
  connected,
  notConnected,
  unknown,
}

enum UserAccountLoginMethodAction { setPassword, connect, unknown }

final class UserAccountAccessOverview {
  const UserAccountAccessOverview({
    required this.identity,
    required this.loginMethods,
  });

  final UserAccountIdentity identity;
  final List<UserAccountLoginMethod> loginMethods;
}

final class UserAccountIdentity {
  const UserAccountIdentity({
    required this.username,
    required this.email,
    required this.emailStatus,
    required this.phoneNumber,
    required this.phoneStatus,
  });

  final String username;
  final String? email;
  final UserAccountContactStatus emailStatus;
  final String? phoneNumber;
  final UserAccountContactStatus phoneStatus;
}

final class UserAccountLoginMethod {
  const UserAccountLoginMethod({
    required this.type,
    required this.status,
    required this.action,
  });

  final UserAccountLoginMethodType type;
  final UserAccountLoginMethodStatus status;
  final UserAccountLoginMethodAction? action;
}
