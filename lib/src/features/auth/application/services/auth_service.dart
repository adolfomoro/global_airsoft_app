import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/storage/shared_prefs_key_value_store.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_security_coordinator.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_storage_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/google_sign_in_exception.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/auth_repository.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/check_username_availability_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/check_username_availability_output_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/create_user_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/create_user_output_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/google_sign_in_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/google_sign_in_response_output_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/google_sign_up_confirm_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/request_password_recovery_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/user_login_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/user_login_output_dto.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/auth_profile.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/auth_tokens.dart';

final class AuthService {
  static const String _userIdBackupKey = 'user_id_for_backup';

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

  Future<void> persistAuthenticatedUser(
    UserLoginOutputDto output, {
    required String successLogMessage,
  }) async {
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
    await _sharedPrefs.setString(_userIdBackupKey, profile.id);
    AuthSecurityCoordinator.instance.cacheTokens(authTokens);
    AuthSecurityCoordinator.instance.notifySessionChanged();

    _logger.info(successLogMessage);
  }

  Future<void> login(String login, String password) async {
    final UserLoginInputDto input = UserLoginInputDto(
      login: login,
      password: password,
    );

    final output = await _authRepository.login(input);
    await persistAuthenticatedUser(
      output,
      successLogMessage: 'User logged in successfully',
    );
  }

  Future<void> logout() async {
    await _authRepository.logout();
    await _clearLocalSession();
    _logger.info('User logged out');
  }

  Future<void> _clearLocalSession() async {
    await AuthSecurityCoordinator.instance.clearSession();
    if (AuthSecurityCoordinator.instance.isConfigured) {
      return;
    }

    await _authStorageService.clearAll();
    await _sharedPrefs.remove(_userIdBackupKey);
  }

  Future<void> signUp({
    required String username,
    required String fullName,
    required String email,
    required String password,
  }) async {
    final CreateUserInputDto input = CreateUserInputDto(
      username: username,
      fullName: fullName,
      email: email,
      password: password,
    );

    final CreateUserOutputDto output = await _authRepository.signUp(input);
    await persistAuthenticatedUser(
      UserLoginOutputDto(profile: output.profile, tokens: output.tokens),
      successLogMessage: 'User signed up successfully',
    );
  }

  Future<CheckUsernameAvailabilityOutputDto> checkUsernameAvailability(
    String username,
  ) {
    final CheckUsernameAvailabilityInputDto input =
        CheckUsernameAvailabilityInputDto(
          userName: username.trim().toLowerCase(),
        );

    return _authRepository.checkUsernameAvailability(input);
  }

  Future<GoogleSignInResponseOutputDto> signInWithGoogle(String idToken) async {
    final GoogleSignInInputDto input = GoogleSignInInputDto(idToken: idToken);
    final GoogleSignInResponseOutputDto output = await _authRepository
        .signInWithGoogle(input);

    if (output.userExists) {
      final UserLoginOutputDto? login = output.login;
      if (login == null) {
        throw const GoogleSignInException(
          'Google sign-in succeeded but no login payload was returned.',
        );
      }

      await persistAuthenticatedUser(
        login,
        successLogMessage: 'User signed in with Google successfully',
      );
    }

    return output;
  }

  Future<void> signUpWithGoogle(GoogleSignUpConfirmInputDto input) async {
    final CreateUserOutputDto output = await _authRepository.signUpWithGoogle(
      input,
    );
    await persistAuthenticatedUser(
      UserLoginOutputDto(profile: output.profile, tokens: output.tokens),
      successLogMessage: 'User signed up with Google successfully',
    );
  }

  Future<void> requestPasswordRecovery(String email) {
    final RequestPasswordRecoveryInputDto input =
        RequestPasswordRecoveryInputDto(email: email);

    return _authRepository.requestPasswordRecovery(input);
  }
}
