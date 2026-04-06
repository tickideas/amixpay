class WalletCurrency {
  final String currencyCode;
  final double balance;
  final double availableBalance;

  const WalletCurrency({
    required this.currencyCode,
    required this.balance,
    required this.availableBalance,
  });

  factory WalletCurrency.fromJson(Map<String, dynamic> json) => WalletCurrency(
    currencyCode: json['currency_code'] as String,
    balance: double.tryParse(json['balance'].toString()) ?? 0,
    availableBalance: double.tryParse(json['available_balance'].toString()) ?? 0,
  );
}

class WalletModel {
  final String id;
  final String userId;
  final String primaryCurrency;
  final List<WalletCurrency> currencies;

  const WalletModel({
    required this.id,
    required this.userId,
    required this.primaryCurrency,
    required this.currencies,
  });

  double balanceFor(String code) =>
      currencies.firstWhere((c) => c.currencyCode == code, orElse: () => WalletCurrency(currencyCode: code, balance: 0, availableBalance: 0)).balance;

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    primaryCurrency: json['primary_currency'] as String? ?? 'USD',
    currencies: (json['currencies'] as List<dynamic>? ?? [])
        .map((c) => WalletCurrency.fromJson(c as Map<String, dynamic>))
        .toList(),
  );
}

class TransactionModel {
  final String id;
  final String type;
  final String status;
  final double amount;
  final double fee;
  final String currencyCode;
  final String? note;
  final String? counterpartyName;
  final String? counterpartyEmail;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.fee,
    required this.currencyCode,
    this.note,
    this.counterpartyName,
    this.counterpartyEmail,
    required this.createdAt,
  });

  bool get isCredit => type == 'credit' || type == 'receive' || type == 'deposit' || type == 'refund';
  String get displaySign => isCredit ? '+' : '-';

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
    id: json['id'] as String,
    type: json['type'] as String? ?? 'debit',
    status: json['status'] as String? ?? 'completed',
    amount: double.tryParse(json['amount'].toString()) ?? 0,
    fee: double.tryParse(json['fee']?.toString() ?? '0') ?? 0,
    currencyCode: json['currency_code'] as String? ?? json['currency'] as String? ?? 'USD',
    note: json['note'] as String?,
    counterpartyName: json['counterparty_name'] as String?,
    counterpartyEmail: json['counterparty_email'] as String?,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}
