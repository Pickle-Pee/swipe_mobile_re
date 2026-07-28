import '../../profile/domain/profile_models.dart';

enum OnboardingStep { basic, preferences, interests, photos, review }

class OnboardingReadiness {
  const OnboardingReadiness({
    required this.basicProfile,
    required this.preferences,
    required this.interests,
  });

  final bool basicProfile;
  final bool preferences;
  final bool interests;

  bool get isComplete => basicProfile && preferences && interests;

  OnboardingStep? get firstMissingStep {
    if (!basicProfile) return OnboardingStep.basic;
    if (!preferences) return OnboardingStep.preferences;
    if (!interests) return OnboardingStep.interests;
    return null;
  }

  factory OnboardingReadiness.fromProfile(UserProfile profile) {
    return OnboardingReadiness(
      basicProfile:
          profile.firstName.trim().isNotEmpty &&
          profile.dateOfBirth != null &&
          profile.gender.trim().isNotEmpty &&
          profile.city.trim().isNotEmpty,
      preferences:
          profile.attributes.whatLookingFor?.trim().isNotEmpty ?? false,
      interests: profile.interests.isNotEmpty,
    );
  }
}

class OnboardingDraft {
  const OnboardingDraft({
    required this.firstName,
    required this.dateOfBirth,
    required this.gender,
    required this.city,
    required this.aboutMe,
    required this.whatLookingFor,
    required this.interestIds,
  });

  final String firstName;
  final DateTime? dateOfBirth;
  final String gender;
  final String city;
  final String aboutMe;
  final String whatLookingFor;
  final List<int> interestIds;

  factory OnboardingDraft.fromProfile(UserProfile profile) {
    return OnboardingDraft(
      firstName: profile.firstName,
      dateOfBirth: profile.dateOfBirth,
      gender: profile.gender,
      city: profile.city,
      aboutMe: profile.aboutMe,
      whatLookingFor: profile.attributes.whatLookingFor ?? '',
      interestIds: profile.interests
          .map((interest) => interest.id)
          .toList(growable: false),
    );
  }

  OnboardingDraft copyWith({
    String? firstName,
    DateTime? dateOfBirth,
    String? gender,
    String? city,
    String? aboutMe,
    String? whatLookingFor,
    List<int>? interestIds,
  }) {
    return OnboardingDraft(
      firstName: firstName ?? this.firstName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      aboutMe: aboutMe ?? this.aboutMe,
      whatLookingFor: whatLookingFor ?? this.whatLookingFor,
      interestIds: interestIds ?? this.interestIds,
    );
  }
}

bool isAtLeastEighteen(DateTime value, [DateTime? today]) {
  final now = today ?? DateTime.now();
  final threshold = DateTime(now.year - 18, now.month, now.day);
  final dateOnly = DateTime(value.year, value.month, value.day);
  return !dateOnly.isAfter(threshold);
}
