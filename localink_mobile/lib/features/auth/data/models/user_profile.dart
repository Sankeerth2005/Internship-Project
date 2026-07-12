class AddressDto {
  final String? street;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;

  AddressDto({this.street, this.city, this.state, this.country, this.pincode});

  factory AddressDto.fromJson(Map<String, dynamic> json) {
    return AddressDto(
      street: json['street'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      pincode: json['pincode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'street': street,
    'city': city,
    'state': state,
    'country': country,
    'pincode': pincode,
  };
}

class UserProfileDto {
  final int userId;
  final String fullName;
  final String email;
  final String? phone;
  final AddressDto address;

  UserProfileDto({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    required this.address,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] as String?,
      address: json['address'] != null
          ? AddressDto.fromJson(json['address'])
          : AddressDto(),
    );
  }
}

class UpdateUserProfileDto {
  final String fullName;
  final String? email;
  final String? phone;
  final AddressDto address;

  UpdateUserProfileDto({
    required this.fullName,
    this.email,
    this.phone,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'address': address.toJson(),
  };
}
