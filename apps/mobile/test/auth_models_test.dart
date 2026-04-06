import 'package:flutter_test/flutter_test.dart';
import 'package:amixpay_app/features/auth/domain/auth_models.dart';

void main() {
  group('UserModel', () {
    test('fromJson parses user correctly', () {
      final json = {
        'id': 'user-123',
        'email': 'test@amixpay.com',
        'username': 'testuser',
        'first_name': 'Test',
        'last_name': 'User',
        'phone': '+1234567890',
        'country_code': 'US',
        'role': 'user',
        'status': 'active',
        'two_factor_on': false,
        'kyc_status': 'none',
        'kyc_level': 0,
        'avatar_url': null,
        'email_verified': true,
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 'user-123');
      expect(user.email, 'test@amixpay.com');
      expect(user.username, 'testuser');
      expect(user.firstName, 'Test');
      expect(user.lastName, 'User');
      expect(user.fullName, 'Test User');
      expect(user.role, 'user');
      expect(user.twoFactorOn, false);
      expect(user.emailVerified, true);
    });

    test('fromJson handles camelCase keys (Flutter-side)', () {
      final json = {
        'id': 'user-789',
        'email': 'camel@case.com',
        'username': 'camelcase',
        'firstName': 'Camel',
        'lastName': 'Case',
        'countryCode': 'NG',
        'role': 'merchant',
        'status': 'active',
        'twoFactorOn': true,
        'kycStatus': 'approved',
        'kycLevel': 3,
        'emailVerified': true,
      };

      final user = UserModel.fromJson(json);
      expect(user.firstName, 'Camel');
      expect(user.countryCode, 'NG');
      expect(user.twoFactorOn, true);
      expect(user.kycLevel, 3);
    });

    test('fromJson defaults missing fields gracefully', () {
      final json = {
        'id': 'minimal-001',
        'email': 'min@test.com',
        'username': 'minimal',
      };

      final user = UserModel.fromJson(json);
      expect(user.firstName, '');
      expect(user.lastName, '');
      expect(user.role, 'user');
      expect(user.status, 'active');
      expect(user.twoFactorOn, false);
      expect(user.kycStatus, 'none');
      expect(user.kycLevel, 0);
      expect(user.emailVerified, false);
      expect(user.phone, isNull);
      expect(user.avatarUrl, isNull);
    });

    test('toJson produces valid output', () {
      const user = UserModel(
        id: 'user-456',
        email: 'jane@amixpay.com',
        username: 'janedoe',
        firstName: 'Jane',
        lastName: 'Doe',
        phone: '+1987654321',
        countryCode: 'GB',
        role: 'user',
        status: 'active',
        twoFactorOn: true,
        kycStatus: 'approved',
        kycLevel: 2,
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      final json = user.toJson();
      expect(json['id'], 'user-456');
      expect(json['email'], 'jane@amixpay.com');
      expect(json['first_name'], 'Jane');
      expect(json['two_factor_on'], true);
      expect(json['kyc_level'], 2);
    });

    test('fromJson → toJson roundtrip preserves data', () {
      final original = {
        'id': 'roundtrip-001',
        'email': 'round@trip.com',
        'username': 'roundtrip',
        'first_name': 'Round',
        'last_name': 'Trip',
        'phone': null,
        'country_code': 'NG',
        'role': 'merchant',
        'status': 'active',
        'two_factor_on': false,
        'kyc_status': 'pending',
        'kyc_level': 1,
        'avatar_url': null,
        'email_verified': false,
      };

      final user = UserModel.fromJson(original);
      final rebuilt = user.toJson();

      expect(rebuilt['id'], original['id']);
      expect(rebuilt['email'], original['email']);
      expect(rebuilt['role'], original['role']);
      expect(rebuilt['kyc_level'], original['kyc_level']);
      expect(rebuilt['email_verified'], original['email_verified']);
    });
  });

  group('AuthTokens', () {
    test('fromJson parses snake_case tokens', () {
      final json = {
        'access_token': 'eyJhbGciOiJIUzI1NiJ9.test',
        'refresh_token': 'refresh_abc123',
        'expires_in': 900,
      };

      final tokens = AuthTokens.fromJson(json);
      expect(tokens.accessToken, 'eyJhbGciOiJIUzI1NiJ9.test');
      expect(tokens.refreshToken, 'refresh_abc123');
      expect(tokens.expiresIn, 900);
    });

    test('fromJson parses camelCase tokens', () {
      final json = {
        'accessToken': 'token_camel',
        'refreshToken': 'refresh_camel',
        'expiresIn': 1800,
      };

      final tokens = AuthTokens.fromJson(json);
      expect(tokens.accessToken, 'token_camel');
      expect(tokens.refreshToken, 'refresh_camel');
      expect(tokens.expiresIn, 1800);
    });

    test('fromJson defaults missing expiresIn to 900', () {
      final json = {
        'access_token': 'some_token',
        'refresh_token': 'some_refresh',
      };

      final tokens = AuthTokens.fromJson(json);
      expect(tokens.expiresIn, 900);
    });
  });
}
