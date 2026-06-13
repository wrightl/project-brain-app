import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/models/location.dart';
import 'package:projectbrain/services/http_service.dart';

/// Service for location search (cities via backend, countries via restcountries).
class LocationService extends HttpService {
  LocationService({required super.authService});

  static const _countriesUrl =
      'https://restcountries.com/v3.1/all?fields=name,cca2';

  List<CountryOption>? _cachedCountries;

  /// Fetch all countries (cached in memory for the session).
  Future<List<CountryOption>> getCountries() async {
    if (_cachedCountries != null) {
      return _cachedCountries!;
    }

    logDebug('[LocationService] Fetching countries');
    final response = await http.get(Uri.parse(_countriesUrl));

    if (response.statusCode != 200) {
      logError(
          '[LocationService] Failed to fetch countries: ${response.statusCode}');
      throw Exception('Failed to fetch countries: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    final countries = data
        .map((item) {
          final map = item as Map<String, dynamic>;
          final name = map['name']?['common'] as String? ?? '';
          final code = map['cca2'] as String? ?? '';
          return CountryOption(name: name, code: code);
        })
        .where((country) => country.name.isNotEmpty && country.code.isNotEmpty)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    _cachedCountries = countries;
    logDebug('[LocationService] Loaded ${countries.length} countries');
    return countries;
  }

  /// Search cities via backend Google Places proxy.
  Future<List<CityOption>> searchCities({
    required String query,
    required String countryCode,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2 || countryCode.trim().isEmpty) {
      return const [];
    }

    logDebug('[LocationService] Searching cities: $trimmed ($countryCode)');
    final response = await get(
      '/locations/cities?q=${Uri.encodeQueryComponent(trimmed)}&countryCode=${Uri.encodeQueryComponent(countryCode)}',
      useCache: false,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((item) => CityOption.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    logError(
        '[LocationService] Failed to search cities: ${response.statusCode}');
    throw Exception('Failed to search cities: ${response.statusCode}');
  }
}
