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
