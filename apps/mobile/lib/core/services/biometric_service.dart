import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:convert';
import 'dart:math';

/// Biometric / quick-access authentication service.
///
/// Uses local_auth for Face ID / Touch ID / Fingerprint on native.
/// Falls back to encrypted 6-digit PIN on web / desktop.
class BiometricService {
  static const _storage = FlutterSecureStorage();
  static const _pinKey = 'amixpay_quick_pin_hash';
  static const _pinSaltKey = 'amixpay_quick_pin_salt';
  static const _biometricEnabledKey = 'amixpay_biometric_enabled';

  static final _localAuth = LocalAuthentication();

  // ── Availability ────────────────────────────────────────────────────────

  /// Returns true if device biometrics are enrolled and available.
  static Future<bool> isAvailable() async {
    if (kIsWeb) return true; // PIN always available on web
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Returns which biometric types are enrolled (fingerprint, face, iris).
  static Future<List<BiometricType>> availableTypes() async {
    if (kIsWeb) return [];
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isEnabled() async {
    final val = await _storage.read(key: _biometricEnabledKey);
    return val == 'true';
  }

  static Future<void> setEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  // ── PIN management ───────────────────────────────────────────────────────

  static Future<bool> hasPinSet() async {
    final hash = await _storage.read(key: _pinKey);
    return hash != null && hash.isNotEmpty;
  }

  static Future<void> setPin(String pin) async {
    final salt = _randomSalt();
    final hash = _hashPin(pin, salt);
    await _storage.write(key: _pinSaltKey, value: salt);
    await _storage.write(key: _pinKey, value: hash);
    await setEnabled(true);
  }

  static Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _pinSaltKey);
    final stored = await _storage.read(key: _pinKey);
    if (salt == null || stored == null) return false;
    return _hashPin(pin, salt) == stored;
  }

  static Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _pinSaltKey);
    await setEnabled(false);
  }

  // ── Native biometric auth ────────────────────────────────────────────────

  /// Authenticate using device biometrics (Face ID / fingerprint / iris).
  /// Returns true on success. Returns false on failure or cancellation.
  static Future<bool> authenticateWithBiometrics({
    String reason = 'Confirm your identity to access AmixPay',
  }) async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,   // allow device PIN as fallback
          stickyAuth: true,       // stay active if user switches apps briefly
          sensitiveTransaction: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Stop any in-progress biometric prompt.
  static Future<void> stopAuthentication() async {
    if (kIsWeb) return;
    try {
      await _localAuth.stopAuthentication();
    } catch (_) {}
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _randomSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _hashPin(String pin, String salt) {
    Uint8List hash = Uint8List.fromList(utf8.encode('$salt:$pin'));
    for (int i = 0; i < 10000; i++) {
      final combined = [...hash, ...utf8.encode(salt)];
      hash = Uint8List.fromList(List<int>.generate(32, (j) =>
          combined[j % combined.length] ^ combined[(j + 7) % combined.length]));
    }
    return base64Url.encode(hash);
  }

  // ── Display labels ───────────────────────────────────────────────────────

  static String get biometricLabel {
    if (kIsWeb) return 'Quick PIN';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'Face ID' : 'Fingerprint';
  }

  static String get biometricIcon {
    if (kIsWeb) return '🔢';
    return defaultTargetPlatform == TargetPlatform.iOS ? '👤' : '👆';
  }
}
