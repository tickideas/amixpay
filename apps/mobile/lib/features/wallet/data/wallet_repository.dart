import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/wallet_models.dart';

class WalletRepository {
  final Dio _dio;
  WalletRepository(this._dio);

  Future<WalletModel> getWallet() async {
    final res = await _dio.get('/wallets');
    return WalletModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<WalletModel> addCurrency(String currencyCode) async {
    final res = await _dio.post('/wallets/currencies', data: {'currencyCode': currencyCode});
    return WalletModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> removeCurrency(String currencyCode) async {
    await _dio.delete('/wallets/currencies/$currencyCode');
  }

  Future<List<TransactionModel>> getTransactions({
    int limit = 20, int offset = 0, String? type, String? currency,
  }) async {
    final res = await _dio.get('/wallets/transactions', queryParameters: {
      'limit': limit, 'offset': offset,
      if (type != null) 'type': type,
      if (currency != null) 'currency': currency,
    });
    final list = res.data['data'] as List<dynamic>? ?? [];
    return list.map((t) => TransactionModel.fromJson(t as Map<String, dynamic>)).toList();
  }

  Future<TransactionModel> getTransaction(String id) async {
    final res = await _dio.get('/wallets/transactions/$id');
    return TransactionModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) => WalletRepository(ApiClient.instance));
