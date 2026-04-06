import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/secure_storage.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class AppSettings {
  final bool pushNotifications;
  final bool smsAlerts;
  final bool emailNotifications;
  final String languageCode;   // BCP47, e.g. 'en', 'fr'
  final String countryCode;    // ISO alpha-2, e.g. 'US', 'NG'
  final String displayCurrency; // e.g. 'USD', 'NGN'

  const AppSettings({
    this.pushNotifications = true,
    this.smsAlerts = true,
    this.emailNotifications = false,
    this.languageCode = 'en',
    this.countryCode = 'US',
    this.displayCurrency = 'USD',
  });

  AppSettings copyWith({
    bool? pushNotifications,
    bool? smsAlerts,
    bool? emailNotifications,
    String? languageCode,
    String? countryCode,
    String? displayCurrency,
  }) => AppSettings(
    pushNotifications: pushNotifications ?? this.pushNotifications,
    smsAlerts: smsAlerts ?? this.smsAlerts,
    emailNotifications: emailNotifications ?? this.emailNotifications,
    languageCode: languageCode ?? this.languageCode,
    countryCode: countryCode ?? this.countryCode,
    displayCurrency: displayCurrency ?? this.displayCurrency,
  );

  Map<String, dynamic> toJson() => {
    'pushNotifications': pushNotifications,
    'smsAlerts': smsAlerts,
    'emailNotifications': emailNotifications,
    'languageCode': languageCode,
    'countryCode': countryCode,
    'displayCurrency': displayCurrency,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    pushNotifications: json['pushNotifications'] as bool? ?? true,
    smsAlerts: json['smsAlerts'] as bool? ?? true,
    emailNotifications: json['emailNotifications'] as bool? ?? false,
    languageCode: json['languageCode'] as String? ?? 'en',
    countryCode: json['countryCode'] as String? ?? 'US',
    displayCurrency: json['displayCurrency'] as String? ?? 'USD',
  );

  /// Auto-detect settings from the device locale on first launch.
  factory AppSettings.fromDeviceLocale() {
    final locale = ui.PlatformDispatcher.instance.locale;
    final langCode = locale.languageCode;
    final countryCode = locale.countryCode ?? 'US';
    final currency = _countryToCurrency[countryCode] ?? 'USD';
    return AppSettings(
      languageCode: langCode,
      countryCode: countryCode,
      displayCurrency: currency,
    );
  }

  String get languageLabel => _langLabels[languageCode] ?? languageCode.toUpperCase();
  String get countryLabel => _countryLabels[countryCode] ?? countryCode;
}

// ── Country → Currency mapping ────────────────────────────────────────────────
const _countryToCurrency = {
  'US': 'USD', 'CA': 'CAD', 'GB': 'GBP',
  'DE': 'EUR', 'FR': 'EUR', 'IT': 'EUR', 'ES': 'EUR', 'NL': 'EUR',
  'BE': 'EUR', 'PT': 'EUR', 'AT': 'EUR', 'IE': 'EUR', 'FI': 'EUR',
  'AU': 'AUD', 'NZ': 'NZD', 'JP': 'JPY', 'CN': 'CNY', 'IN': 'INR',
  'NG': 'NGN', 'GH': 'GHS', 'KE': 'KES', 'ZA': 'ZAR', 'UG': 'UGX',
  'TZ': 'TZS', 'EG': 'EGP', 'MA': 'MAD',
  'BR': 'BRL', 'MX': 'MXN', 'AR': 'ARS', 'CO': 'COP', 'CL': 'CLP',
  'AE': 'AED', 'SA': 'SAR', 'QA': 'QAR', 'SG': 'SGD', 'HK': 'HKD',
  'MY': 'MYR', 'PH': 'PHP', 'TH': 'THB', 'ID': 'IDR',
  'CH': 'CHF', 'SE': 'SEK', 'NO': 'NOK', 'DK': 'DKK', 'PL': 'PLN',
  'TR': 'TRY', 'KR': 'KRW', 'PK': 'PKR', 'BD': 'BDT', 'LK': 'LKR',
};

const _langLabels = {
  'en': 'English', 'fr': 'Français', 'de': 'Deutsch', 'es': 'Español',
  'pt': 'Português', 'ar': 'العربية', 'zh': '中文', 'hi': 'हिन्दी',
  'yo': 'Yorùbá', 'ig': 'Igbo', 'ha': 'Hausa', 'sw': 'Kiswahili',
};

const _countryLabels = {
  'US': 'United States', 'GB': 'United Kingdom', 'NG': 'Nigeria',
  'GH': 'Ghana', 'KE': 'Kenya', 'ZA': 'South Africa', 'CA': 'Canada',
  'AU': 'Australia', 'DE': 'Germany', 'FR': 'France', 'IN': 'India',
};

// ── Notifier ──────────────────────────────────────────────────────────────────

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await SecureStorage.getSettings();
      if (raw != null && raw.isNotEmpty) {
        state = AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } else {
        // First launch: auto-detect from device
        state = AppSettings.fromDeviceLocale();
        await _persist();
      }
    } catch (_) {
      state = AppSettings.fromDeviceLocale();
    }
  }

  Future<void> _persist() async {
    await SecureStorage.saveSettings(jsonEncode(state.toJson()));
  }

  Future<void> setPushNotifications(bool v) async {
    state = state.copyWith(pushNotifications: v);
    await _persist();
  }

  Future<void> setSmsAlerts(bool v) async {
    state = state.copyWith(smsAlerts: v);
    await _persist();
  }

  Future<void> setEmailNotifications(bool v) async {
    state = state.copyWith(emailNotifications: v);
    await _persist();
  }

  Future<void> setLanguage(String code) async {
    state = state.copyWith(languageCode: code);
    await _persist();
  }

  Future<void> setCountry(String code) async {
    final currency = _countryToCurrency[code] ?? state.displayCurrency;
    state = state.copyWith(countryCode: code, displayCurrency: currency);
    await _persist();
  }

  Future<void> setDisplayCurrency(String code) async {
    state = state.copyWith(displayCurrency: code);
    await _persist();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (_) => SettingsNotifier(),
);
