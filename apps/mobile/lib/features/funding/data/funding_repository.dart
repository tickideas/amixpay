import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class FundingRepository {
  final Dio _dio;
  FundingRepository(this._dio);

  /// Step 1 — get a Plaid link_token from the backend
  Future<String> createPlaidLinkToken() async {
    final res = await _dio.post('/funding/bank-accounts/link-token');
    final data = res.data['data'] as Map<String, dynamic>;
    return data['link_token'] as String;
  }

  /// Step 2 — exchange the public_token Plaid returns after the user links
  Future<List<dynamic>> exchangePlaidToken(String publicToken) async {
    final res = await _dio.post('/funding/bank-accounts', data: {
      'publicToken': publicToken,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    return data['accounts'] as List<dynamic>? ?? [];
  }

  /// Get linked bank accounts
  Future<List<dynamic>> getLinkedAccounts() async {
    final res = await _dio.get('/funding/bank-accounts');
    return res.data['data'] as List<dynamic>? ?? [];
  }

  /// Create a Stripe PaymentIntent for card deposit
  Future<Map<String, dynamic>> createDepositIntent({
    required double amount,
    required String currency,
  }) async {
    final res = await _dio.post('/funding/deposit', data: {
      'amount': amount,
      'currency': currency,
    });
    return res.data['data'] as Map<String, dynamic>;
  }

  /// Confirm the deposit after Stripe payment succeeds
  Future<void> confirmDeposit(String paymentIntentId) async {
    await _dio.post('/funding/deposit/confirm', data: {
      'paymentIntentId': paymentIntentId,
    });
  }
}

final fundingRepositoryProvider = Provider<FundingRepository>(
  (ref) => FundingRepository(ApiClient.instance),
);
