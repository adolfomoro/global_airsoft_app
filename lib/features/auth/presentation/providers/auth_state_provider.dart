import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  const AuthState({required this.isLoggedIn});

  final bool isLoggedIn;

  AuthState copyWith({bool? isLoggedIn}) {
    return AuthState(isLoggedIn: isLoggedIn ?? this.isLoggedIn);
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState(isLoggedIn: false);
  }

  Future<void> markLoggedIn() async {
    state = state.copyWith(isLoggedIn: true);
  }

  Future<void> markLoggedOut() async {
    state = state.copyWith(isLoggedIn: false);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
