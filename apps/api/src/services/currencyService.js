const axios = require('axios');
const { redisGet, redisSet } = require('../redis/client');

const CACHE_TTL = 600; // 10 minutes
const CACHE_KEY = 'exchange_rates:USD';

const SUPPORTED_CURRENCIES = [
  { code: 'USD', name: 'US Dollar', symbol: '$', flag: '🇺🇸' },
  { code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺' },
  { code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧' },
  { code: 'JPY', name: 'Japanese Yen', symbol: '¥', flag: '🇯🇵' },
  { code: 'CAD', name: 'Canadian Dollar', symbol: 'C$', flag: '🇨🇦' },
  { code: 'AUD', name: 'Australian Dollar', symbol: 'A$', flag: '🇦🇺' },
  { code: 'CHF', name: 'Swiss Franc', symbol: 'Fr', flag: '🇨🇭' },
  { code: 'CNY', name: 'Chinese Yuan', symbol: '¥', flag: '🇨🇳' },
  { code: 'NGN', name: 'Nigerian Naira', symbol: '₦', flag: '🇳🇬' },
  { code: 'KES', name: 'Kenyan Shilling', symbol: 'KSh', flag: '🇰🇪' },
  { code: 'GHS', name: 'Ghanaian Cedi', symbol: '₵', flag: '🇬🇭' },
  { code: 'ZAR', name: 'South African Rand', symbol: 'R', flag: '🇿🇦' },
  { code: 'INR', name: 'Indian Rupee', symbol: '₹', flag: '🇮🇳' },
  { code: 'BRL', name: 'Brazilian Real', symbol: 'R$', flag: '🇧🇷' },
  { code: 'MXN', name: 'Mexican Peso', symbol: '$', flag: '🇲🇽' },
  { code: 'SGD', name: 'Singapore Dollar', symbol: 'S$', flag: '🇸🇬' },
];

// Fallback rates (used when API is unavailable)
const FALLBACK_RATES = {
  USD: 1, EUR: 0.92, GBP: 0.79, JPY: 149.5, CAD: 1.36, AUD: 1.53,
  CHF: 0.89, CNY: 7.24, NGN: 1580, KES: 129, GHS: 15.2, ZAR: 18.6,
  INR: 83.1, BRL: 4.97, MXN: 17.2, SGD: 1.34,
};

const currencyService = {
  async getRates(baseCurrency = 'USD') {
    try {
      const cached = await redisGet(CACHE_KEY);
      if (cached) return JSON.parse(cached);

      const apiKey = process.env.OPEN_EXCHANGE_RATES_KEY;
      if (!apiKey) {
        console.warn('[Currency] No API key — using fallback rates');
        return FALLBACK_RATES;
      }

      const { data } = await axios.get(
        `https://openexchangerates.org/api/latest.json?app_id=${apiKey}&base=USD`,
        { timeout: 5000 }
      );

      const rates = data.rates;
      await redisSet(CACHE_KEY, JSON.stringify(rates), CACHE_TTL);
      return rates;
    } catch (err) {
      console.error('[Currency] Failed to fetch rates:', err.message);
      return FALLBACK_RATES;
    }
  },

  async convert(amount, fromCurrency, toCurrency) {
    if (fromCurrency === toCurrency) return { amount, rate: 1, fee: 0 };
    const rates = await currencyService.getRates();
    const fromRate = rates[fromCurrency.toUpperCase()] || 1;
    const toRate = rates[toCurrency.toUpperCase()] || 1;
    const rate = toRate / fromRate;
    const converted = parseFloat((amount * rate).toFixed(8));
    const fee = parseFloat((converted * 0.002).toFixed(8)); // 0.2% conversion fee
    return { amount: converted, rate, fee };
  },

  getSupportedCurrencies: () => SUPPORTED_CURRENCIES,

  isSupported: (code) => SUPPORTED_CURRENCIES.some((c) => c.code === code.toUpperCase()),
};

module.exports = currencyService;
