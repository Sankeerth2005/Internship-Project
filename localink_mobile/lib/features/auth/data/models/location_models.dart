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
