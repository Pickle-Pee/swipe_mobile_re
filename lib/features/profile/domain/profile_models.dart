class ProfileInterest {
  const ProfileInterest({required this.id, required this.label});

  final int id;
  final String label;

  factory ProfileInterest.fromJson(Map<String, dynamic> json) {
    return ProfileInterest(
      id: json['interest_id'] as int? ?? 0,
      label: json['interest_text'] as String? ?? '',
    );
  }
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
    required this.gender,
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

  int? get age {
    final birthDate = dateOfBirth;
    if (birthDate == null) return null;
    final now = DateTime.now();
    var years = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      years--;
    }
    return years;
  }

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
    final facts = <String, String>{};
    final rawGender = json['gender'];
    if (rawGender is String && rawGender.trim().isNotEmpty) {
      facts['Gender'] = readableProfileValue(rawGender);
    }
    final rawAttributes = json['attributes'];
    if (rawAttributes is Map<String, dynamic>) {
      for (final entry in rawAttributes.entries) {
        final value = entry.value;
        if (value == null || '$value'.trim().isEmpty) continue;
        final label = _profileFactLabel(entry.key);
        facts[label] = entry.key == 'height'
            ? '${readableProfileValue('$value')} cm'
            : readableProfileValue('$value');
      }
    }
    return PublicUserProfile(
      id: json['id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      dateOfBirth: DateTime.tryParse(json['date_of_birth'] as String? ?? ''),
      gender: rawGender as String? ?? '',
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

String _profileFactLabel(String key) => switch (key) {
  'smoking_attitude' => 'Smoking',
  'alcohol_attitude' => 'Alcohol',
  'children_preference' => 'Children preference',
  'what_looking_for' => 'Looking for',
  _ => readableProfileValue(key),
};

class UserProfile {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.city,
    required this.aboutMe,
    required this.status,
    required this.isSubscription,
    required this.interests,
    required this.photos,
  });

  final int id;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String city;
  final String aboutMe;
  final String status;
  final bool isSubscription;
  final List<ProfileInterest> interests;
  final List<ProfilePhoto> photos;

  int? get age {
    final birthDate = dateOfBirth;
    if (birthDate == null) return null;
    final now = DateTime.now();
    var years = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      years--;
    }
    return years;
  }

  UserProfile withPhotos(List<ProfilePhoto> value) => UserProfile(
    id: id,
    firstName: firstName,
    lastName: lastName,
    dateOfBirth: dateOfBirth,
    city: city,
    aboutMe: aboutMe,
    status: status,
    isSubscription: isSubscription,
    interests: interests,
    photos: value,
  );

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final interests = json['interests'] as List<dynamic>? ?? const [];
    return UserProfile(
      id: json['id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      dateOfBirth: DateTime.tryParse(json['date_of_birth'] as String? ?? ''),
      city: json['city_name'] as String? ?? '',
      aboutMe: json['about_me'] as String? ?? '',
      status: json['status'] as String? ?? '',
      isSubscription: json['is_subscription'] as bool? ?? false,
      interests: interests
          .whereType<Map<String, dynamic>>()
          .map(ProfileInterest.fromJson)
          .toList(),
      photos: const [],
    );
  }
}

class ProfileUpdate {
  const ProfileUpdate({
    required this.firstName,
    required this.city,
    required this.aboutMe,
  });

  final String firstName;
  final String city;
  final String aboutMe;

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'city_name': city,
    'about_me': aboutMe,
  };
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
