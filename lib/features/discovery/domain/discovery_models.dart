class DiscoveryInterest {
  const DiscoveryInterest({required this.id, required this.label});
  final int id;
  final String label;

  factory DiscoveryInterest.fromJson(Map<String, dynamic> json) =>
      DiscoveryInterest(
        id: json['interest_id'] as int? ?? 0,
        label: json['interest_text'] as String? ?? '',
      );
}

class DiscoveryProfile {
  const DiscoveryProfile({
    required this.id,
    required this.firstName,
    required this.dateOfBirth,
    required this.city,
    required this.aboutMe,
    required this.photoUrl,
    required this.interests,
    required this.attributes,
  });

  final int id;
  final String firstName;
  final DateTime? dateOfBirth;
  final String city;
  final String aboutMe;
  final String? photoUrl;
  final List<DiscoveryInterest> interests;
  final Map<String, String> attributes;

  int? get age {
    final birth = dateOfBirth;
    if (birth == null) return null;
    final now = DateTime.now();
    var result = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      result--;
    }
    return result;
  }

  factory DiscoveryProfile.fromJson(
    Map<String, dynamic> match,
    Map<String, dynamic> details,
  ) {
    final rawFirstName = details['first_name'] ?? match['first_name'];
    final rawDateOfBirth =
        details['date_of_birth'] ?? match['date_of_birth'];
    final rawCity = details['city_name'] ?? match['city_name'];
    final rawPhotoUrl = details['avatar_url'] ?? match['avatar_url'];
    final interests = details['interests'] as List<dynamic>? ?? const [];
    final rawAttributes = details['attributes'];
    final attributes = <String, String>{};
    if (rawAttributes is Map<String, dynamic>) {
      for (final entry in rawAttributes.entries) {
        if (entry.value != null && '${entry.value}'.isNotEmpty) {
          attributes[_attributeLabel(entry.key)] = '${entry.value}';
        }
      }
    }
    return DiscoveryProfile(
      id: match['user_id'] as int,
      firstName: rawFirstName is String ? rawFirstName : '',
      dateOfBirth:
          DateTime.tryParse(rawDateOfBirth is String ? rawDateOfBirth : ''),
      city: rawCity is String ? rawCity : '',
      aboutMe: details['about_me'] as String? ?? '',
      photoUrl: rawPhotoUrl is String ? rawPhotoUrl : null,
      interests: interests
          .whereType<Map<String, dynamic>>()
          .map(DiscoveryInterest.fromJson)
          .toList(),
      attributes: attributes,
    );
  }

  static String _attributeLabel(String key) => key
      .split('_')
      .map((part) => part.isEmpty
          ? part
          : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

enum DiscoveryReaction { like, pass }

class DiscoveryReactionResult {
  const DiscoveryReactionResult({required this.isMatch});
  final bool isMatch;
}
