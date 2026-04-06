import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/auth_models.dart';
import '../../core/storage/secure_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  const AuthState({required this.status, this.user, this.error});
  AuthState copyWith({AuthStatus? status, UserModel? user, String? error}) =>
      AuthState(status: status ?? this.status, user: user ?? this.user, error: error);
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final isLoggedIn = await SecureStorage.isLoggedIn();
    if (!isLoggedIn) return const AuthState(status: AuthStatus.unauthenticated);

    // Load cached user from storage immediately (no network wait)
    final savedJson = await SecureStorage.getUserJson();
    if (savedJson != null) {
      try {
        final user = UserModel.fromJson(jsonDecode(savedJson) as Map<String, dynamic>);
        return AuthState(status: AuthStatus.authenticated, user: user);
      } catch (_) {}
    }

    // Fallback: try network
    try {
      final user = await ref.read(authRepositoryProvider).getMe();
      return AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await SecureStorage.clearAll();
      return const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final result = await ref.read(authRepositoryProvider).login(email: email, password: password);
      if (result.requires2fa) {
        state = AsyncData(const AuthState(status: AuthStatus.unauthenticated));
        return false;
      }
      state = AsyncData(AuthState(status: AuthStatus.authenticated, user: result.user));
      return true;
    } catch (e) {
      state = AsyncData(AuthState(status: AuthStatus.unauthenticated, error: e.toString()));
      return false;
    }
  }

  Future<bool> register({
    required String email, required String password,
    required String firstName, required String lastName,
    required String username, String? phone, String? countryCode,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await ref.read(authRepositoryProvider).register(
        email: email, password: password, firstName: firstName,
        lastName: lastName, username: username, phone: phone, countryCode: countryCode,
      );
      state = AsyncData(AuthState(status: AuthStatus.authenticated, user: result.user));
      return true;
    } catch (e) {
      state = AsyncData(AuthState(status: AuthStatus.unauthenticated, error: e.toString()));
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = AsyncData(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> refreshUser() async {
    try {
      final user = await ref.read(authRepositoryProvider).getMe();
      state = AsyncData(AuthState(status: AuthStatus.authenticated, user: user));
    } catch (_) {}
  }

  /// Called immediately after a direct-repository login/register to sync the user into state.
  void setUser(UserModel user) {
    state = AsyncData(AuthState(status: AuthStatus.authenticated, user: user));
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
