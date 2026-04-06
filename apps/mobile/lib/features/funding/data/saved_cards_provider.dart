import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';

class SavedPaymentCard {
  final String id;
  final String last4;
  final String brand;   // 'visa' | 'mastercard' | 'amex' | 'other'
  final String expiry;  // MM/YY
  final String nickname; // e.g. "My Chase Visa"

  const SavedPaymentCard({
    required this.id,
    required this.last4,
    required this.brand,
    required this.expiry,
    required this.nickname,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'last4': last4, 'brand': brand, 'expiry': expiry, 'nickname': nickname,
  };

  factory SavedPaymentCard.fromJson(Map<String, dynamic> j) => SavedPaymentCard(
    id: j['id'] as String,
    last4: j['last4'] as String,
    brand: j['brand'] as String? ?? 'visa',
    expiry: j['expiry'] as String? ?? '',
    nickname: j['nickname'] as String? ?? '',
  );
}

class SavedCardsNotifier extends StateNotifier<List<SavedPaymentCard>> {
  SavedCardsNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await SecureStorage.getSavedPaymentCards();
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((e) => SavedPaymentCard.fromJson(e as Map<String, dynamic>))
            .toList();
        state = list;
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      await SecureStorage.saveSavedPaymentCards(
        jsonEncode(state.map((c) => c.toJson()).toList()),
      );
    } catch (_) {}
  }

  void addCard(SavedPaymentCard card) {
    // Avoid duplicates based on last4 + expiry
    if (state.any((c) => c.last4 == card.last4 && c.expiry == card.expiry)) return;
    state = [...state, card];
    _persist();
  }

  void removeCard(String id) {
    state = state.where((c) => c.id != id).toList();
    _persist();
  }
}

final savedCardsProvider =
    StateNotifierProvider<SavedCardsNotifier, List<SavedPaymentCard>>(
        (_) => SavedCardsNotifier());
