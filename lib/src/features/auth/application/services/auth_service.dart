import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_storage_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository.dart';
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

  String? _cachedJwtToken;

  String? getCachedJwtToken() => _cachedJwtToken;

  Future<bool> isAuthenticated() async {
    final String? token = await _authStorageService.getJwtToken();
    _cachedJwtToken = token;
    return token != null && token.isNotEmpty;
  }

  Future<void> login(String login, String password) async {
    final UserLoginInputDto input = UserLoginInputDto(
      login: login,
      password: password,
    );

    final output = await _authRepository.login(input);

    await _authStorageService.saveJwtToken(output.jwtToken);
    await _authStorageService.saveRefreshToken(output.refreshToken);

    _cachedJwtToken = output.jwtToken;

    _logger.info('User logged in successfully');
  }

  Future<void> logout() async {
    await _authStorageService.clearTokens();
    _cachedJwtToken = null;
    _logger.info('User logged out');
  }
}
