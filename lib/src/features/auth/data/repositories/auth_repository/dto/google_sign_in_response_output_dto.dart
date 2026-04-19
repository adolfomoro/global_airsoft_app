import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/external_sign_in_response_output_dto.dart';

final class GoogleSignInResponseOutputDto
    extends ExternalSignInResponseOutputDto {
  const GoogleSignInResponseOutputDto({
    required super.userExists,
    required super.challengeToken,
    required super.suggestion,
    required super.login,
  });

  factory GoogleSignInResponseOutputDto.fromJson(Map<String, dynamic> json) {
    final ExternalSignInResponseOutputDto parsed =
        ExternalSignInResponseOutputDto.fromJson(json);

    return GoogleSignInResponseOutputDto(
      userExists: parsed.userExists,
      challengeToken: parsed.challengeToken,
      suggestion: parsed.suggestion,
      login: parsed.login,
    );
  }
}
