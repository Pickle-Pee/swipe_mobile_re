class LikesUser {
  const LikesUser({
    required this.id,
    required this.firstName,
    required this.dateOfBirth,
    required this.city,
    required this.aboutMe,
    required this.status,
    required this.avatarUrl,
    required this.mutual,
  });

  final int id;
  final String firstName;
  final DateTime? dateOfBirth;
  final String city;
  final String aboutMe;
  final String status;
  final String? avatarUrl;
  final bool mutual;

  int? get age {
    final birth = dateOfBirth;
    if (birth == null) return null;
    final now = DateTime.now();
    var years = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      years--;
    }
    return years;
  }

  factory LikesUser.fromJson(Map<String, dynamic> json) => LikesUser(
    id: json['id'] as int,
    firstName: json['first_name'] as String? ?? '',
    dateOfBirth: DateTime.tryParse(json['date_of_birth'] as String? ?? ''),
    city: json['city_name'] as String? ?? '',
    aboutMe: json['about_me'] as String? ?? '',
    status: json['status'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String?,
    mutual: json['mutual'] as bool? ?? false,
  );
}

class LikesData {
  const LikesData({
    required this.likedMe,
    required this.likedUsers,
    required this.favorites,
    required this.mutual,
  });

  final List<LikesUser> likedMe;
  final List<LikesUser> likedUsers;
  final List<LikesUser> favorites;
  final List<LikesUser> mutual;
}
