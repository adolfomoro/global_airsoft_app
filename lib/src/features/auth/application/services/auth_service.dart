import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_storage_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/create_user_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/password_validation_rules_output_dto.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/request_password_recovery_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/user_login_input_dto.dart';

final class AuthService {
  AuthService({
    required AuthRepository authRepository,
    required AuthStorageService authStorageService,
    required AppLogger logger,
  }) : _authRepository = authRepository,
       _authStorageService = authStorageService,
       _logger = logger;

  final AuthRepository _authRepository;
  final AuthStorageService _authStorageService;
  final AppLogger _logger;

  Future<void> login(String login, String password) async {
    final UserLoginInputDto input = UserLoginInputDto(
      login: login,
      password: password,
    );

    final output = await _authRepository.login(input);

    await _authStorageService.saveJwtToken(output.jwtToken);
    await _authStorageService.saveRefreshToken(output.refreshToken);

    _logger.info('User logged in successfully');
  }

  Future<void> logout() async {
    await _authStorageService.clearTokens();
    _logger.info('User logged out');
  }

  Future<void> signUp({
    required String userName,
    required String email,
    required String password,
  }) async {
    final CreateUserInputDto input = CreateUserInputDto(
      userName: userName,
      email: email,
      password: password,
    );

    final output = await _authRepository.signUp(input);

    await _authStorageService.saveJwtToken(output.loginInfo.jwtToken);
    await _authStorageService.saveRefreshToken(output.loginInfo.refreshToken);

    _logger.info('User signed up successfully');
  }

  Future<PasswordValidationRulesOutputDto> getPasswordValidationRules() {
    return _authRepository.getPasswordValidationRules();
  }

  Future<void> requestPasswordRecovery(String email) {
    final RequestPasswordRecoveryInputDto input =
        RequestPasswordRecoveryInputDto(email: email);

    return _authRepository.requestPasswordRecovery(input);
  }
}
