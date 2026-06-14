import 'dart:convert';

import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/models/location.dart';
import 'package:projectbrain/services/http_service.dart';

/// Service for location search (countries and cities via backend).
class LocationService extends HttpService {
  LocationService({required super.authService});

  /// Fetch all countries from the backend catalog.
  Future<List<CountryOption>> getCountries() async {
    logDebug('[LocationService] Fetching countries');
    final response = await get(
      '/locations/countries',
      useCache: true,
      cacheDuration: const Duration(hours: 24),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      final countries = data
          .map((item) => CountryOption.fromJson(item as Map<String, dynamic>))
          .where((country) => country.name.isNotEmpty && country.code.isNotEmpty)
          .toList();
      logDebug('[LocationService] Loaded ${countries.length} countries');
      return countries;
    }

    logError(
        '[LocationService] Failed to fetch countries: ${response.statusCode}');
    throw Exception('Failed to fetch countries: ${response.statusCode}');
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
