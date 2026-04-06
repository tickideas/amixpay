import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  static const String _baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000/v1', // Android emulator → localhost
  );

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(_AuthInterceptor());
    if (kDebugMode) dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));

    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try token refresh
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken != null) {
        try {
          final refreshDio = Dio(BaseOptions(baseUrl: ApiClient._baseUrl));
          final response = await refreshDio.post('/auth/refresh', data: {'refreshToken': refreshToken});
          final newToken = response.data['data']['access_token'];
          final newRefresh = response.data['data']['refresh_token'];
          await SecureStorage.saveTokens(accessToken: newToken, refreshToken: newRefresh);

          // Retry original request
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await ApiClient.instance.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        } catch (_) {
          await SecureStorage.clearAll();
        }
      }
    }
    handler.next(err);
  }
}

class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  ApiException({required this.message, this.code, this.statusCode});

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    final msg = data?['error']?['message'] ?? data?['message'] ?? e.message ?? 'An error occurred';
    final code = data?['error']?['code'];
    return ApiException(message: msg, code: code, statusCode: e.response?.statusCode);
  }

  @override
  String toString() => message;
}
