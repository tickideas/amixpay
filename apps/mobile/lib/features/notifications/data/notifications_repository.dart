import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final String? readAt;
  final String createdAt;

  const NotificationModel({
    required this.id, required this.type, required this.title,
    required this.body, required this.data, required this.read,
    this.readAt, required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['id'] as String,
    type: json['type'] as String? ?? 'system',
    title: json['title'] as String,
    body: json['body'] as String,
    data: json['data'] as Map<String, dynamic>? ?? {},
    read: json['read'] as bool? ?? false,
    readAt: json['read_at'] as String?,
    createdAt: json['created_at'] as String? ?? '',
  );
}

class NotificationsRepository {
  final Dio _dio;
  NotificationsRepository(this._dio);

  Future<List<NotificationModel>> getAll() async {
    final res = await _dio.get('/notifications');
    final list = res.data['data'] as List<dynamic>? ?? [];
    return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markRead(String id) async {
    await _dio.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.post('/notifications/read-all');
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ApiClient.instance),
);

final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) {
  return ref.read(notificationsRepositoryProvider).getAll();
});
