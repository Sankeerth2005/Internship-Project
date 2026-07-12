import 'package:json_annotation/json_annotation.dart';

part 'register_request.g.dart';

@JsonSerializable()
class RegisterRequest {
  @JsonKey(name: 'userType')
  final String userType;
  @JsonKey(name: 'name')
  final String name;
  @JsonKey(name: 'email')
  final String email;
  @JsonKey(name: 'phone')
  final String phone;
  @JsonKey(name: 'countryCode')
  final String countryCode;
  @JsonKey(name: 'password')
  final String password;
  @JsonKey(name: 'country')
  final String country;
  @JsonKey(name: 'state')
  final String state;
  @JsonKey(name: 'city')
  final String city;
  @JsonKey(name: 'street')
  final String street;
  @JsonKey(name: 'pincode')
  final String pincode;

  RegisterRequest({
    required this.userType,
    required this.name,
    required this.email,
    required this.phone,
    required this.countryCode,
    required this.password,
    required this.country,
    required this.state,
    required this.city,
    this.street = '',
    this.pincode = '',
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}
