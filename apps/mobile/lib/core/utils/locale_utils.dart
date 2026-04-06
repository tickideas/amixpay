import 'dart:io';

/// Detects the device's region and returns the most appropriate currency code.
/// Falls back to 'USD' if detection fails.
String detectLocaleCurrency() {
  try {
    final locale = Platform.localeName; // e.g. 'en_NG', 'en_GB', 'fr_FR'
    final parts = locale.split('_');
    // Country code is the last part for most locales (en_GB, en_US, fr_FR etc.)
    final countryCode = parts.length >= 2
        ? parts.last.toUpperCase()
        : parts.first.toUpperCase();
    return _countryToCurrency[countryCode] ?? 'USD';
  } catch (_) {
    return 'USD';
  }
}

/// Returns flag emoji for a currency code.
String currencyToFlag(String code) => _currencyFlags[code] ?? '🌐';

/// Returns full name for a currency code.
String currencyToName(String code) => _currencyNames[code] ?? code;

/// Returns symbol for a currency code.
String currencyToSymbol(String code) => _currencySymbols[code] ?? code;

// ---------------------------------------------------------------------------
// Country ISO-2 → currency code
// ---------------------------------------------------------------------------
const _countryToCurrency = {
  // Africa
  'NG': 'NGN', 'GH': 'GHS', 'KE': 'KES', 'ZA': 'ZAR', 'TZ': 'TZS',
  'UG': 'UGX', 'RW': 'RWF', 'ET': 'ETB', 'EG': 'EGP', 'MA': 'MAD',
  'TN': 'TND', 'ZM': 'ZMW', 'MW': 'MWK', 'MZ': 'MZN', 'CM': 'XAF',
  'SN': 'XOF', 'CI': 'XOF', 'BF': 'XOF', 'ML': 'XOF', 'NE': 'XOF',
  'ZW': 'USD',
  // Europe
  'GB': 'GBP', 'DE': 'EUR', 'FR': 'EUR', 'ES': 'EUR', 'IT': 'EUR',
  'NL': 'EUR', 'BE': 'EUR', 'PT': 'EUR', 'AT': 'EUR', 'IE': 'EUR',
  'FI': 'EUR', 'GR': 'EUR', 'LU': 'EUR', 'HR': 'EUR', 'SK': 'EUR',
  'SE': 'SEK', 'NO': 'NOK', 'DK': 'DKK', 'PL': 'PLN', 'CZ': 'CZK',
  'RO': 'RON', 'HU': 'HUF', 'BG': 'BGN', 'CH': 'CHF',
  // Americas
  'US': 'USD', 'CA': 'CAD', 'MX': 'MXN', 'BR': 'BRL', 'AR': 'ARS',
  'CO': 'COP', 'CL': 'CLP', 'PE': 'PEN', 'UY': 'UYU', 'BO': 'BOB',
  'VE': 'VES', 'PY': 'PYG', 'EC': 'USD', 'GY': 'GYD', 'SR': 'SRD',
  // Asia / Pacific
  'IN': 'INR', 'CN': 'CNY', 'JP': 'JPY', 'KR': 'KRW', 'SG': 'SGD',
  'HK': 'HKD', 'TW': 'TWD', 'TH': 'THB', 'MY': 'MYR', 'ID': 'IDR',
  'PH': 'PHP', 'VN': 'VND', 'PK': 'PKR', 'BD': 'BDT', 'LK': 'LKR',
  'NP': 'NPR', 'AU': 'AUD', 'NZ': 'NZD',
  // Middle East
  'AE': 'AED', 'SA': 'SAR', 'QA': 'QAR', 'KW': 'KWD', 'BH': 'BHD',
  'IL': 'ILS', 'TR': 'TRY',
};

const _currencyFlags = {
  'USDT': '💲', 'USD': '🇺🇸', 'GBP': '🇬🇧', 'EUR': '🇪🇺', 'CAD': '🇨🇦', 'AUD': '🇦🇺',
  'NGN': '🇳🇬', 'GHS': '🇬🇭', 'KES': '🇰🇪', 'ZAR': '🇿🇦', 'TZS': '🇹🇿',
  'UGX': '🇺🇬', 'RWF': '🇷🇼', 'ETB': '🇪🇹', 'EGP': '🇪🇬', 'MAD': '🇲🇦',
  'ZMW': '🇿🇲', 'XOF': '🌍', 'XAF': '🌍', 'MZN': '🇲🇿', 'MWK': '🇲🇼',
  'INR': '🇮🇳', 'CNY': '🇨🇳', 'JPY': '🇯🇵', 'KRW': '🇰🇷', 'SGD': '🇸🇬',
  'HKD': '🇭🇰', 'TWD': '🇹🇼', 'THB': '🇹🇭', 'MYR': '🇲🇾', 'IDR': '🇮🇩',
  'PHP': '🇵🇭', 'VND': '🇻🇳', 'PKR': '🇵🇰', 'BDT': '🇧🇩', 'LKR': '🇱🇰',
  'NPR': '🇳🇵', 'NZD': '🇳🇿', 'CHF': '🇨🇭', 'SEK': '🇸🇪', 'NOK': '🇳🇴',
  'DKK': '🇩🇰', 'PLN': '🇵🇱', 'CZK': '🇨🇿', 'RON': '🇷🇴', 'HUF': '🇭🇺',
  'BGN': '🇧🇬', 'AED': '🇦🇪', 'SAR': '🇸🇦', 'QAR': '🇶🇦', 'KWD': '🇰🇼',
  'BHD': '🇧🇭', 'ILS': '🇮🇱', 'TRY': '🇹🇷', 'BRL': '🇧🇷', 'MXN': '🇲🇽',
  'ARS': '🇦🇷', 'COP': '🇨🇴', 'CLP': '🇨🇱', 'PEN': '🇵🇪', 'UYU': '🇺🇾',
  'BOB': '🇧🇴', 'VES': '🇻🇪', 'PYG': '🇵🇾', 'GYD': '🇬🇾', 'SRD': '🇸🇷',
};

const _currencyNames = {
  'USDT': 'Tether USD', 'USD': 'US Dollar', 'GBP': 'British Pound', 'EUR': 'Euro',
  'CAD': 'Canadian Dollar', 'AUD': 'Australian Dollar',
  'NGN': 'Nigerian Naira', 'GHS': 'Ghanaian Cedi', 'KES': 'Kenyan Shilling',
  'ZAR': 'South African Rand', 'TZS': 'Tanzanian Shilling',
  'UGX': 'Ugandan Shilling', 'RWF': 'Rwandan Franc', 'ETB': 'Ethiopian Birr',
  'EGP': 'Egyptian Pound', 'MAD': 'Moroccan Dirham', 'ZMW': 'Zambian Kwacha',
  'XOF': 'CFA Franc BCEAO', 'XAF': 'CFA Franc BEAC',
  'INR': 'Indian Rupee', 'CNY': 'Chinese Yuan', 'JPY': 'Japanese Yen',
  'KRW': 'South Korean Won', 'SGD': 'Singapore Dollar',
  'HKD': 'Hong Kong Dollar', 'TWD': 'Taiwan Dollar', 'THB': 'Thai Baht',
  'MYR': 'Malaysian Ringgit', 'IDR': 'Indonesian Rupiah',
  'PHP': 'Philippine Peso', 'VND': 'Vietnamese Dong', 'PKR': 'Pakistani Rupee',
  'BDT': 'Bangladeshi Taka', 'LKR': 'Sri Lankan Rupee',
  'NPR': 'Nepalese Rupee', 'NZD': 'New Zealand Dollar',
  'CHF': 'Swiss Franc', 'SEK': 'Swedish Krona', 'NOK': 'Norwegian Krone',
  'DKK': 'Danish Krone', 'PLN': 'Polish Zloty', 'CZK': 'Czech Koruna',
  'RON': 'Romanian Leu', 'HUF': 'Hungarian Forint', 'BGN': 'Bulgarian Lev',
  'AED': 'UAE Dirham', 'SAR': 'Saudi Riyal', 'QAR': 'Qatari Riyal',
  'KWD': 'Kuwaiti Dinar', 'BHD': 'Bahraini Dinar', 'ILS': 'Israeli Shekel',
  'TRY': 'Turkish Lira', 'BRL': 'Brazilian Real', 'MXN': 'Mexican Peso',
  'ARS': 'Argentine Peso', 'COP': 'Colombian Peso', 'CLP': 'Chilean Peso',
  'PEN': 'Peruvian Sol', 'UYU': 'Uruguayan Peso', 'BOB': 'Bolivian Boliviano',
  'VES': 'Venezuelan Bolívar', 'PYG': 'Paraguayan Guaraní',
  'GYD': 'Guyanese Dollar', 'SRD': 'Surinamese Dollar',
};

const _currencySymbols = {
  'USDT': r'$', 'USD': r'$', 'GBP': '£', 'EUR': '€', 'CAD': r'C$', 'AUD': r'A$',
  'NGN': '₦', 'GHS': '₵', 'KES': 'KSh', 'ZAR': 'R', 'TZS': 'TSh',
  'UGX': 'USh', 'RWF': 'RF', 'ETB': 'Br', 'EGP': 'E£', 'MAD': 'MAD',
  'ZMW': 'ZK', 'XOF': 'CFA', 'XAF': 'FCFA', 'MZN': 'MTn', 'MWK': 'MK',
  'INR': '₹', 'CNY': '¥', 'JPY': '¥', 'KRW': '₩', 'SGD': r'S$',
  'HKD': r'HK$', 'TWD': r'NT$', 'THB': '฿', 'MYR': 'RM', 'IDR': 'Rp',
  'PHP': '₱', 'VND': '₫', 'PKR': '₨', 'BDT': '৳', 'LKR': '₨',
  'NPR': '₨', 'NZD': r'NZ$', 'CHF': 'Fr', 'SEK': 'kr', 'NOK': 'kr',
  'DKK': 'kr', 'PLN': 'zł', 'CZK': 'Kč', 'RON': 'lei', 'HUF': 'Ft',
  'BGN': 'лв', 'AED': 'AED', 'SAR': 'SAR', 'QAR': 'QAR', 'KWD': 'KD',
  'BHD': 'BD', 'ILS': '₪', 'TRY': '₺', 'BRL': r'R$', 'MXN': r'MX$',
  'ARS': r'ARS$', 'COP': r'COP$', 'CLP': r'CL$', 'PEN': 'S/',
  'UYU': r'$U', 'BOB': 'Bs', 'VES': 'Bs.S', 'PYG': '₲',
  'GYD': r'G$', 'SRD': r'SRD$',
};
