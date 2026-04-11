import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/storage/shared_prefs_key_value_store.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_storage_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/auth_repository.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/create_user_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/create_user_output_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/password_validation_rules_output_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/request_password_recovery_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/user_login_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/auth_profile.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/auth_tokens.dart';

final class AuthService {
  AuthService({
    required AuthRepository authRepository,
    required AuthStorageService authStorageService,
    required SharedPrefsKeyValueStore sharedPrefs,
    required AppLogger logger,
  }) : _authRepository = authRepository,
       _authStorageService = authStorageService,
       _sharedPrefs = sharedPrefs,
       _logger = logger;

  final AuthRepository _authRepository;
  final AuthStorageService _authStorageService;
  final SharedPrefsKeyValueStore _sharedPrefs;
  final AppLogger _logger;

  Future<void> login(String login, String password) async {
    final UserLoginInputDto input = UserLoginInputDto(
      login: login,
      password: password,
    );

    final output = await _authRepository.login(input);
    final tokens = output.tokens;
    final profile = output.profile;

    final authTokens = AuthTokens(
      jwtToken: tokens.jwtToken,
      refreshToken: tokens.refreshToken,
    );
    final authProfile = AuthProfile(
      userId: profile.id,
      username: profile.username,
    );
    await _authStorageService.saveTokens(authTokens);
    await _authStorageService.saveProfile(authProfile);
    await _sharedPrefs.setString('user_id_for_backup', profile.id);

    _logger.info('User logged in successfully');
  }

  Future<void> logout() async {
    await _authStorageService.clearAll();
    await _sharedPrefs.remove('user_id_for_backup');
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

    final CreateUserOutputDto output = await _authRepository.signUp(input);
    final tokens = output.tokens;
    final profile = output.profile;

    final authTokens = AuthTokens(
      jwtToken: tokens.jwtToken,
      refreshToken: tokens.refreshToken,
    );
    final authProfile = AuthProfile(
      userId: profile.id,
      username: profile.username,
    );
    await _authStorageService.saveTokens(authTokens);
    await _authStorageService.saveProfile(authProfile);
    await _sharedPrefs.setString('user_id_for_backup', profile.id);

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
