import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/google_sign_in_response_output_dto.dart';

void main() {
  test('parses a successful google response with login payload', () {
    final GoogleSignInResponseOutputDto response =
        GoogleSignInResponseOutputDto.fromJson(<String, dynamic>{
          'userExists': true,
          'challengeToken': 'challenge-123',
          'login': <String, dynamic>{
            'profile': <String, dynamic>{'id': 'user-1', 'username': 'player1'},
            'tokens': <String, dynamic>{
              'jwtToken': 'jwt-token',
              'refreshToken': 'refresh-token',
            },
          },
        });

    expect(response.userExists, isTrue);
    expect(response.challengeToken, 'challenge-123');
    expect(response.login, isNotNull);
    expect(response.login?.profile.username, 'player1');
  });

  test('parses a suggestion when the user does not exist yet', () {
    final GoogleSignInResponseOutputDto response =
        GoogleSignInResponseOutputDto.fromJson(<String, dynamic>{
          'userExists': false,
          'challengeToken': 'challenge-456',
          'suggestion': <String, dynamic>{
            'profilePictureUrl': 'https://example.com/photo.jpg',
            'username': 'player2',
          },
        });

    expect(response.userExists, isFalse);
    expect(response.challengeToken, 'challenge-456');
    expect(response.suggestion, isNotNull);
    expect(response.suggestion?.username, 'player2');
  });
}
