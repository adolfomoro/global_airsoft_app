import 'package:global_airsoft_app/src/features/users/data/repositories/user_account_repository/dto/user_account_access_overview_output_dto.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_account_repository/user_account_repository.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_account_access_overview.dart';

final class UserAccountService {
  const UserAccountService({required UserAccountRepository repository})
    : _repository = repository;

  final UserAccountRepository _repository;

  Future<UserAccountAccessOverview> getCurrentUserAccessOverview() async {
    final UserAccountAccessOverviewOutputDto dto = await _repository
        .getCurrentUserAccessOverview();

    return UserAccountAccessOverview(
      identity: _mapIdentity(dto.identity),
      loginMethods: dto.loginMethods
          .map(_mapLoginMethod)
          .toList(growable: false),
    );
  }

  UserAccountIdentity _mapIdentity(UserAccountIdentityOutputDto dto) {
    return UserAccountIdentity(
      username: dto.userName,
      email: dto.email,
      emailStatus: _parseContactStatus(dto.emailStatus),
      phoneNumber: dto.phoneNumber,
      phoneStatus: _parseContactStatus(dto.phoneStatus),
    );
  }

  UserAccountLoginMethod _mapLoginMethod(UserAccountLoginMethodOutputDto dto) {
    return UserAccountLoginMethod(
      type: _parseLoginMethodType(dto.type),
      status: _parseLoginMethodStatus(dto.status),
      action: _parseLoginMethodAction(dto.action),
    );
  }

  UserAccountContactStatus _parseContactStatus(String value) {
    return switch (value.trim().toLowerCase()) {
      'verified' => UserAccountContactStatus.verified,
      'unverified' => UserAccountContactStatus.unverified,
      'notconfigured' => UserAccountContactStatus.notConfigured,
      'not_configured' => UserAccountContactStatus.notConfigured,
      _ => UserAccountContactStatus.unknown,
    };
  }

  UserAccountLoginMethodType _parseLoginMethodType(String value) {
    return switch (value.trim().toLowerCase()) {
      'password' => UserAccountLoginMethodType.password,
      'google' => UserAccountLoginMethodType.google,
      'apple' => UserAccountLoginMethodType.apple,
      _ => UserAccountLoginMethodType.unknown,
    };
  }

  UserAccountLoginMethodStatus _parseLoginMethodStatus(String value) {
    return switch (value.trim().toLowerCase()) {
      'active' => UserAccountLoginMethodStatus.active,
      'notconfigured' => UserAccountLoginMethodStatus.notConfigured,
      'not_configured' => UserAccountLoginMethodStatus.notConfigured,
      'connected' => UserAccountLoginMethodStatus.connected,
      'notconnected' => UserAccountLoginMethodStatus.notConnected,
      'not_connected' => UserAccountLoginMethodStatus.notConnected,
      _ => UserAccountLoginMethodStatus.unknown,
    };
  }

  UserAccountLoginMethodAction? _parseLoginMethodAction(String? value) {
    final String normalized = value?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) {
      return null;
    }

    return switch (normalized) {
      'setpassword' => UserAccountLoginMethodAction.setPassword,
      'set_password' => UserAccountLoginMethodAction.setPassword,
      'connect' => UserAccountLoginMethodAction.connect,
      _ => UserAccountLoginMethodAction.unknown,
    };
  }
}
