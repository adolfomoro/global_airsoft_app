final class UserAccountAccessOverviewOutputDto {
  const UserAccountAccessOverviewOutputDto({
    required this.identity,
    required this.loginMethods,
  });

  factory UserAccountAccessOverviewOutputDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return UserAccountAccessOverviewOutputDto(
      identity: UserAccountIdentityOutputDto.fromJson(
        _asObject(json['identity']),
      ),
      loginMethods: _asObjectList(
        json['loginMethods'],
      ).map(UserAccountLoginMethodOutputDto.fromJson).toList(growable: false),
    );
  }

  final UserAccountIdentityOutputDto identity;
  final List<UserAccountLoginMethodOutputDto> loginMethods;
}

final class UserAccountIdentityOutputDto {
  const UserAccountIdentityOutputDto({
    required this.userName,
    required this.email,
    required this.emailStatus,
    required this.phoneNumber,
    required this.phoneStatus,
  });

  factory UserAccountIdentityOutputDto.fromJson(Map<String, dynamic> json) {
    return UserAccountIdentityOutputDto(
      userName: _readString(json['userName']),
      email: _readOptionalString(json['email']),
      emailStatus: _readString(json['emailStatus']),
      phoneNumber: _readOptionalString(json['phoneNumber']),
      phoneStatus: _readString(json['phoneStatus']),
    );
  }

  final String userName;
  final String? email;
  final String emailStatus;
  final String? phoneNumber;
  final String phoneStatus;
}

final class UserAccountLoginMethodOutputDto {
  const UserAccountLoginMethodOutputDto({
    required this.type,
    required this.status,
    required this.action,
  });

  factory UserAccountLoginMethodOutputDto.fromJson(Map<String, dynamic> json) {
    return UserAccountLoginMethodOutputDto(
      type: _readString(json['type']),
      status: _readString(json['status']),
      action: _readOptionalString(json['action']),
    );
  }

  final String type;
  final String status;
  final String? action;
}

Map<String, dynamic> _asObject(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  return <String, dynamic>{};
}

List<Map<String, dynamic>> _asObjectList(Object? value) {
  if (value is! List<dynamic>) {
    return const <Map<String, dynamic>>[];
  }

  return value.whereType<Map<String, dynamic>>().toList(growable: false);
}

String _readString(Object? value) {
  if (value is String) {
    return value.trim();
  }

  return '';
}

String? _readOptionalString(Object? value) {
  final String normalized = _readString(value);
  return normalized.isEmpty ? null : normalized;
}
