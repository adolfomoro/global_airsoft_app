import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/external_sign_in_suggestion_output_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/user_login_output_dto.dart';

class ExternalSignInResponseOutputDto {
  const ExternalSignInResponseOutputDto({
    required this.userExists,
    required this.challengeToken,
    required this.suggestion,
    required this.login,
  });

  final bool userExists;
  final String? challengeToken;
  final ExternalSignInSuggestionOutputDto? suggestion;
  final UserLoginOutputDto? login;

  factory ExternalSignInResponseOutputDto.fromJson(Map<String, dynamic> json) {
    final Object? suggestionValue = json['suggestion'];
    final Object? loginValue = json['login'];
    final String? rawChallengeToken = json['challengeToken'] as String?;
    final String? normalizedChallengeToken =
        rawChallengeToken == null || rawChallengeToken.trim().isEmpty
        ? null
        : rawChallengeToken;

    return ExternalSignInResponseOutputDto(
      userExists: json['userExists'] == true,
      challengeToken: normalizedChallengeToken,
      suggestion: suggestionValue is Map<String, dynamic>
          ? ExternalSignInSuggestionOutputDto.fromJson(suggestionValue)
          : null,
      login: loginValue is Map<String, dynamic>
          ? UserLoginOutputDto.fromJson(loginValue)
          : null,
    );
  }
}
