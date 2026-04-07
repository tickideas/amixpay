import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/payment_models.dart';

class PaymentRepository {
  final Dio _dio;
  PaymentRepository(this._dio);

  Future<PaymentModel> send({
    required String recipient, required double amount,
    required String currencyCode, String? note,
  }) async {
    final res = await _dio.post('/payments/send', data: {
      'recipient': recipient, 'amount': amount, 'currencyCode': currencyCode,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return PaymentModel.fromJson(res.data['data']['payment'] as Map<String, dynamic>);
  }

  Future<PaymentRequestModel> createRequest({
    required String payer, required double amount,
    required String currencyCode, String? note,
  }) async {
    final res = await _dio.post('/payment-requests', data: {
      'payer': payer, 'amount': amount, 'currencyCode': currencyCode,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return PaymentRequestModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<List<PaymentRequestModel>> getRequests({String role = 'all'}) async {
    final res = await _dio.get('/payment-requests', queryParameters: {'role': role});
    final list = res.data['data'] as List<dynamic>? ?? [];
    return list.map((r) => PaymentRequestModel.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<void> acceptRequest(String id) async => _dio.post('/payment-requests/$id/accept');
  Future<void> declineRequest(String id) async => _dio.post('/payment-requests/$id/decline');
  Future<void> cancelRequest(String id) async => _dio.post('/payment-requests/$id/cancel');

  /// Search for AmixPay users by username, email, or phone
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final res = await _dio.get('/users/lookup', queryParameters: {'q': query});
    final data = res.data['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map) return [data.cast<String, dynamic>()];
    return [];
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) => PaymentRepository(ApiClient.instance));
