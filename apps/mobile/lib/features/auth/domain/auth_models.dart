class UserModel {
  final String id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? countryCode;
  final String role;
  final String status;
  final bool twoFactorOn;
  final String kycStatus;
  final int kycLevel;
  final String? avatarUrl;
  final bool emailVerified;
  final String? dateOfBirth;
  final String? address;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.countryCode,
    required this.role,
    required this.status,
    required this.twoFactorOn,
    required this.kycStatus,
    required this.kycLevel,
    this.avatarUrl,
    this.emailVerified = false,
    this.dateOfBirth,
    this.address,
  });

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    email: json['email'] as String,
    username: json['username'] as String,
    firstName: json['first_name'] as String? ?? json['firstName'] as String? ?? '',
    lastName: json['last_name'] as String? ?? json['lastName'] as String? ?? '',
    phone: json['phone'] as String?,
    countryCode: json['country_code'] as String? ?? json['countryCode'] as String?,
    role: json['role'] as String? ?? 'user',
    status: json['status'] as String? ?? 'active',
    twoFactorOn: json['two_factor_on'] as bool? ?? json['twoFactorOn'] as bool? ?? false,
    kycStatus: json['kyc_status'] as String? ?? json['kycStatus'] as String? ?? 'none',
    kycLevel: json['kyc_level'] as int? ?? json['kycLevel'] as int? ?? 0,
    avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
    emailVerified: json['email_verified'] as bool? ?? json['emailVerified'] as bool? ?? false,
    dateOfBirth: json['date_of_birth'] as String? ?? json['dateOfBirth'] as String?,
    address: json['address'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'first_name': firstName,
    'last_name': lastName,
    'phone': phone,
    'country_code': countryCode,
    'role': role,
    'status': status,
    'two_factor_on': twoFactorOn,
    'kyc_status': kycStatus,
    'kyc_level': kycLevel,
    'avatar_url': avatarUrl,
    'email_verified': emailVerified,
    'date_of_birth': dateOfBirth,
    'address': address,
  };
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['access_token'] as String? ?? json['accessToken'] as String? ?? '',
    refreshToken: json['refresh_token'] as String? ?? json['refreshToken'] as String? ?? '',
    expiresIn: json['expires_in'] as int? ?? json['expiresIn'] as int? ?? 900,
  );
}
