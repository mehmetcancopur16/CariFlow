import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/secure_storage_service.dart';
import '../../data/auth_repository.dart';
import '../../data/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  const AuthState({required this.status, this.user, this.errorMessage});

  const AuthState.initial() : this(status: AuthStatus.initial);

  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final token = await ref
        .read(secureStorageServiceProvider)
        .readAccessToken();
    if (token != null && token.isNotEmpty) {
      return const AuthState(status: AuthStatus.authenticated);
    }
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref
          .read(authRepositoryProvider)
          .login(email, password);
      return AuthState(status: AuthStatus.authenticated, user: user);
    });
  }

  Future<void> register(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref
          .read(authRepositoryProvider)
          .register(email, password);
      return AuthState(status: AuthStatus.authenticated, user: user);
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).logout();
      return const AuthState(status: AuthStatus.unauthenticated);
    });
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
