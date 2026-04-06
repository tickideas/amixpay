import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class SavingsGoalModel {
  final String id;
  final String name;
  final String emoji;
  final double targetAmount;
  final double savedAmount;
  final String currencyCode;
  final String? targetDate;
  final int colorIndex;
  final String status;

  const SavingsGoalModel({
    required this.id, required this.name, required this.emoji,
    required this.targetAmount, required this.savedAmount,
    required this.currencyCode, this.targetDate,
    required this.colorIndex, required this.status,
  });

  double get progress => targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0;
  double get remaining => (targetAmount - savedAmount).clamp(0, double.infinity);
  bool get isCompleted => savedAmount >= targetAmount;

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) => SavingsGoalModel(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String? ?? '🎯',
    targetAmount: double.parse(json['target_amount'].toString()),
    savedAmount: double.parse(json['saved_amount'].toString()),
    currencyCode: json['currency_code'] as String? ?? 'USD',
    targetDate: json['target_date'] as String?,
    colorIndex: json['color_index'] as int? ?? 0,
    status: json['status'] as String? ?? 'active',
  );
}

class SavingsRepository {
  final Dio _dio;
  SavingsRepository(this._dio);

  Future<List<SavingsGoalModel>> getGoals() async {
    final res = await _dio.get('/savings');
    final list = res.data['data'] as List<dynamic>? ?? [];
    return list.map((e) => SavingsGoalModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SavingsGoalModel> createGoal({
    required String name, required double targetAmount,
    required String currencyCode, String? targetDate,
    String emoji = '🎯', int colorIndex = 0,
  }) async {
    final res = await _dio.post('/savings', data: {
      'name': name, 'targetAmount': targetAmount,
      'currencyCode': currencyCode,
      if (targetDate != null) 'targetDate': targetDate,
      'emoji': emoji, 'colorIndex': colorIndex,
    });
    return SavingsGoalModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<SavingsGoalModel> deposit(String goalId, double amount) async {
    final res = await _dio.post('/savings/$goalId/deposit', data: {'amount': amount});
    return SavingsGoalModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<SavingsGoalModel> withdraw(String goalId, double amount) async {
    final res = await _dio.post('/savings/$goalId/withdraw', data: {'amount': amount});
    return SavingsGoalModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteGoal(String goalId) async {
    await _dio.delete('/savings/$goalId');
  }
}

final savingsRepositoryProvider = Provider<SavingsRepository>(
  (ref) => SavingsRepository(ApiClient.instance),
);

final savingsGoalsProvider = FutureProvider.autoDispose<List<SavingsGoalModel>>((ref) {
  return ref.read(savingsRepositoryProvider).getGoals();
});
