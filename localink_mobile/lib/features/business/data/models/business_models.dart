class CategoryDto {
  final int categoryId;
  final String categoryName;
  final String? iconUrl;

  CategoryDto({
    required this.categoryId,
    required this.categoryName,
    this.iconUrl,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      categoryId: json['id'] ?? json['categoryId'] ?? json['category_id'] ?? 0,
      categoryName: json['name'] ?? json['categoryName'] ?? json['category_name'] ?? '',
      iconUrl: json['iconUrl'] ?? json['icon_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'categoryName': categoryName,
        'iconUrl': iconUrl,
      };
}

class SubcategoryDto {
  final int subcategoryId;
  final String subcategoryName;
  final int categoryId;
  final String? iconUrl;

  SubcategoryDto({
    required this.subcategoryId,
    required this.subcategoryName,
    required this.categoryId,
    this.iconUrl,
  });

  factory SubcategoryDto.fromJson(Map<String, dynamic> json) {
    return SubcategoryDto(
      subcategoryId: json['id'] ?? json['subcategoryId'] ?? json['subcategory_id'] ?? 0,
      subcategoryName: json['name'] ?? json['subcategoryName'] ?? json['subcategory_name'] ?? '',
      categoryId: json['categoryId'] ?? json['category_id'] ?? 0,
      iconUrl: json['iconUrl'] ?? json['icon_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'subcategoryId': subcategoryId,
        'subcategoryName': subcategoryName,
        'categoryId': categoryId,
        'iconUrl': iconUrl,
      };
}

class SlotDto {
  final String open;
  final String close;

  SlotDto({required this.open, required this.close});

  factory SlotDto.fromJson(Map<String, dynamic> json) {
    return SlotDto(
      open: json['open'] ?? json['openTime'] ?? '',
      close: json['close'] ?? json['closeTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    String formatTime(String time) {
      if (time.isEmpty) return "00:00:00";
      final parts = time.split(':');
      if (parts.length == 2) {
        return "$time:00";
      }
      return time;
    }
    return {
      'openTime': formatTime(open),
      'closeTime': formatTime(close),
    };
  }
}

class DayHoursDto {
  final String day;
  final String mode;
  final List<SlotDto> slots;

  DayHoursDto({
    required this.day,
    required this.mode,
    required this.slots,
  });

  factory DayHoursDto.fromJson(Map<String, dynamic> json) {
    var slotsJson = json['slots'] as List? ?? [];
    return DayHoursDto(
      day: json['day'] ?? json['dayOfWeek'] ?? '',
      mode: json['mode'] ?? '',
      slots: slotsJson.map((e) => SlotDto.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'dayOfWeek': day,
        'mode': mode,
        'slots': slots.map((e) => e.toJson()).toList(),
      };
}

class BusinessDto {
  final int businessId;
  final String businessName;
  final String description;
  final int categoryId;
  final int subcategoryId;
  final String? categoryName;
  final String? subcategoryName;
  final String phoneCode;
  final String phoneNumber;
  final String email;
  final String website;
  final String address;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final double averageRating;
  final int reviewCount;
  final String? status;
  final List<DayHoursDto> hours;
  final List<String> photos;
  final String? photo;

  BusinessDto({
    required this.businessId,
    required this.businessName,
    required this.description,
    required this.categoryId,
    required this.subcategoryId,
    this.categoryName,
    this.subcategoryName,
    required this.phoneCode,
    required this.phoneNumber,
    required this.email,
    required this.website,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    this.latitude,
    this.longitude,
    required this.averageRating,
    required this.reviewCount,
    this.status,
    required this.hours,
    required this.photos,
    this.photo,
  });

  factory BusinessDto.fromJson(Map<String, dynamic> json) {
    var hoursJson = json['hours'] as List? ?? [];
    var photosJson = json['photos'] as List? ?? [];
    if (photosJson.isEmpty) {
      final primImg = json['primaryImage'] ?? json['primary_image'] ?? json['PrimaryImage'];
      if (primImg != null && primImg is String && primImg.isNotEmpty) {
        photosJson = [primImg];
      }
    }
    
    // Parse photos which could be either string lists or PhotoDto lists from backend
    List<String> parsedPhotos = [];
    for (var item in photosJson) {
      if (item is String) {
        parsedPhotos.add(item);
      } else if (item is Map) {
        final imgUrl = item['imageUrl'] ?? item['ImageUrl'] ?? item['image_url'] ?? item['Image_url'];
        if (imgUrl != null && imgUrl is String) {
          parsedPhotos.add(imgUrl);
        }
      }
    }

    final contactJson = json['contact'] as Map<String, dynamic>?;

    return BusinessDto(
      businessId: json['businessId'] ?? json['business_id'] ?? json['id'] ?? 0,
      businessName: json['businessName'] ?? json['business_name'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      categoryId: json['categoryId'] ?? json['category_id'] ?? 0,
      subcategoryId: json['subcategoryId'] ?? json['subcategory_id'] ?? 0,
      categoryName: json['categoryName'] ?? json['category_name'],
      subcategoryName: json['subcategoryName'] ?? json['subcategory_name'],
      phoneCode: json['phoneCode'] ?? json['phone_code'] ?? contactJson?['phoneCode'] ?? contactJson?['phone_code'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone_number'] ?? contactJson?['phoneNumber'] ?? contactJson?['phone_number'] ?? '',
      email: json['email'] ?? contactJson?['email'] ?? '',
      website: json['website'] ?? contactJson?['website'] ?? '',
      address: json['address'] ?? json['streetAddress'] ?? json['street_address'] ?? contactJson?['streetAddress'] ?? contactJson?['street_address'] ?? contactJson?['address'] ?? '',
      city: json['city'] ?? contactJson?['city'] ?? '',
      state: json['state'] ?? contactJson?['state'] ?? '',
      country: json['country'] ?? contactJson?['country'] ?? '',
      pincode: json['pincode'] ?? contactJson?['pincode'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? (contactJson?['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble() ?? (contactJson?['longitude'] as num?)?.toDouble(),
      averageRating: ((json['averageRating'] ?? json['average_rating'] ?? 0.0) as num).toDouble(),
      reviewCount: json['reviewCount'] ?? json['review_count'] ?? 0,
      status: json['status'],
      hours: hoursJson.map((e) => DayHoursDto.fromJson(e)).toList(),
      photos: parsedPhotos,
      photo: json['photo'],
    );
  }

  Map<String, dynamic> toJson() => {
        'businessId': businessId,
        'businessName': businessName,
        'description': description,
        'categoryId': categoryId,
        'subcategoryId': subcategoryId,
        'phoneCode': phoneCode,
        'phoneNumber': phoneNumber,
        'email': email,
        'website': website,
        'address': address,
        'city': city,
        'state': state,
        'country': country,
        'pincode': pincode,
        'latitude': latitude,
        'longitude': longitude,
        'hours': hours.map((e) => e.toJson()).toList(),
        'photo': photo,
      };
}

class BusinessReviewDto {
  final int reviewId;
  final int businessId;
  final double rating;
  final String comment;
  final String userName;
  final DateTime createdAt;

  BusinessReviewDto({
    required this.reviewId,
    required this.businessId,
    required this.rating,
    required this.comment,
    required this.userName,
    required this.createdAt,
  });

  factory BusinessReviewDto.fromJson(Map<String, dynamic> json) {
    return BusinessReviewDto(
      reviewId: json['reviewId'] ?? json['review_id'] ?? 0,
      businessId: json['businessId'] ?? json['business_id'] ?? 0,
      rating: ((json['rating'] ?? 0.0) as num).toDouble(),
      comment: json['comment'] ?? '',
      userName: json['userName'] ?? json['user_name'] ?? 'Anonymous',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
}
