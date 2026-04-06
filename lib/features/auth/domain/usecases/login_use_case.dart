import '../repositories/auth_repository.dart';

class LoginUseCase {
  LoginUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> call({required String username, required String password}) {
    return _authRepository.login(username: username, password: password);
  }

  Future<void> withGoogle() {
    return _authRepository.loginWithGoogle();
  }
}
