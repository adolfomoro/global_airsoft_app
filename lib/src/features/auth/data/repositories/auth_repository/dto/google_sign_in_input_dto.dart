import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/external_sign_in_input_dto.dart';

final class GoogleSignInInputDto extends ExternalSignInInputDto {
  GoogleSignInInputDto({required super.idToken});
}
