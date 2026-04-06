import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

/// Cached mid-market rates (USD base) — used as fallback when API is
/// unavailable. Updated to March 2026 market levels.
const fallbackRates = <String, double>{
  'USD': 1.0,    'GBP': 0.790,  'EUR': 0.920,  'CAD': 1.360,  'AUD': 1.540,
  'NZD': 1.690,  'CHF': 0.900,  'JPY': 149.50, 'CNY': 7.240,  'KRW': 1325.0,
  'SGD': 1.340,  'HKD': 7.820,  'TWD': 31.50,  'INR': 83.50,  'PKR': 279.0,
  'BDT': 110.0,  'LKR': 325.0,  'NPR': 133.0,  'THB': 35.40,  'MYR': 4.720,
  'IDR': 15600.0,'PHP': 57.50,  'VND': 24800.0,'NGN': 1580.0, 'GHS': 15.80,
  'KES': 130.0,  'ZAR': 18.70,  'TZS': 2700.0, 'UGX': 3750.0, 'RWF': 1350.0,
  'ETB': 57.0,   'XOF': 605.0,  'XAF': 605.0,  'EGP': 48.50,  'MAD': 10.00,
  'TND': 3.12,   'ZMW': 26.80,  'MZN': 64.0,   'MWK': 1720.0, 'BRL': 4.970,
  'ARS': 875.0,  'COP': 3980.0, 'CLP': 960.0,  'PEN': 3.720,  'MXN': 17.20,
  'UYU': 39.50,  'BOB': 6.910,  'VES': 36.50,  'GYD': 209.0,  'SRD': 37.20,
  'PYG': 7450.0, 'SEK': 10.50,  'NOK': 10.80,  'DKK': 6.870,  'PLN': 4.070,
  'CZK': 23.20,  'HUF': 364.0,  'RON': 4.580,  'BGN': 1.800,  'AED': 3.670,
  'SAR': 3.750,  'QAR': 3.640,  'KWD': 0.307,  'BHD': 0.377,  'ILS': 3.750,
  'TRY': 32.50,
};

/// Holds fetched rates + metadata for UI display.
class ExchangeRates {
  final Map<String, double> rates;
  final DateTime fetchedAt;
  final bool isLive;

  const ExchangeRates({
    required this.rates,
    required this.fetchedAt,
    required this.isLive,
  });

  /// Convert [amount] from [from] currency to [to] currency.
  double convert(double amount, String from, String to) {
    final fromRate = rates[from] ?? 1.0;
    final toRate = rates[to] ?? 1.0;
    return amount * (toRate / fromRate);
  }

  /// e.g. "1 USD = 1,580 NGN"
  String rateLabel(String from, String to) {
    final fromRate = rates[from] ?? 1.0;
    final toRate = rates[to] ?? 1.0;
    final rate = toRate / fromRate;
    if (rate >= 1000) return '1 $from = ${rate.toStringAsFixed(0)} $to';
    if (rate >= 100)  return '1 $from = ${rate.toStringAsFixed(1)} $to';
    if (rate >= 1)    return '1 $from = ${rate.toStringAsFixed(4)} $to';
    return '1 $to = ${(1 / rate).toStringAsFixed(4)} $from';
  }
}

/// Fetches live rates from Open Exchange Rates (free tier).
/// Falls back to [fallbackRates] on any error.
///
/// In production: replace APP_ID with real key from openexchangerates.org
/// or route through the backend `/v1/exchange-rates` endpoint.
class ExchangeRateService {
  static const _appId = String.fromEnvironment('OXR_APP_ID', defaultValue: 'bda60ab884f4457882e56600f8834315');
  static const _apiUrl = 'https://openexchangerates.org/api/latest.json';

  // Cache to avoid hammering the API
  static ExchangeRates? _cache;
  static DateTime? _lastFetch;
  static const _cacheDuration = Duration(minutes: 10);

  static Future<ExchangeRates> getRates() async {
    // Return cache if fresh
    if (_cache != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      return _cache!;
    }

    // Don't attempt API call with placeholder key
    if (_appId == 'YOUR_OPEN_EXCHANGE_RATES_APP_ID') {
      return _fallback();
    }

    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));
      final response = await dio.get(_apiUrl, queryParameters: {
        'app_id': _appId,
        'base': 'USD',
      });
      if (response.statusCode == 200 && response.data != null) {
        final raw = Map<String, dynamic>.from(response.data['rates'] as Map);
        final rates = <String, double>{
          'USD': 1.0,
          ...raw.map((k, v) => MapEntry(k, (v as num).toDouble())),
        };
        final result = ExchangeRates(
          rates: rates,
          fetchedAt: DateTime.now(),
          isLive: true,
        );
        _cache = result;
        _lastFetch = DateTime.now();
        return result;
      }
    } catch (_) {
      // Network error — fall back to static rates silently
    }
    return _fallback();
  }

  static ExchangeRates _fallback() => ExchangeRates(
        rates: fallbackRates,
        fetchedAt: DateTime(2026, 3, 16),
        isLive: false,
      );
}

/// Riverpod provider — auto-fetches on first use.
/// Exposes [AsyncValue<ExchangeRates>] to widgets.
final exchangeRatesProvider = FutureProvider.autoDispose<ExchangeRates>((ref) {
  return ExchangeRateService.getRates();
});
