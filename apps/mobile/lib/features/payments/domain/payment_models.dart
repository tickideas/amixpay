class PaymentModel {
  final String id;
  final String senderId;
  final String recipientId;
  final double amount;
  final double fee;
  final String currencyCode;
  final String status;
  final String? note;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.amount,
    required this.fee,
    required this.currencyCode,
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
    id: json['id'] as String,
    senderId: json['sender_id'] as String? ?? '',
    recipientId: json['recipient_id'] as String? ?? '',
    amount: double.tryParse(json['amount'].toString()) ?? 0,
    fee: double.tryParse(json['fee']?.toString() ?? '0') ?? 0,
    currencyCode: json['currency_code'] as String? ?? 'USD',
    status: json['status'] as String? ?? 'completed',
    note: json['note'] as String?,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}

class PaymentRequestModel {
  final String id;
  final String requesterId;
  final String payerId;
  final double amount;
  final String currencyCode;
  final String status;
  final String? note;
  final DateTime createdAt;
  final String? requesterUsername;
  final String? payerUsername;

  const PaymentRequestModel({
    required this.id,
    required this.requesterId,
    required this.payerId,
    required this.amount,
    required this.currencyCode,
    required this.status,
    this.note,
    required this.createdAt,
    this.requesterUsername,
    this.payerUsername,
  });

  factory PaymentRequestModel.fromJson(Map<String, dynamic> json) => PaymentRequestModel(
    id: json['id'] as String,
    requesterId: json['requester_id'] as String? ?? '',
    payerId: json['payer_id'] as String? ?? '',
    amount: double.tryParse(json['amount'].toString()) ?? 0,
    currencyCode: json['currency_code'] as String? ?? 'USD',
    status: json['status'] as String? ?? 'pending',
    note: json['note'] as String?,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    requesterUsername: json['requester_username'] as String?,
    payerUsername: json['payer_username'] as String?,
  );
}
