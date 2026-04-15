import 'dart:convert';

import 'package:http/http.dart' as http;

import 'unit_converter.dart';

class CurrencyService {
  CurrencyService._();
  static final instance = CurrencyService._();

  List<UnitDef>? _cachedUnits;
  DateTime? _lastFetch;
  DateTime? _ratesUpdateTime;

  /// Currency names for display.
  static const _currencyNames = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
    'CHF': 'Swiss Franc',
    'CNY': 'Chinese Yuan',
    'INR': 'Indian Rupee',
    'PKR': 'Pakistani Rupee',
    'SAR': 'Saudi Riyal',
    'AED': 'UAE Dirham',
    'TRY': 'Turkish Lira',
    'KRW': 'South Korean Won',
    'BRL': 'Brazilian Real',
    'MXN': 'Mexican Peso',
    'ZAR': 'South African Rand',
    'RUB': 'Russian Ruble',
    'SGD': 'Singapore Dollar',
    'MYR': 'Malaysian Ringgit',
    'SEK': 'Swedish Krona',
    'NOK': 'Norwegian Krone',
    'DKK': 'Danish Krone',
    'NZD': 'New Zealand Dollar',
    'THB': 'Thai Baht',
    'HKD': 'Hong Kong Dollar',
    'IDR': 'Indonesian Rupiah',
    'PHP': 'Philippine Peso',
    'PLN': 'Polish Zloty',
    'CZK': 'Czech Koruna',
    'HUF': 'Hungarian Forint',
    'ILS': 'Israeli Shekel',
    'EGP': 'Egyptian Pound',
    'NGN': 'Nigerian Naira',
    'BGN': 'Bulgarian Lev',
    'RON': 'Romanian Leu',
    'ISK': 'Icelandic Krona',
    'KES': 'Kenyan Shilling',
  };

  /// Preferred order — common currencies first.
  static const _preferredOrder = [
    'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY',
    'INR', 'PKR', 'SAR', 'AED', 'TRY', 'KRW', 'BRL', 'MXN',
    'SGD', 'MYR', 'HKD', 'THB',
  ];

  bool get hasCachedRates => _cachedUnits != null;

  List<UnitDef>? get cachedUnits => _cachedUnits;

  /// The date when the rates were last updated by the API.
  DateTime? get ratesUpdateTime => _ratesUpdateTime;

  /// Fetch live rates from Google-sourced currency API (base: USD).
  /// Caches for 30 seconds so the screen can auto-refresh with
  /// up-to-date rates.
  Future<List<UnitDef>> fetchRates({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedUnits != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inSeconds < 30) {
      return _cachedUnits!;
    }

    // Primary: Google-sourced currency-api (updates daily, accurate Google rates)
    // Fallback: ExchangeRate-API (open access, no key)
    final apis = [
      'https://latest.currency-api.pages.dev/v1/currencies/usd.json',
      'https://open.er-api.com/v6/latest/USD',
    ];

    Map<String, double>? rates;
    String? dateStr;

    for (final url in apis) {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode != 200) continue;

        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (url.contains('currency-api')) {
          // fawazahmed0 format: { "date": "...", "usd": { "eur": 0.86, ... } }
          dateStr = data['date'] as String?;
          final usdRates = data['usd'] as Map<String, dynamic>;
          rates = {};
          for (final entry in usdRates.entries) {
            final v = entry.value;
            if (v is num) rates[entry.key.toUpperCase()] = v.toDouble();
          }
        } else {
          // ExchangeRate-API format: { "rates": { "EUR": 0.86, ... } }
          final unixTime = data['time_last_update_unix'] as int?;
          if (unixTime != null) {
            dateStr = DateTime.fromMillisecondsSinceEpoch(
              unixTime * 1000,
              isUtc: true,
            ).toIso8601String().substring(0, 10);
          }
          final rawRates = data['rates'] as Map<String, dynamic>;
          rates = rawRates.map((k, v) => MapEntry(k, (v as num).toDouble()));
        }
        break; // success
      } catch (_) {
        continue; // try next API
      }
    }

    if (rates == null || rates.isEmpty) {
      if (_cachedUnits != null) return _cachedUnits!;
      throw Exception('Failed to fetch exchange rates');
    }

    // Parse date
    if (dateStr != null) {
      _ratesUpdateTime = DateTime.tryParse(dateStr);
    }

    // Build UnitDef list. USD is the base (factor = 1).
    final units = <UnitDef>[
      const UnitDef(name: 'US Dollar', symbol: 'USD', toBase: 1),
    ];

    // Add preferred currencies first (in order), then the rest alphabetically.
    final added = <String>{'USD'};

    for (final code in _preferredOrder) {
      if (rates.containsKey(code)) {
        units.add(UnitDef(
          name: _currencyNames[code] ?? code,
          symbol: code,
          toBase: 1 / rates[code]!,
        ));
        added.add(code);
      }
    }

    final remaining = rates.keys
        .where((c) => !added.contains(c) && _currencyNames.containsKey(c))
        .toList()
      ..sort();
    for (final code in remaining) {
      units.add(UnitDef(
        name: _currencyNames[code] ?? code,
        symbol: code,
        toBase: 1 / rates[code]!,
      ));
    }

    _cachedUnits = units;
    _lastFetch = DateTime.now();
    return units;
  }
}