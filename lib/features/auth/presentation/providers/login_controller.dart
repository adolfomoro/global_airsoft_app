import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/mock_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_use_case.dart';

enum LoginSource { traditional, google }

class LoginState {
  const LoginState({this.isLoading = false, this.loadingSource});

  final bool isLoading;
  final LoginSource? loadingSource;

  LoginState copyWith({
    bool? isLoading,
    LoginSource? loadingSource,
    bool resetLoadingSource = false,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      loadingSource: resetLoadingSource
          ? null
          : (loadingSource ?? this.loadingSource),
    );
  }
}

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<void> login({
    required String username,
    required String password,
  }) async {
    // Guard clause: prevent multiple submissions
    if (state.isLoading) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      loadingSource: LoginSource.traditional,
    );

    try {
      await ref
          .read(loginUseCaseProvider)
          .call(username: username, password: password);
      // TODO: Handle success (e.g., store token, navigate)
    } catch (e) {
      // TODO: Handle error (show snackbar, etc)
      rethrow;
    } finally {
      // Always reset loading state, even if error occurs
      state = state.copyWith(isLoading: false, resetLoadingSource: true);
    }
  }

  Future<void> loginWithGoogle() async {
    if (state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true, loadingSource: LoginSource.google);

    try {
      await ref.read(loginUseCaseProvider).withGoogle();
      // TODO: Handle success (e.g., store token, navigate)
    } catch (e) {
      // TODO: Handle error (show snackbar, etc)
      rethrow;
    } finally {
      // Always reset loading state, even if error occurs
      state = state.copyWith(isLoading: false, resetLoadingSource: true);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(),
);

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);

final loginControllerProvider = NotifierProvider<LoginController, LoginState>(
  LoginController.new,
);
