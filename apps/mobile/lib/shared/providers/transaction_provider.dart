import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/secure_storage.dart';

enum AppTxType { sent, received, funded, transfer }
enum AppTxStatus { paid, pending, failed }

class AppTransaction {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final String currency;
  final String symbol;
  final AppTxType type;
  final AppTxStatus status;
  final DateTime date;

  const AppTransaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.currency,
    required this.symbol,
    required this.type,
    required this.status,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'amount': amount,
    'currency': currency,
    'symbol': symbol,
    'type': type.name,
    'status': status.name,
    'date': date.toIso8601String(),
  };

  factory AppTransaction.fromJson(Map<String, dynamic> json) => AppTransaction(
    id: json['id'] as String,
    title: json['title'] as String,
    subtitle: json['subtitle'] as String,
    amount: (json['amount'] as num).toDouble(),
    currency: json['currency'] as String,
    symbol: json['symbol'] as String,
    type: AppTxType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => AppTxType.transfer,
    ),
    status: AppTxStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => AppTxStatus.paid,
    ),
    date: DateTime.parse(json['date'] as String),
  );
}

class TransactionNotifier extends StateNotifier<List<AppTransaction>> {
  TransactionNotifier() : super(const []) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final raw = await SecureStorage.getTransactions();
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((e) => AppTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
        state = list;
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      await SecureStorage.saveTransactions(
        jsonEncode(state.map((t) => t.toJson()).toList()),
      );
    } catch (_) {}
  }

  void add(AppTransaction tx) {
    state = [tx, ...state];
    _persist();
  }

  void clearAll() {
    state = [];
    _persist();
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, List<AppTransaction>>(
        (_) => TransactionNotifier());
