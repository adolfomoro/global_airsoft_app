import '../../domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<void> login({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
  }

  @override
  Future<void> loginWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
  }
}
