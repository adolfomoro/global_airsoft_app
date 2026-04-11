import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/user_login_profile_output_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/user_login_tokens_output_dto.dart';

final class UserLoginOutputDto {
  const UserLoginOutputDto({required this.profile, required this.tokens});

  final UserLoginProfileOutputDto profile;
  final UserLoginTokensOutputDto tokens;

  factory UserLoginOutputDto.fromJson(Map<String, dynamic> json) {
    return UserLoginOutputDto(
      profile: UserLoginProfileOutputDto.fromJson(
        (json['profile'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
      tokens: UserLoginTokensOutputDto.fromJson(
        (json['tokens'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
    );
  }
}
