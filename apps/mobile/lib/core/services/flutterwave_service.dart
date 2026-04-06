import 'package:flutter/material.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Flutterwave Service
//
// PUBLIC KEY is the only credential that belongs in the Flutter client.
// Secret key + encryption key must live exclusively on the backend API.
//
// Set at build time with --dart-define:
//   flutter build apk \
//     --dart-define=FLW_PUBLIC_KEY=FLWPUBK-your-public-key-X
// ---------------------------------------------------------------------------

class FlutterwaveService {
  static const _publicKey = String.fromEnvironment(
    'FLW_PUBLIC_KEY',
    // Fallback to test-mode key for debug builds (safe — test keys can't charge real cards)
    defaultValue: 'FLWPUBK_TEST-986bf566cb0b4846ba4568613052b3ab-X',
  );

  static const bool _isTestMode = bool.fromEnvironment(
    'FLW_LIVE_MODE',
    defaultValue: false,
  );

  /// Launches the Flutterwave payment sheet and returns true if the payment
  /// was successful.
  ///
  /// [currency] — ISO 4217 currency code (e.g. "NGN", "GHS", "KES", "USD")
  /// [amount] — amount to charge (as a string to avoid floating-point issues)
  /// [email] — customer email
  /// [name] — customer full name
  /// [phone] — customer phone number (required for Mobile Money)
  /// [paymentOptions] — comma-separated: "card", "mobilemoneyrwanda", etc.
  static Future<bool> charge({
    required BuildContext context,
    required double amount,
    required String currency,
    required String email,
    required String name,
    String phone = '',
    String paymentOptions = 'card, mobilemoneyghana, mobilemoneyrwanda, '
        'mobilemoneyuganda, mobilemoneyfranco, ussd, banktransfer',
  }) async {
    final txRef = 'amixpay-${const Uuid().v4()}';

    final customer = Customer(
      name: name,
      phoneNumber: phone,
      email: email,
    );

    final flutterwave = Flutterwave(
      publicKey: _publicKey,
      currency: currency,
      redirectUrl: 'https://amixpay.com/payment/callback',
      txRef: txRef,
      amount: amount.toStringAsFixed(2),
      customer: customer,
      paymentOptions: paymentOptions,
      customization: Customization(
        title: 'AmixPay',
        description: 'Fund your AmixPay wallet',
        logo: 'https://amixpay.com/logo.png',
      ),
      isTestMode: !_isTestMode,
    );

    try {
      final response = await flutterwave.charge(context);

      if (response == null) return false;

      // status == "successful" and txRef matches — payment done
      if (response.status == 'successful' &&
          response.txRef == txRef &&
          response.success == true) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Returns the best payment options string for a given currency.
  /// African currencies default to Mobile Money + card, others card only.
  static String paymentOptionsFor(String currency) {
    const mobileMoneyMap = {
      'NGN': 'card, ussd, banktransfer',
      'GHS': 'card, mobilemoneyghana',
      'KES': 'card, mpesa',
      'UGX': 'card, mobilemoneyuganda',
      'RWF': 'card, mobilemoneyrwanda',
      'ZMW': 'card, mobilemoneyzambia',
      'TZS': 'card, mobilemoneytanzania',
      'XAF': 'card, mobilemoneyfranco',
      'XOF': 'card, mobilemoneyfranco',
      'EGP': 'card',
      'ZAR': 'card',
    };
    return mobileMoneyMap[currency] ?? 'card';
  }
}
