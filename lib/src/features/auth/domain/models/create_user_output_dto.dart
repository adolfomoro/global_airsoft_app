import 'package:global_airsoft_app/src/features/auth/domain/models/user_login_output_dto.dart';

final class CreateUserOutputDto {
  const CreateUserOutputDto({
    required this.id,
    required this.userName,
    required this.loginInfo,
  });

  final String id;
  final String userName;
  final UserLoginOutputDto loginInfo;

  factory CreateUserOutputDto.fromJson(Map<String, dynamic> json) {
    return CreateUserOutputDto(
      id: (json['id'] as String?) ?? '',
      userName: (json['userName'] as String?) ?? '',
      loginInfo: UserLoginOutputDto.fromJson(
        (json['loginInfo'] as Map<String, dynamic>?) ??
            const <String, dynamic>{},
      ),
    );
  }
}
