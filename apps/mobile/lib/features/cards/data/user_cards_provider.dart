import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_theme.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class IssuedCard {
  final String id;
  final String type; // 'virtual' | 'physical' | 'disposable'
  final String last4;
  final String holder;
  final String expiry;
  final String currency;
  final bool isFree; // first card is always free
  final LinearGradient gradient;
  final bool isDisposable;
  final int usageLimit; // 0 = unlimited, 1+ = max uses
  final int timesUsed;

  const IssuedCard({
    required this.id,
    required this.type,
    required this.last4,
    required this.holder,
    required this.expiry,
    required this.currency,
    required this.isFree,
    required this.gradient,
    this.isDisposable = false,
    this.usageLimit = 0,
    this.timesUsed = 0,
  });

  bool get isExpired => isDisposable && usageLimit > 0 && timesUsed >= usageLimit;

  IssuedCard copyWith({String? holder, bool? frozen, int? timesUsed}) => IssuedCard(
        id: id,
        type: type,
        last4: last4,
        holder: holder ?? this.holder,
        expiry: expiry,
        currency: currency,
        isFree: isFree,
        gradient: gradient,
        isDisposable: isDisposable,
        usageLimit: usageLimit,
        timesUsed: timesUsed ?? this.timesUsed,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'type': type, 'last4': last4, 'holder': holder,
        'expiry': expiry, 'currency': currency, 'isFree': isFree,
        'isDisposable': isDisposable, 'usageLimit': usageLimit, 'timesUsed': timesUsed,
        // gradient is not serializable; rebuild from id
      };

  // Returns the gradient name for serialization
  String get gradientKey {
    if (gradient == AppColors.cardGradient) return 'primary';
    if (gradient == _purpleGradient) return 'purple';
    if (gradient == _goldGradient) return 'gold';
    // Check by first color for dynamically created gradients
    if (gradient.colors.isNotEmpty) {
      if (gradient.colors.first == const Color(0xFFBE185D)) return 'rose';
      if (gradient.colors.first == const Color(0xFF1D4ED8)) return 'blue';
    }
    if (isFree) return 'primary';
    return 'physical';
  }

  factory IssuedCard.fromJson(Map<String, dynamic> json) {
    final key = json['gradientKey'] as String? ?? (json['isFree'] == true ? 'primary' : 'physical');
    final grad = switch (key) {
      'primary' => AppColors.cardGradient,
      'purple'  => _purpleGradient,
      'gold'    => _goldGradient,
      'rose'    => const LinearGradient(colors: [Color(0xFFBE185D), Color(0xFF9D174D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      'blue'    => const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF1E40AF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      _         => _physicalGradient,
    };
    return IssuedCard(
      id: json['id'] as String,
      type: json['type'] as String,
      last4: json['last4'] as String,
      holder: json['holder'] as String? ?? '',
      expiry: json['expiry'] as String? ?? '08/29',
      currency: json['currency'] as String? ?? 'USD',
      isFree: json['isFree'] as bool? ?? false,
      gradient: grad,
      isDisposable: json['isDisposable'] as bool? ?? false,
      usageLimit: json['usageLimit'] as int? ?? 0,
      timesUsed: json['timesUsed'] as int? ?? 0,
    );
  }
}

// Dark gradient for physical / extra cards
const _physicalGradient = LinearGradient(
  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const _purpleGradient = LinearGradient(
  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const _goldGradient = LinearGradient(
  colors: [Color(0xFFB8860B), Color(0xFFD4AF37)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class UserCardsNotifier extends StateNotifier<List<IssuedCard>> {
  UserCardsNotifier()
      : super(const [
          // The primary AmixPay virtual card — always free
          IssuedCard(
            id: 'primary-virtual',
            type: 'virtual',
            last4: '9982',
            holder: '',
            expiry: '08/29',
            currency: 'USD',
            isFree: true,
            gradient: AppColors.cardGradient,
            isDisposable: false,
            usageLimit: 0,
            timesUsed: 0,
          ),
        ]) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final raw = await SecureStorage.getIssuedCards();
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((e) => IssuedCard.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) state = list;
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final json = jsonEncode(state.map((c) {
        final m = c.toJson();
        m['gradientKey'] = c.gradientKey;
        return m;
      }).toList());
      await SecureStorage.saveIssuedCards(json);
    } catch (_) {}
  }

  static const _extraGradients = [
    _physicalGradient,
    _purpleGradient,
    _goldGradient,
  ];

  void updatePrimaryHolder(String name, {String? currency}) {
    if (state.isEmpty) return;
    final primary = state.first;
    state = [
      IssuedCard(
        id: primary.id,
        type: primary.type,
        last4: primary.last4,
        holder: name,
        expiry: primary.expiry,
        currency: currency ?? primary.currency,
        isFree: primary.isFree,
        gradient: primary.gradient,
        isDisposable: primary.isDisposable,
        usageLimit: primary.usageLimit,
        timesUsed: primary.timesUsed,
      ),
      ...state.skip(1),
    ];
    _persist();
  }

  void addCard({
    required String type,
    required String holder,
    required String currency,
    String? gradientKey,
    bool isDisposable = false,
  }) {
    final extraCount = state.where((c) => !c.isFree).length;
    LinearGradient gradient;
    if (gradientKey != null) {
      gradient = switch (gradientKey) {
        'primary' => AppColors.cardGradient,
        'purple'  => _purpleGradient,
        'gold'    => _goldGradient,
        'rose'    => const LinearGradient(colors: [Color(0xFFBE185D), Color(0xFF9D174D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        'blue'    => const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF1E40AF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        _         => _physicalGradient,
      };
    } else {
      gradient = _extraGradients[extraCount % _extraGradients.length];
    }
    final newCard = IssuedCard(
      id: 'card-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      last4: _generateLast4(),
      holder: holder,
      expiry: '12/28',
      currency: currency,
      isFree: false,
      gradient: gradient,
      isDisposable: isDisposable,
      usageLimit: isDisposable ? 1 : 0,
      timesUsed: 0,
    );
    state = [...state, newCard];
    _persist();
  }

  void removeCard(String id) {
    if (id == 'primary-virtual') return;
    state = state.where((c) => c.id != id).toList();
    _persist();
  }

  void toggleFreeze(String id) {
    // Freeze is stored as a naming convention in the holder field for now
    // In production this would be an API call
    state = state.map((c) {
      if (c.id != id) return c;
      final frozenPrefix = '[FROZEN] ';
      final newHolder = c.holder.startsWith(frozenPrefix)
          ? c.holder.substring(frozenPrefix.length)
          : '$frozenPrefix${c.holder}';
      return c.copyWith(holder: newHolder);
    }).toList();
    _persist();
  }

  void recordUsage(String id) {
    state = state.map((c) {
      if (c.id != id) return c;
      final used = c.timesUsed + 1;
      if (c.isDisposable && used >= c.usageLimit) {
        final frozenHolder = c.holder.startsWith('[FROZEN] ') ? c.holder : '[FROZEN] ${c.holder}';
        return IssuedCard(
          id: c.id, type: c.type, last4: c.last4,
          holder: frozenHolder, expiry: c.expiry, currency: c.currency,
          isFree: c.isFree, gradient: c.gradient,
          isDisposable: true, usageLimit: c.usageLimit, timesUsed: used,
        );
      }
      return c.copyWith(timesUsed: used);
    }).toList();
    _persist();
  }

  void updateCard(String id, {String? holder, String? gradientKey}) {
    state = state.map((c) {
      if (c.id != id) return c;
      LinearGradient grad = c.gradient;
      if (gradientKey != null) {
        grad = switch (gradientKey) {
          'primary' => AppColors.cardGradient,
          'purple'  => _purpleGradient,
          'gold'    => _goldGradient,
          'rose'    => const LinearGradient(colors: [Color(0xFFBE185D), Color(0xFF9D174D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          'blue'    => const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF1E40AF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          _         => _physicalGradient,
        };
      }
      return IssuedCard(
        id: c.id, type: c.type, last4: c.last4,
        holder: holder != null ? holder : c.holder,
        expiry: c.expiry, currency: c.currency, isFree: c.isFree,
        gradient: grad,
        isDisposable: c.isDisposable, usageLimit: c.usageLimit, timesUsed: c.timesUsed,
      );
    }).toList();
    _persist();
  }

  bool isFrozen(String id) {
    final card = state.where((c) => c.id == id).firstOrNull;
    return card?.holder.startsWith('[FROZEN] ') ?? false;
  }

  static String _generateLast4() {
    final n = DateTime.now().millisecondsSinceEpoch % 10000;
    return n.toString().padLeft(4, '0');
  }
}

final userCardsProvider =
    StateNotifierProvider<UserCardsNotifier, List<IssuedCard>>(
        (_) => UserCardsNotifier());

/// Monthly fee for each additional card beyond the free first card
const cardExtraFee = 3.99;
