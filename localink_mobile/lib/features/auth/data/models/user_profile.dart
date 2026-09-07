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
  final String countryCode;
  final String? profilePicture;
  final String? referralCode;
  final int successfulReferralCount;
  final String referralAchievementTier;
  final String referralAchievementLabel;
  final AddressDto address;

  UserProfileDto({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    required this.countryCode,
    this.profilePicture,
    this.referralCode,
    this.successfulReferralCount = 0,
    this.referralAchievementTier = 'none',
    this.referralAchievementLabel = 'Community Member',
    required this.address,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] as String?,
      countryCode: json['countryCode'] ?? '',
      profilePicture: json['profilePicture'] as String?,
      referralCode: json['referralCode'] as String?,
      successfulReferralCount: json['successfulReferralCount'] is int
          ? json['successfulReferralCount'] as int
          : int.tryParse('${json['successfulReferralCount']}') ?? 0,
      referralAchievementTier:
          (json['referralAchievementTier'] ?? 'none').toString(),
      referralAchievementLabel:
          (json['referralAchievementLabel'] ?? 'Community Member').toString(),
      address: json['address'] != null
          ? AddressDto.fromJson(json['address'])
          : AddressDto(),
    );
  }

  String get referralTierEmoji {
    switch (referralAchievementTier.toLowerCase()) {
      case 'bronze':
        return '🥉';
      case 'silver':
        return '🥈';
      case 'gold':
        return '🥇';
      default:
        return '';
    }
  }
}

class UpdateUserProfileDto {
  final String fullName;
  final String? email;
  final String? phone;
  final String? countryCode;
  final String? profilePicture;
  final AddressDto address;

  UpdateUserProfileDto({
    required this.fullName,
    this.email,
    this.phone,
    this.countryCode,
    this.profilePicture,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'countryCode': countryCode,
        'profilePicture': profilePicture,
        'address': address.toJson(),
      };
}
