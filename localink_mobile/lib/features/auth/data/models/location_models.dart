class Country {
  final String name;
  final String iso2;
  final String? phoneCode;
  final String? emoji;

  Country({required this.name, required this.iso2, this.phoneCode, this.emoji});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name'] as String? ?? '',
      iso2: json['iso2'] as String? ?? '',
      phoneCode: (json['phonecode'] ?? json['phone_code'])?.toString(),
      emoji: json['emoji'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'iso2': iso2, 'phonecode': phoneCode, 'emoji': emoji};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          iso2 == other.iso2 &&
          name == other.name;

  @override
  int get hashCode => iso2.hashCode ^ name.hashCode;
}

class StateModel {
  final String name;
  final String iso2;

  StateModel({required this.name, required this.iso2});

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      name: json['name'] as String? ?? '',
      iso2: json['iso2'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'iso2': iso2};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StateModel &&
          runtimeType == other.runtimeType &&
          iso2 == other.iso2 &&
          name == other.name;

  @override
  int get hashCode => iso2.hashCode ^ name.hashCode;
}

class CityModel {
  final String name;

  CityModel({required this.name});

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(name: json['name'] as String? ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CityModel &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class PincodeValidationResponse {
  final String? country;
  final String? state;
  final String? city;

  PincodeValidationResponse({this.country, this.state, this.city});

  bool get isValid =>
      (country != null && country!.trim().isNotEmpty) ||
      (state != null && state!.trim().isNotEmpty) ||
      (city != null && city!.trim().isNotEmpty);

  factory PincodeValidationResponse.fromJson(Map<String, dynamic> json) {
    return PincodeValidationResponse(
      country: json['country'] as String?,
      state: json['state'] as String?,
      city: json['city'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'country': country, 'state': state, 'city': city};
  }
}

/// Resolves a business's registered country/flag from persisted phone code + country
/// using the app's existing CSC country dataset. Never assumes India or a default flag.
class CountryLookup {
  CountryLookup._();

  static String normalizeCallingCode(String? value) {
    if (value == null) return '';
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static String? flagFromIso2(String? iso2) {
    final code = iso2?.trim().toUpperCase() ?? '';
    if (code.length != 2) return null;
    if (code.codeUnits.any((u) => u < 65 || u > 90)) return null;
    return String.fromCharCodes(
      code.codeUnits.map((u) => 0x1F1E6 - 65 + u),
    );
  }

  static Country? resolve({
    required List<Country> countries,
    String? phoneCode,
    String? countryName,
  }) {
    final calling = normalizeCallingCode(phoneCode);
    final name = countryName?.trim().toLowerCase() ?? '';

    final byPhone = calling.isEmpty
        ? const <Country>[]
        : countries.where((c) {
            return normalizeCallingCode(c.phoneCode) == calling;
          }).toList();

    if (byPhone.length == 1) return byPhone.first;

    if (byPhone.length > 1 && name.isNotEmpty) {
      final exact = byPhone
          .where((c) => c.name.toLowerCase() == name)
          .toList();
      if (exact.length == 1) return exact.first;
    }

    if (name.isNotEmpty) {
      final byName = countries
          .where((c) => c.name.toLowerCase() == name)
          .toList();
      if (byName.length == 1) return byName.first;
    }

    return null;
  }

  static String? flagEmoji(Country? country) {
    if (country == null) return null;
    final emoji = country.emoji?.trim();
    if (emoji != null && emoji.isNotEmpty) return emoji;
    return flagFromIso2(country.iso2);
  }
}
