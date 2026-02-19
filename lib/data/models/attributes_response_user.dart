// models/attributes_response_user.dart




import 'package:swipe_mobile_re/data/models/enums.dart';

class AttributesResponseUser {
  final int? height;
  final SmokingAttitudeEnum? smokingAttitude;
  final AlcoholAttitudeEnum? alcoholAttitude;
  final ChildrenEnum? childrenPreference;
  final WhatLookingForEnum? whatLookingFor;
  final AppearanceEnum? appearance;
  final ReligionEnum? religion;

  AttributesResponseUser({
    this.height,
    this.smokingAttitude,
    this.alcoholAttitude,
    this.childrenPreference,
    this.whatLookingFor,
    this.appearance,
    this.religion,
  });

  factory AttributesResponseUser.fromJson(Map<String, dynamic> json) {
    return AttributesResponseUser(
      height: json['height'],
      smokingAttitude: json['smoking_attitude'] != null
          ? SmokingAttitudeExtension.fromString(json['smoking_attitude'])
          : null,
      alcoholAttitude: json['alcohol_attitude'] != null
          ? AlcoholAttitudeExtension.fromString(json['alcohol_attitude'])
          : null,
      childrenPreference: json['children_preference'] != null
          ? ChildrenEnumExtension.fromString(json['children_preference'])
          : null,
      whatLookingFor: json['what_looking_for'] != null
          ? WhatLookingForExtension.fromString(json['what_looking_for'])
          : null,
      appearance: json['appearance'] != null
          ? AppearanceEnumExtension.fromString(json['appearance'])
          : null,
      religion: json['religion'] != null
          ? ReligionExtension.fromString(json['religion'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "height": height,
      "smoking_attitude": smokingAttitude?.value,
      "alcohol_attitude": alcoholAttitude?.value,
      "children_preference": childrenPreference?.value,
      "what_looking_for": whatLookingFor?.value,
      "appearance": appearance?.value,
      "religion": religion?.value,
    };
  }
}
