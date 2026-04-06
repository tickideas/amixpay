import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/wallet/data/wallet_repository.dart';
import '../../features/wallet/domain/wallet_models.dart';

class WalletNotifier extends AsyncNotifier<WalletModel?> {
  @override
  Future<WalletModel?> build() async {
    try {
      return await ref.read(walletRepositoryProvider).getWallet();
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final wallet = await ref.read(walletRepositoryProvider).getWallet();
      state = AsyncData(wallet);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// Immediately credits [amount] to [currency] in local state (optimistic update).
  void addFunds(String currency, double amount) {
    final current = state.value;
    if (current == null) return;
    final updatedCurrencies = current.currencies.map((c) {
      if (c.currencyCode == currency) {
        return WalletCurrency(
          currencyCode: c.currencyCode,
          balance: c.balance + amount,
          availableBalance: c.availableBalance + amount,
        );
      }
      return c;
    }).toList();
    // If currency not in wallet yet, add it
    if (!updatedCurrencies.any((c) => c.currencyCode == currency)) {
      updatedCurrencies.add(WalletCurrency(
        currencyCode: currency,
        balance: amount,
        availableBalance: amount,
      ));
    }
    state = AsyncData(WalletModel(
      id: current.id,
      userId: current.userId,
      primaryCurrency: current.primaryCurrency,
      currencies: updatedCurrencies,
    ));
  }

  Future<void> addCurrency(String code) async {
    try {
      final wallet = await ref.read(walletRepositoryProvider).addCurrency(code);
      state = AsyncData(wallet);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> removeCurrency(String code) async {
    try {
      await ref.read(walletRepositoryProvider).removeCurrency(code);
      await refresh();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

final walletProvider = AsyncNotifierProvider<WalletNotifier, WalletModel?>(WalletNotifier.new);

final transactionsProvider = FutureProvider.family<List<TransactionModel>, ({int offset, String? type, String? currency})>(
  (ref, params) => ref.read(walletRepositoryProvider).getTransactions(
    limit: 20, offset: params.offset, type: params.type, currency: params.currency,
  ),
);

final recentTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) {
  return ref.read(walletRepositoryProvider).getTransactions(limit: 10, offset: 0);
});
