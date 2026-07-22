import 'package:collection/collection.dart';

const _listEquality = ListEquality<Object?>();

class ProfileInterest {
  const ProfileInterest({required this.id, required this.label});

  final int id;
  final String label;

  factory ProfileInterest.fromJson(Map<String, dynamic> json) {
    return ProfileInterest(
      id: json['interest_id'] as int? ?? json['id'] as int? ?? 0,
      label: json['interest_text'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProfileInterest && other.id == id && other.label == label;

  @override
  int get hashCode => Object.hash(id, label);
}

class ProfilePhoto {
  const ProfilePhoto({
    required this.id,
    required this.url,
    required this.isAvatar,
  });

  final int id;
  final String url;
  final bool isAvatar;

  factory ProfilePhoto.fromJson(Map<String, dynamic> json) {
    return ProfilePhoto(
      id: json['id'] as int,
      url: json['photo_url'] as String,
      isAvatar: json['is_avatar'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProfilePhoto &&
      other.id == id &&
      other.url == url &&
      other.isAvatar == isAvatar;

  @override
  int get hashCode => Object.hash(id, url, isAvatar);
}

class ProfileAttributes {
  const ProfileAttributes({
    this.height,
    this.smokingAttitude,
    this.alcoholAttitude,
    this.childrenPreference,
    this.whatLookingFor,
    this.appearance,
    this.religion,
  });

  static const keys = [
    'height',
    'smoking_attitude',
    'alcohol_attitude',
    'children_preference',
    'what_looking_for',
    'appearance',
    'religion',
  ];

  final int? height;
  final String? smokingAttitude;
  final String? alcoholAttitude;
  final String? childrenPreference;
  final String? whatLookingFor;
  final String? appearance;
  final String? religion;

  factory ProfileAttributes.fromJson(Map<String, dynamic> json) {
    String? text(String key) {
      final value = json[key];
      if (value == null || '$value'.trim().isEmpty) return null;
      return '$value';
    }

    final rawHeight = json['height'];
    return ProfileAttributes(
      height: rawHeight is int ? rawHeight : int.tryParse('$rawHeight'),
      smokingAttitude: text('smoking_attitude'),
      alcoholAttitude: text('alcohol_attitude'),
      childrenPreference: text('children_preference'),
      whatLookingFor: text('what_looking_for'),
      appearance: text('appearance'),
      religion: text('religion'),
    );
  }

  Object? valueFor(String key) => switch (key) {
    'height' => height,
    'smoking_attitude' => smokingAttitude,
    'alcohol_attitude' => alcoholAttitude,
    'children_preference' => childrenPreference,
    'what_looking_for' => whatLookingFor,
    'appearance' => appearance,
    'religion' => religion,
    _ => null,
  };

  ProfileAttributes copyWithValue(String key, Object? value) =>
      ProfileAttributes(
        height: key == 'height' ? value as int? : height,
        smokingAttitude: key == 'smoking_attitude'
            ? value as String?
            : smokingAttitude,
        alcoholAttitude: key == 'alcohol_attitude'
            ? value as String?
            : alcoholAttitude,
        childrenPreference: key == 'children_preference'
            ? value as String?
            : childrenPreference,
        whatLookingFor: key == 'what_looking_for'
            ? value as String?
            : whatLookingFor,
        appearance: key == 'appearance' ? value as String? : appearance,
        religion: key == 'religion' ? value as String? : religion,
      );

  Map<String, String> get facts {
    final result = <String, String>{};
    for (final key in keys) {
      final value = valueFor(key);
      if (value == null || '$value'.trim().isEmpty) continue;
      result[_profileFactLabel(key)] = key == 'height'
          ? '${readableProfileValue('$value')} cm'
          : readableProfileValue('$value');
    }
    return result;
  }

  Map<String, Object?> changedValuesFrom(ProfileAttributes baseline) {
    final result = <String, Object?>{};
    for (final key in keys) {
      final value = valueFor(key);
      if (value != baseline.valueFor(key)) result[key] = value;
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      other is ProfileAttributes &&
      other.height == height &&
      other.smokingAttitude == smokingAttitude &&
      other.alcoholAttitude == alcoholAttitude &&
      other.childrenPreference == childrenPreference &&
      other.whatLookingFor == whatLookingFor &&
      other.appearance == appearance &&
      other.religion == religion;

  @override
  int get hashCode => Object.hash(
    height,
    smokingAttitude,
    alcoholAttitude,
    childrenPreference,
    whatLookingFor,
    appearance,
    religion,
  );
}

class ProfileAttributeOption {
  const ProfileAttributeOption({required this.name, required this.description});

  final String name;
  final String description;

  factory ProfileAttributeOption.fromJson(Map<String, dynamic> json) {
    return ProfileAttributeOption(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class ProfileEditCatalog {
  const ProfileEditCatalog({
    this.interests = const [],
    this.attributes = const {},
  });

  final List<ProfileInterest> interests;
  final Map<String, List<ProfileAttributeOption>> attributes;

  List<ProfileAttributeOption> optionsFor(String key) =>
      attributes[key] ?? const [];
}

/// Read-only data for another user's public profile.
///
/// This intentionally contains only fields exposed by the existing user and
/// user-photo endpoints. Reaction state remains owned by Discovery.
class PublicUserProfile {
  const PublicUserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    this.gender = '',
    required this.city,
    required this.aboutMe,
    required this.avatarUrl,
    required this.interests,
    required this.photos,
    required this.facts,
  });

  final int id;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String gender;
  final String city;
  final String aboutMe;
  final String? avatarUrl;
  final List<ProfileInterest> interests;
  final List<ProfilePhoto> photos;
  final Map<String, String> facts;

  int? get age => profileAge(dateOfBirth);

  String get displayName => [
    firstName.trim(),
    lastName.trim(),
  ].where((part) => part.isNotEmpty).join(' ');

  String get identity {
    final name = displayName;
    final value = name.isEmpty ? 'Profile' : name;
    return age == null ? value : '$value, $age';
  }

  ProfilePhoto? get heroPhoto {
    for (final photo in photos) {
      if (photo.isAvatar) return photo;
    }
    return photos.isEmpty ? null : photos.first;
  }

  String? get heroPhotoUrl {
    final photoUrl = heroPhoto?.url.trim();
    if (photoUrl != null && photoUrl.isNotEmpty) return photoUrl;
    final avatar = avatarUrl?.trim();
    return avatar == null || avatar.isEmpty ? null : avatar;
  }

  List<ProfilePhoto> get additionalPhotos {
    final hero = heroPhoto;
    if (hero == null) return photos;
    return photos.where((photo) => photo.id != hero.id).toList(growable: false);
  }

  factory PublicUserProfile.fromJson(
    Map<String, dynamic> json, {
    List<ProfilePhoto> photos = const [],
  }) {
    final rawInterests = json['interests'] as List<dynamic>? ?? const [];
    final rawAttributes = json['attributes'];
    final attributes = rawAttributes is Map<String, dynamic>
        ? ProfileAttributes.fromJson(rawAttributes)
        : const ProfileAttributes();
    final rawGender = json['gender'] as String? ?? '';
    final facts = attributes.facts;
    if (rawGender.trim().isNotEmpty) {
      facts.addAll({'Gender': readableProfileValue(rawGender)});
    }
    return PublicUserProfile(
      id: json['id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      dateOfBirth: DateTime.tryParse(json['date_of_birth'] as String? ?? ''),
      gender: rawGender,
      city: json['city_name'] as String? ?? '',
      aboutMe: json['about_me'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      interests: rawInterests
          .whereType<Map<String, dynamic>>()
          .map(ProfileInterest.fromJson)
          .toList(growable: false),
      photos: photos,
      facts: facts,
    );
  }
}

String readableProfileValue(String value) {
  final normalized = value.trim().replaceAll('_', ' ');
  if (normalized.isEmpty) return '';
  final words = normalized.split(RegExp(r'\s+'));
  return words
      .map((word) {
        final lower = word.toLowerCase();
        if (lower == 'doesnt') return "Doesn't";
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

String profileAttributeLabel(String key) => _profileFactLabel(key);

String _profileFactLabel(String key) => switch (key) {
  'smoking_attitude' => 'Smoking',
  'alcohol_attitude' => 'Alcohol',
  'children_preference' => 'Children preference',
  'what_looking_for' => 'Looking for',
  'appearance' => 'Appearance',
  'religion' => 'Religion',
  'height' => 'Height',
  _ => readableProfileValue(key),
};

int? profileAge(DateTime? birthDate, [DateTime? today]) {
  if (birthDate == null) return null;
  final now = today ?? DateTime.now();
  var years = now.year - birthDate.year;
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    years--;
  }
  return years;
}

enum ProfileCompletionStep { primaryPhoto, about, interests, city, lookingFor }

enum ProfileEditSection { basic, about, interests, attributes, photos }

class ProfileCompleteness {
  const ProfileCompleteness({required this.completedSteps});

  static const totalSteps = 5;
  final Set<ProfileCompletionStep> completedSteps;

  int get completedCount => completedSteps.length;
  int get percent => completedCount * 20;
  bool get isComplete => completedCount == totalSteps;

  ProfileCompletionStep? get nextStep {
    for (final step in ProfileCompletionStep.values) {
      if (!completedSteps.contains(step)) return step;
    }
    return null;
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    required this.city,
    required this.aboutMe,
    required this.status,
    required this.isSubscription,
    this.avatarUrl,
    this.attributes = const ProfileAttributes(),
    this.deleted = false,
    required this.interests,
    required this.photos,
  });

  final int id;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String gender;
  final String city;
  final String aboutMe;
  final String status;
  final bool isSubscription;
  final String? avatarUrl;
  final ProfileAttributes attributes;
  final bool deleted;
  final List<ProfileInterest> interests;
  final List<ProfilePhoto> photos;

  int? get age => profileAge(dateOfBirth);

  String get displayName => [
    firstName.trim(),
    lastName.trim(),
  ].where((part) => part.isNotEmpty).join(' ');

  ProfilePhoto? get avatarPhoto {
    for (final photo in photos) {
      if (photo.isAvatar) return photo;
    }
    return null;
  }

  String? get primaryPhotoUrl {
    final photo = avatarPhoto?.url.trim();
    if (photo != null && photo.isNotEmpty) return photo;
    final avatar = avatarUrl?.trim();
    return avatar == null || avatar.isEmpty ? null : avatar;
  }

  ProfileCompleteness get completeness {
    final completed = <ProfileCompletionStep>{};
    if (avatarPhoto != null) completed.add(ProfileCompletionStep.primaryPhoto);
    if (aboutMe.trim().isNotEmpty) completed.add(ProfileCompletionStep.about);
    if (interests.isNotEmpty) completed.add(ProfileCompletionStep.interests);
    if (city.trim().isNotEmpty) completed.add(ProfileCompletionStep.city);
    if (attributes.whatLookingFor?.trim().isNotEmpty ?? false) {
      completed.add(ProfileCompletionStep.lookingFor);
    }
    return ProfileCompleteness(completedSteps: completed);
  }

  PublicUserProfile toPublicProfile() {
    final facts = attributes.facts;
    if (gender.trim().isNotEmpty) {
      facts.addAll({'Gender': readableProfileValue(gender)});
    }
    return PublicUserProfile(
      id: id,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      city: city,
      aboutMe: aboutMe,
      avatarUrl: avatarUrl,
      interests: interests,
      photos: photos,
      facts: facts,
    );
  }

  UserProfile withPhotos(List<ProfilePhoto> value) => copyWith(photos: value);

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    String? city,
    String? aboutMe,
    String? status,
    bool? isSubscription,
    String? avatarUrl,
    ProfileAttributes? attributes,
    bool? deleted,
    List<ProfileInterest>? interests,
    List<ProfilePhoto>? photos,
  }) => UserProfile(
    id: id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    gender: gender ?? this.gender,
    city: city ?? this.city,
    aboutMe: aboutMe ?? this.aboutMe,
    status: status ?? this.status,
    isSubscription: isSubscription ?? this.isSubscription,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    attributes: attributes ?? this.attributes,
    deleted: deleted ?? this.deleted,
    interests: interests ?? this.interests,
    photos: photos ?? this.photos,
  );

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final interests = json['interests'] as List<dynamic>? ?? const [];
    final rawAttributes = json['attributes'];
    return UserProfile(
      id: json['id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      dateOfBirth: DateTime.tryParse(json['date_of_birth'] as String? ?? ''),
      gender: json['gender'] as String? ?? '',
      city: json['city_name'] as String? ?? '',
      aboutMe: json['about_me'] as String? ?? '',
      status: json['status'] as String? ?? '',
      isSubscription: json['is_subscription'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
      attributes: rawAttributes is Map<String, dynamic>
          ? ProfileAttributes.fromJson(rawAttributes)
          : const ProfileAttributes(),
      deleted: json['deleted'] as bool? ?? false,
      interests: interests
          .whereType<Map<String, dynamic>>()
          .map(ProfileInterest.fromJson)
          .toList(growable: false),
      photos: const [],
    );
  }
}

class ProfileEditDraft {
  const ProfileEditDraft({
    required this.firstName,
    required this.dateOfBirth,
    required this.gender,
    required this.city,
    required this.aboutMe,
    required this.heightText,
    required this.interestIds,
    required this.attributes,
  });

  final String firstName;
  final DateTime? dateOfBirth;
  final String gender;
  final String city;
  final String aboutMe;
  final String heightText;
  final List<int> interestIds;
  final ProfileAttributes attributes;

  factory ProfileEditDraft.fromProfile(UserProfile profile) => ProfileEditDraft(
    firstName: profile.firstName,
    dateOfBirth: profile.dateOfBirth,
    gender: profile.gender,
    city: profile.city,
    aboutMe: profile.aboutMe,
    heightText: profile.attributes.height?.toString() ?? '',
    interestIds: profile.interests
        .map((interest) => interest.id)
        .toList(growable: false),
    attributes: profile.attributes,
  );

  ProfileEditDraft copyWith({
    String? firstName,
    DateTime? dateOfBirth,
    String? gender,
    String? city,
    String? aboutMe,
    String? heightText,
    List<int>? interestIds,
    ProfileAttributes? attributes,
  }) => ProfileEditDraft(
    firstName: firstName ?? this.firstName,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    gender: gender ?? this.gender,
    city: city ?? this.city,
    aboutMe: aboutMe ?? this.aboutMe,
    heightText: heightText ?? this.heightText,
    interestIds: interestIds ?? this.interestIds,
    attributes: attributes ?? this.attributes,
  );

  bool sameValues(ProfileEditDraft other) =>
      firstName == other.firstName &&
      _sameDate(dateOfBirth, other.dateOfBirth) &&
      gender == other.gender &&
      city == other.city &&
      aboutMe == other.aboutMe &&
      heightText == other.heightText &&
      _listEquality.equals(interestIds, other.interestIds) &&
      attributes == other.attributes;
}

class ProfileUpdate {
  const ProfileUpdate({
    this.firstName,
    this.dateOfBirth,
    this.gender,
    this.city,
    this.aboutMe,
  });

  final String? firstName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? city;
  final String? aboutMe;

  bool get isEmpty =>
      firstName == null &&
      dateOfBirth == null &&
      gender == null &&
      city == null &&
      aboutMe == null;

  Map<String, dynamic> toJson() => {
    if (firstName != null) 'first_name': firstName,
    if (dateOfBirth != null) 'date_of_birth': _dateOnly(dateOfBirth!),
    if (gender != null) 'gender': gender,
    if (city != null) 'city_name': city,
    if (aboutMe != null) 'about_me': aboutMe,
  };
}

class ProfileSaveRequest {
  const ProfileSaveRequest({
    required this.profile,
    this.interestIds,
    this.attributeValues = const {},
  });

  final ProfileUpdate profile;
  final List<int>? interestIds;
  final Map<String, Object?> attributeValues;

  bool get isEmpty =>
      profile.isEmpty && interestIds == null && attributeValues.isEmpty;

  factory ProfileSaveRequest.fromDraft(
    ProfileEditDraft baseline,
    ProfileEditDraft draft,
  ) {
    final interestsChanged = !_listEquality.equals(
      baseline.interestIds,
      draft.interestIds,
    );
    final attributeValues = draft.attributes.changedValuesFrom(
      baseline.attributes,
    );
    if (baseline.heightText.trim() != draft.heightText.trim()) {
      attributeValues['height'] = draft.heightText.trim().isEmpty
          ? null
          : int.tryParse(draft.heightText.trim());
    }
    return ProfileSaveRequest(
      profile: ProfileUpdate(
        firstName: baseline.firstName == draft.firstName
            ? null
            : draft.firstName.trim(),
        dateOfBirth: _sameDate(baseline.dateOfBirth, draft.dateOfBirth)
            ? null
            : draft.dateOfBirth,
        gender: baseline.gender == draft.gender ? null : draft.gender,
        city: baseline.city == draft.city ? null : draft.city.trim(),
        aboutMe: baseline.aboutMe == draft.aboutMe ? null : draft.aboutMe,
      ),
      interestIds: interestsChanged
          ? List<int>.unmodifiable(draft.interestIds)
          : null,
      attributeValues: attributeValues,
    );
  }
}

enum ProfileSaveStage { basicInfo, interests, attributes }

class PartialProfileSaveException implements Exception {
  const PartialProfileSaveException({
    required this.completedStages,
    required this.cause,
    this.canonicalProfile,
  });

  final List<ProfileSaveStage> completedStages;
  final Object cause;
  final UserProfile? canonicalProfile;

  @override
  String toString() =>
      'Profile save stopped after ${completedStages.length} '
      'completed section(s): $cause';
}

class ProfilePhotoFile {
  const ProfilePhotoFile({required this.name, required this.bytes});

  final String name;
  final List<int> bytes;
}

class InvalidProfilePhotoException implements Exception {
  const InvalidProfilePhotoException(this.message);

  final String message;

  @override
  String toString() => message;
}

bool _sameDate(DateTime? left, DateTime? right) =>
    left?.year == right?.year &&
    left?.month == right?.month &&
    left?.day == right?.day;

String _dateOnly(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
