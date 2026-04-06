import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  // Internal storage instance, exposed for services that need direct key access
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _accessToken = 'access_token';
  static const _refreshToken = 'refresh_token';
  static const _userId = 'user_id';
  static const _userJson = 'user_json';

  static Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await Future.wait([
      _storage.write(key: _accessToken, value: accessToken),
      _storage.write(key: _refreshToken, value: refreshToken),
    ]);
  }

  static Future<String?> getAccessToken() => _storage.read(key: _accessToken);
  static Future<String?> getRefreshToken() => _storage.read(key: _refreshToken);
  static Future<String?> getUserId() => _storage.read(key: _userId);

  static Future<void> saveUserId(String id) => _storage.write(key: _userId, value: id);

  static Future<void> saveUserJson(String json) => _storage.write(key: _userJson, value: json);
  static Future<String?> getUserJson() => _storage.read(key: _userJson);

  static const _walletCurrencies = 'wallet_currencies_json';
  static Future<void> saveWalletCurrencies(String json) =>
      _storage.write(key: _walletCurrencies, value: json);
  static Future<String?> getWalletCurrencies() =>
      _storage.read(key: _walletCurrencies);

  static const _transactions = 'transactions_json';
  static Future<void> saveTransactions(String json) =>
      _storage.write(key: _transactions, value: json);
  static Future<String?> getTransactions() =>
      _storage.read(key: _transactions);

  static const _settings = 'app_settings_json';
  static Future<void> saveSettings(String json) =>
      _storage.write(key: _settings, value: json);
  static Future<String?> getSettings() =>
      _storage.read(key: _settings);

  static const _favouriteCountries = 'favourite_countries_json';
  static Future<void> saveFavouriteCountries(String json) =>
      _storage.write(key: _favouriteCountries, value: json);
  static Future<String?> getFavouriteCountries() =>
      _storage.read(key: _favouriteCountries);

  static const _issuedCards = 'issued_cards_json';
  static Future<void> saveIssuedCards(String json) =>
      _storage.write(key: _issuedCards, value: json);
  static Future<String?> getIssuedCards() =>
      _storage.read(key: _issuedCards);

  static const _savedRecipients = 'saved_recipients_json';
  static Future<void> saveRecipients(String json) =>
      _storage.write(key: _savedRecipients, value: json);
  static Future<String?> getRecipients() =>
      _storage.read(key: _savedRecipients);

  static const _savingsGoals = 'savings_goals_json';
  static Future<void> saveSavingsGoals(String json) =>
      _storage.write(key: _savingsGoals, value: json);
  static Future<String?> getSavingsGoals() =>
      _storage.read(key: _savingsGoals);

  static const _savedPaymentCards = 'saved_payment_cards_json';
  static Future<void> saveSavedPaymentCards(String json) =>
      _storage.write(key: _savedPaymentCards, value: json);
  static Future<String?> getSavedPaymentCards() =>
      _storage.read(key: _savedPaymentCards);

  static Future<void> clearAll() async {
    await Future.wait([
      _storage.delete(key: _accessToken),
      _storage.delete(key: _refreshToken),
      _storage.delete(key: _userId),
      _storage.delete(key: _userJson),
      _storage.delete(key: _transactions),
      // wallet_currencies intentionally kept: user's added currencies persist across logout
      // _settings intentionally kept: user preferences persist across logout
    ]);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
