import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';

/// A saved payment recipient with bank details.
class SavedRecipient {
  final String id;
  final String name;
  final String initials;
  final String currency;
  final String flag;
  final String? accountNumber;
  final String? bankSystem;   // 'ukSortCode', 'usRouting', 'generic', etc.
  final String? bankName;
  final DateTime lastSentAt;
  final double? lastAmount;

  const SavedRecipient({
    required this.id,
    required this.name,
    required this.initials,
    required this.currency,
    required this.flag,
    this.accountNumber,
    this.bankSystem,
    this.bankName,
    required this.lastSentAt,
    this.lastAmount,
  });

  factory SavedRecipient.fromJson(Map<String, dynamic> json) => SavedRecipient(
        id: json['id'] as String,
        name: json['name'] as String,
        initials: json['initials'] as String,
        currency: json['currency'] as String,
        flag: json['flag'] as String,
        accountNumber: json['accountNumber'] as String?,
        bankSystem: json['bankSystem'] as String?,
        bankName: json['bankName'] as String?,
        lastSentAt: DateTime.parse(json['lastSentAt'] as String),
        lastAmount: (json['lastAmount'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initials': initials,
        'currency': currency,
        'flag': flag,
        'accountNumber': accountNumber,
        'bankSystem': bankSystem,
        'bankName': bankName,
        'lastSentAt': lastSentAt.toIso8601String(),
        'lastAmount': lastAmount,
      };

  SavedRecipient copyWith({DateTime? lastSentAt, double? lastAmount}) =>
      SavedRecipient(
        id: id,
        name: name,
        initials: initials,
        currency: currency,
        flag: flag,
        accountNumber: accountNumber,
        bankSystem: bankSystem,
        bankName: bankName,
        lastSentAt: lastSentAt ?? this.lastSentAt,
        lastAmount: lastAmount ?? this.lastAmount,
      );
}

/// Manages saved recipients with SecureStorage persistence.
class RecipientsNotifier extends StateNotifier<List<SavedRecipient>> {
  RecipientsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final json = await SecureStorage.getRecipients();
    if (json != null) {
      try {
        final list = jsonDecode(json) as List;
        state = list
            .map((e) => SavedRecipient.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
  }

  Future<void> _persist() async {
    await SecureStorage.saveRecipients(
      jsonEncode(state.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> addOrUpdate(SavedRecipient recipient) async {
    final existing = state.indexWhere((r) => r.id == recipient.id);
    if (existing >= 0) {
      final updated = [...state];
      updated[existing] = recipient;
      state = updated;
    } else {
      state = [recipient, ...state];
    }
    await _persist();
  }

  Future<void> remove(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _persist();
  }

  /// Returns the 6 most recently used recipients for the Quick Send row.
  List<SavedRecipient> get recentSix {
    final sorted = [...state]
      ..sort((a, b) => b.lastSentAt.compareTo(a.lastSentAt));
    return sorted.take(6).toList();
  }
}

final savedRecipientsProvider =
    StateNotifierProvider<RecipientsNotifier, List<SavedRecipient>>(
  (ref) => RecipientsNotifier(),
);
