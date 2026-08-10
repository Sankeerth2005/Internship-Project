import 'package:json_annotation/json_annotation.dart';

part 'authorized_experiences.g.dart';

@JsonSerializable()
class AuthorizedExperiencesDto {
  @JsonKey(name: 'accountType')
  final String accountType;

  @JsonKey(name: 'authorizedExperiences')
  final List<String> authorizedExperiences;

  @JsonKey(name: 'canContinueAsUser')
  final bool canContinueAsUser;

  @JsonKey(name: 'canContinueAsBusinessOwner')
  final bool canContinueAsBusinessOwner;

  @JsonKey(name: 'canRegisterBusiness')
  final bool canRegisterBusiness;

  AuthorizedExperiencesDto({
    required this.accountType,
    required this.authorizedExperiences,
    required this.canContinueAsUser,
    required this.canContinueAsBusinessOwner,
    required this.canRegisterBusiness,
  });

  factory AuthorizedExperiencesDto.fromJson(Map<String, dynamic> json) =>
      _$AuthorizedExperiencesDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorizedExperiencesDtoToJson(this);
}

@JsonSerializable()
class SelectExperienceResultDto {
  @JsonKey(name: 'allowed')
  final bool allowed;

  @JsonKey(name: 'experience')
  final String experience;

  @JsonKey(name: 'destination')
  final String destination;

  @JsonKey(name: 'message')
  final String? message;

  SelectExperienceResultDto({
    required this.allowed,
    required this.experience,
    required this.destination,
    this.message,
  });

  factory SelectExperienceResultDto.fromJson(Map<String, dynamic> json) =>
      _$SelectExperienceResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SelectExperienceResultDtoToJson(this);
}
