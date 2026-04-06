import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class ReferralCode {
  final String code;
  final String link;
  final int totalReferrals;
  final double totalEarned;
  final String rewardCurrency;
  final double rewardPerReferral;

  const ReferralCode({
    required this.code, required this.link,
    required this.totalReferrals, required this.totalEarned,
    required this.rewardCurrency, required this.rewardPerReferral,
  });

  factory ReferralCode.fromJson(Map<String, dynamic> json) => ReferralCode(
    code: json['code'] as String,
    link: json['link'] as String,
    totalReferrals: json['totalReferrals'] as int? ?? 0,
    totalEarned: double.parse((json['totalEarned'] ?? 0).toString()),
    rewardCurrency: json['rewardCurrency'] as String? ?? 'USD',
    rewardPerReferral: double.parse((json['rewardPerReferral'] ?? 5).toString()),
  );
}

class ReferralFriend {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String status;
  final double rewardAmount;
  final String createdAt;

  const ReferralFriend({
    required this.id, required this.firstName, required this.lastName,
    this.avatarUrl, required this.status, required this.rewardAmount,
    required this.createdAt,
  });

  String get initials => '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();

  factory ReferralFriend.fromJson(Map<String, dynamic> json) => ReferralFriend(
    id: json['id'] as String,
    firstName: json['first_name'] as String? ?? '',
    lastName: json['last_name'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String?,
    status: json['status'] as String? ?? 'pending',
    rewardAmount: double.parse((json['reward_amount'] ?? 0).toString()),
    createdAt: json['created_at'] as String? ?? '',
  );
}

class ReferralRepository {
  final Dio _dio;
  ReferralRepository(this._dio);

  Future<ReferralCode> getMyCode() async {
    final res = await _dio.get('/referrals/my-code');
    return ReferralCode.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<List<ReferralFriend>> getReferrals() async {
    final res = await _dio.get('/referrals');
    final list = res.data['data'] as List<dynamic>? ?? [];
    return list.map((e) => ReferralFriend.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> applyCode(String code) async {
    await _dio.post('/referrals/apply', data: {'code': code});
  }
}

final referralRepositoryProvider = Provider<ReferralRepository>(
  (ref) => ReferralRepository(ApiClient.instance),
);

final referralCodeProvider = FutureProvider.autoDispose<ReferralCode>((ref) {
  return ref.read(referralRepositoryProvider).getMyCode();
});

final referralFriendsProvider = FutureProvider.autoDispose<List<ReferralFriend>>((ref) {
  return ref.read(referralRepositoryProvider).getReferrals();
});
