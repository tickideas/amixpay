import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/auth_models.dart';

// ── Demo mode ────────────────────────────────────────────────────────────────
// Only available in debug builds. In release builds, network errors are
// surfaced to the user — no fake sessions are ever created.
const _demoAccessToken = 'demo_amixpay_token_v1';

UserModel _buildDemoUser(String email, {String? firstName, String? lastName, String? phone, String? countryCode}) {
  final nameParts = email.split('@').first.split('.');
  final first = firstName ?? (nameParts.isNotEmpty ? _capitalize(nameParts.first) : 'Demo');
  final last = lastName ?? (nameParts.length > 1 ? _capitalize(nameParts[1]) : 'User');
  return UserModel(
    id: 'demo-user-001',
    email: email,
    username: email.split('@').first.replaceAll('.', '_'),
    firstName: first,
    lastName: last,
    phone: phone ?? '+1 555 012 3456',
    countryCode: countryCode ?? 'US',
    role: 'user',
    status: 'active',
    twoFactorOn: false,
    kycStatus: 'pending',
    kycLevel: 1,
    avatarUrl: null,
  );
}

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

bool _isNetworkError(DioException e) =>
    e.response == null ||
    e.type == DioExceptionType.connectionError ||
    e.type == DioExceptionType.connectionTimeout ||
    e.type == DioExceptionType.receiveTimeout ||
    e.type == DioExceptionType.sendTimeout;

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  Future<({UserModel user, AuthTokens tokens})> register({
    required String email, required String password,
    required String firstName, required String lastName,
    required String username, String? phone, String? countryCode,
  }) async {
    try {
      final res = await _dio.post('/auth/register', data: {
        'email': email, 'password': password, 'firstName': firstName,
        'lastName': lastName, 'username': username,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (countryCode != null) 'countryCode': countryCode,
      });
      final data = res.data['data'] as Map<String, dynamic>;
      final tokens = AuthTokens.fromJson(data);
      await SecureStorage.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
      return (user: UserModel.fromJson(data['user'] as Map<String, dynamic>), tokens: tokens);
    } on DioException catch (e) {
      // Demo mode — debug builds only
      if (kDebugMode && _isNetworkError(e)) {
        debugPrint('[AuthRepository] Server unreachable — entering demo mode (debug only)');
        const tokens = AuthTokens(accessToken: _demoAccessToken, refreshToken: _demoAccessToken, expiresIn: 604800);
        await SecureStorage.saveTokens(accessToken: _demoAccessToken, refreshToken: _demoAccessToken);
        final user = _buildDemoUser(email, firstName: firstName, lastName: lastName, phone: phone, countryCode: countryCode);
        await SecureStorage.saveUserJson(jsonEncode(user.toJson()));
        return (user: user, tokens: tokens);
      }
      throw ApiException.fromDio(e);
    }
  }

  Future<({UserModel? user, AuthTokens? tokens, bool requires2fa, String? challengeToken})> login({
    required String email, required String password,
  }) async {
    try {
      final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
      final data = res.data['data'] as Map<String, dynamic>;
      if (data['requires_2fa'] == true || data['requiresTwoFactor'] == true) {
        return (user: null, tokens: null, requires2fa: true,
          challengeToken: data['challenge_token'] as String? ?? data['challengeToken'] as String?);
      }
      final tokens = AuthTokens.fromJson(data);
      await SecureStorage.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await SecureStorage.saveUserJson(jsonEncode(user.toJson()));
      return (user: user, tokens: tokens, requires2fa: false, challengeToken: null);
    } on DioException catch (e) {
      // Demo mode — debug builds only
      if (kDebugMode && _isNetworkError(e)) {
        debugPrint('[AuthRepository] Server unreachable — entering demo mode (debug only)');
        const tokens = AuthTokens(accessToken: _demoAccessToken, refreshToken: _demoAccessToken, expiresIn: 604800);
        await SecureStorage.saveTokens(accessToken: _demoAccessToken, refreshToken: _demoAccessToken);
        final user = _buildDemoUser(email);
        await SecureStorage.saveUserJson(jsonEncode(user.toJson()));
        return (user: user, tokens: tokens, requires2fa: false, challengeToken: null);
      }
      throw ApiException.fromDio(e);
    }
  }

  Future<({UserModel user, AuthTokens tokens})> verify2fa({
    required String challengeToken, required String code,
  }) async {
    try {
      final res = await _dio.post('/auth/2fa/challenge', data: {'challengeToken': challengeToken, 'code': code});
      final data = res.data['data'] as Map<String, dynamic>;
      final tokens = AuthTokens.fromJson(data);
      await SecureStorage.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
      return (user: UserModel.fromJson(data['user'] as Map<String, dynamic>), tokens: tokens);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logout() async {
    try {
      final refresh = await SecureStorage.getRefreshToken();
      await _dio.post('/auth/logout', data: {'refreshToken': refresh});
    } catch (_) {}
    await SecureStorage.clearAll();
  }

  Future<void> verifyEmail({required String email, required String code}) async {
    try {
      await _dio.post('/auth/verify-email', data: {'code': code});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } catch (_) {
      // Backend returns generic 200 to prevent email enumeration
    }
  }

  Future<void> resendVerification({required String email}) async {
    try {
      await _dio.post('/auth/resend-verification', data: {'email': email});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Register this device's FCM token with the backend so it can receive push notifications.
  /// Called silently after login — errors are swallowed so they never block the user.
  Future<void> registerDeviceToken(String fcmToken, String platform) async {
    try {
      await _dio.post('/notifications/devices', data: {
        'deviceToken': fcmToken,
        'platform': platform,
      });
    } catch (_) {
      // Non-critical — fail silently
    }
  }

  Future<UserModel> getMe() async {
    try {
      final res = await _dio.get('/users/me');
      final user = UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
      await SecureStorage.saveUserJson(jsonEncode(user.toJson()));
      return user;
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        // Return cached user if available (works in both debug and release)
        final saved = await SecureStorage.getUserJson();
        if (saved != null) {
          try { return UserModel.fromJson(jsonDecode(saved) as Map<String, dynamic>); } catch (_) {}
        }
        // In debug mode, return demo user; in release, surface the error
        if (kDebugMode) return _buildDemoUser('demo@amixpay.com');
      }
      throw ApiException.fromDio(e);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ApiClient.instance));
