import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/onboarding/domain/onboarding_models.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';

void main() {
  test('resume selects the first missing canonical setup step', () {
    expect(
      OnboardingReadiness.fromProfile(_profile(firstName: '')).firstMissingStep,
      OnboardingStep.basic,
    );
    expect(
      OnboardingReadiness.fromProfile(_profile(goal: null)).firstMissingStep,
      OnboardingStep.preferences,
    );
    expect(
      OnboardingReadiness.fromProfile(
        _profile(interests: const []),
      ).firstMissingStep,
      OnboardingStep.interests,
    );
  });

  test('photos are not fabricated as a server completion requirement', () {
    final readiness = OnboardingReadiness.fromProfile(
      _profile(photos: const []),
    );

    expect(readiness.isComplete, isTrue);
    expect(readiness.firstMissingStep, isNull);
  });

  test('draft keeps canonical interest identifiers', () {
    final draft = OnboardingDraft.fromProfile(_profile());

    expect(draft.interestIds, [7]);
    expect(draft.whatLookingFor, 'Serious relationship');
  });

  test('adult validation handles the exact birthday boundary', () {
    final today = DateTime(2026, 7, 27);

    expect(isAtLeastEighteen(DateTime(2008, 7, 27), today), isTrue);
    expect(isAtLeastEighteen(DateTime(2008, 7, 28), today), isFalse);
  });
}

UserProfile _profile({
  String firstName = 'Mila',
  String? goal = 'Serious relationship',
  List<ProfileInterest> interests = const [
    ProfileInterest(id: 7, label: 'Cinema'),
  ],
  List<ProfilePhoto> photos = const [],
}) {
  return UserProfile(
    id: 1,
    firstName: firstName,
    lastName: 'Stone',
    dateOfBirth: DateTime(1994, 5, 4),
    gender: 'female',
    city: 'Lisbon',
    aboutMe: '',
    status: '',
    isSubscription: false,
    attributes: ProfileAttributes(whatLookingFor: goal),
    interests: interests,
    photos: photos,
  );
}
