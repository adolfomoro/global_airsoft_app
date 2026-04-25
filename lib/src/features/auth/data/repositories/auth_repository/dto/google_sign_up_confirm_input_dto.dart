import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/external_sign_up_confirm_input_dto.dart';

final class GoogleSignUpConfirmInputDto extends ExternalSignUpConfirmInputDto {
  GoogleSignUpConfirmInputDto({
    required super.challengeToken,
    required super.username,
    super.profilePictureFile,
  });
}
