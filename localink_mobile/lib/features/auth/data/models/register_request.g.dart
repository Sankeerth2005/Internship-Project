// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      userType: json['userType'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      countryCode: json['countryCode'] as String,
      password: json['password'] as String,
      country: json['country'] as String,
      state: json['state'] as String,
      city: json['city'] as String,
      street: json['street'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'userType': instance.userType,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'countryCode': instance.countryCode,
      'password': instance.password,
      'country': instance.country,
      'state': instance.state,
      'city': instance.city,
      'street': instance.street,
      'pincode': instance.pincode,
    };
