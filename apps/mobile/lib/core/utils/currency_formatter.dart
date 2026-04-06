import 'package:intl/intl.dart';

/// Returns the flag emoji for a given currency code.
String currencyFlag(String code) {
  const flags = {
    'USD': '🇺🇸', 'CAD': '🇨🇦', 'AUD': '🇦🇺', 'NZD': '🇳🇿',
    'GBP': '🇬🇧', 'EUR': '🇪🇺', 'CHF': '🇨🇭',
    'JPY': '🇯🇵', 'CNY': '🇨🇳', 'KRW': '🇰🇷', 'HKD': '🇭🇰',
    'SGD': '🇸🇬', 'MYR': '🇲🇾', 'THB': '🇹🇭', 'IDR': '🇮🇩',
    'PHP': '🇵🇭', 'VND': '🇻🇳', 'BDT': '🇧🇩', 'PKR': '🇵🇰',
    'INR': '🇮🇳', 'LKR': '🇱🇰', 'NPR': '🇳🇵', 'TWD': '🇹🇼',
    'AED': '🇦🇪', 'SAR': '🇸🇦', 'QAR': '🇶🇦', 'ILS': '🇮🇱', 'TRY': '🇹🇷',
    'NGN': '🇳🇬', 'GHS': '🇬🇭', 'KES': '🇰🇪', 'ZAR': '🇿🇦',
    'UGX': '🇺🇬', 'TZS': '🇹🇿', 'ETB': '🇪🇹', 'RWF': '🇷🇼',
    'ZMW': '🇿🇲', 'MAD': '🇲🇦', 'EGP': '🇪🇬', 'MZN': '🇲🇿',
    'XAF': '🌍', 'XOF': '🌍', 'ZWL': '🇿🇼', 'MWK': '🇲🇼',
    'BRL': '🇧🇷', 'ARS': '🇦🇷', 'CLP': '🇨🇱', 'COP': '🇨🇴',
    'PEN': '🇵🇪', 'MXN': '🇲🇽', 'UYU': '🇺🇾', 'BOB': '🇧🇴',
    'VES': '🇻🇪', 'PYG': '🇵🇾', 'GYD': '🇬🇾', 'SRD': '🇸🇷',
    'SEK': '🇸🇪', 'NOK': '🇳🇴', 'DKK': '🇩🇰', 'PLN': '🇵🇱',
    'CZK': '🇨🇿', 'HUF': '🇭🇺', 'RON': '🇷🇴', 'BGN': '🇧🇬',
  };
  return flags[code] ?? '🌐';
}

class CurrencyFormatter {
  static const _symbols = {
    'USD': r'$', 'EUR': '€', 'GBP': '£', 'JPY': '¥', 'CAD': 'C\$',
    'AUD': 'A\$', 'CHF': 'Fr', 'CNY': '¥', 'NGN': '₦', 'KES': 'KSh',
    'GHS': '₵', 'ZAR': 'R', 'INR': '₹', 'BRL': 'R\$',
    'SGD': 'S\$', 'HKD': 'HK\$', 'MXN': 'MX\$', 'NZD': 'NZ\$',
    'SEK': 'kr', 'NOK': 'kr', 'DKK': 'kr', 'PLN': 'zł', 'CZK': 'Kč',
    'HUF': 'Ft', 'RON': 'lei', 'TRY': '₺', 'ILS': '₪', 'AED': 'AED',
    'SAR': 'SAR', 'KRW': '₩', 'THB': '฿', 'VND': '₫', 'IDR': 'Rp',
    'MYR': 'RM', 'PHP': '₱', 'PKR': '₨', 'BDT': '৳', 'UGX': 'USh',
    'TZS': 'TSh', 'ETB': 'Br', 'RWF': 'RF', 'ZMW': 'ZK', 'MAD': 'MAD',
    'EGP': 'E£', 'ARS': 'ARS\$', 'CLP': 'CL\$', 'COP': 'COP\$',
    'PEN': 'S/', 'UYU': '\$U', 'BOB': 'Bs', 'PYG': '₲',
  };

  static String symbolFor(String currencyCode) =>
      _symbols[currencyCode.toUpperCase()] ?? currencyCode;

  static String format(double amount, String currencyCode) {
    final symbol = _symbols[currencyCode.toUpperCase()] ?? currencyCode;
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '$symbol${formatter.format(amount)}';
  }

  static String compact(double amount, String currencyCode) {
    final symbol = _symbols[currencyCode.toUpperCase()] ?? currencyCode;
    if (amount >= 1000000) return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    return format(amount, currencyCode);
  }

  static String formatRate(double rate) => NumberFormat('#,##0.0000', 'en_US').format(rate);
}
