class CountryOption {
  final String name;
  final String code;

  const CountryOption({
    required this.name,
    required this.code,
  });

  factory CountryOption.fromJson(Map<String, dynamic> json) {
    return CountryOption(
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryOption && code == other.code && name == other.name;

  @override
  int get hashCode => Object.hash(code, name);
}

class CityOption {
  final String city;
  final String? stateProvince;
  final String? country;
  final double latitude;
  final double longitude;
  final String placeId;
  final String formattedAddress;

  const CityOption({
    required this.city,
    this.stateProvince,
    this.country,
    required this.latitude,
    required this.longitude,
    required this.placeId,
    required this.formattedAddress,
  });

  factory CityOption.fromJson(Map<String, dynamic> json) {
    return CityOption(
      city: json['city'] as String? ?? '',
      stateProvince: json['stateProvince'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      placeId: json['placeId'] as String? ?? '',
      formattedAddress: json['formattedAddress'] as String? ?? '',
    );
  }

  String get displayLabel {
    return [city, stateProvince, country].where((part) => part != null && part.isNotEmpty).join(', ');
  }
}

class SearchCenter {
  final double latitude;
  final double longitude;

  const SearchCenter({
    required this.latitude,
    required this.longitude,
  });
}
