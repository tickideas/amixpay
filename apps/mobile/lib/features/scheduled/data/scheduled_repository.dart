import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class ScheduledTransferModel {
  final String id;
  final String recipientIdentifier;
  final String? recipientName;
  final double amount;
  final String currencyCode;
  final String? description;
  final String frequency;
  final String nextRunDate;
  final String? endDate;
  final int completedRuns;
  final String status;

  const ScheduledTransferModel({
    required this.id, required this.recipientIdentifier,
    this.recipientName, required this.amount,
    required this.currencyCode, this.description,
    required this.frequency, required this.nextRunDate,
    this.endDate, required this.completedRuns,
    required this.status,
  });

  String get frequencyLabel {
    switch (frequency) {
      case 'once': return 'One-time';
      case 'daily': return 'Daily';
      case 'weekly': return 'Weekly';
      case 'biweekly': return 'Bi-weekly';
      case 'monthly': return 'Monthly';
      default: return frequency;
    }
  }

  bool get isActive => status == 'active';

  factory ScheduledTransferModel.fromJson(Map<String, dynamic> json) => ScheduledTransferModel(
    id: json['id'] as String,
    recipientIdentifier: json['recipient_identifier'] as String,
    recipientName: json['recipient_name'] as String?,
    amount: double.parse(json['amount'].toString()),
    currencyCode: json['currency_code'] as String? ?? 'USD',
    description: json['description'] as String?,
    frequency: json['frequency'] as String,
    nextRunDate: json['next_run_date'] as String,
    endDate: json['end_date'] as String?,
    completedRuns: json['completed_runs'] as int? ?? 0,
    status: json['status'] as String? ?? 'active',
  );
}

class ScheduledRepository {
  final Dio _dio;
  ScheduledRepository(this._dio);

  Future<List<ScheduledTransferModel>> getAll() async {
    final res = await _dio.get('/scheduled');
    final list = res.data['data'] as List<dynamic>? ?? [];
    return list.map((e) => ScheduledTransferModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ScheduledTransferModel> create({
    required String recipient, required double amount,
    required String currencyCode, required String frequency,
    required String nextRunDate, String? endDate, String? description,
  }) async {
    final res = await _dio.post('/scheduled', data: {
      'recipient': recipient, 'amount': amount,
      'currencyCode': currencyCode, 'frequency': frequency,
      'nextRunDate': nextRunDate,
      if (endDate != null) 'endDate': endDate,
      if (description != null) 'description': description,
    });
    return ScheduledTransferModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> pause(String id) async {
    await _dio.patch('/scheduled/$id', data: {'status': 'paused'});
  }

  Future<void> resume(String id) async {
    await _dio.patch('/scheduled/$id', data: {'status': 'active'});
  }

  Future<void> cancel(String id) async {
    await _dio.delete('/scheduled/$id');
  }
}

final scheduledRepositoryProvider = Provider<ScheduledRepository>(
  (ref) => ScheduledRepository(ApiClient.instance),
);

final scheduledTransfersProvider = FutureProvider.autoDispose<List<ScheduledTransferModel>>((ref) {
  return ref.read(scheduledRepositoryProvider).getAll();
});
