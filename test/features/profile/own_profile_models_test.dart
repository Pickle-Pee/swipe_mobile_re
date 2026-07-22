import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';

void main() {
  test('completeness uses five documented equal-weight saved steps', () {
    expect(_empty.completeness.percent, 0);
    expect(_empty.completeness.nextStep, ProfileCompletionStep.primaryPhoto);

    expect(_complete.completeness.completedCount, 5);
    expect(_complete.completeness.percent, 100);
    expect(_complete.completeness.nextStep, isNull);
    expect(_complete.completeness.isComplete, isTrue);
  });

  test(
    'save request includes only values changed from the canonical draft',
    () {
      final baseline = ProfileEditDraft.fromProfile(_complete);
      final draft = baseline.copyWith(
        aboutMe: 'A changed introduction',
        heightText: '181',
        interestIds: [1, 2],
        attributes: baseline.attributes.copyWithValue(
          'what_looking_for',
          'New friends',
        ),
      );

      final request = ProfileSaveRequest.fromDraft(baseline, draft);

      expect(request.profile.toJson(), {'about_me': 'A changed introduction'});
      expect(request.interestIds, [1, 2]);
      expect(request.attributeValues, {
        'height': 181,
        'what_looking_for': 'New friends',
      });
    },
  );

  test('saved own profile converts to the shared public profile model', () {
    final preview = _complete.toPublicProfile();

    expect(preview.displayName, 'Mila Stone');
    expect(preview.heroPhotoUrl, '/primary.jpg');
    expect(preview.facts['Looking for'], 'Serious Relationship');
    expect(preview.facts['Height'], '180 cm');
    expect(preview.facts, isNot(contains('Status')));
  });

  test('catalog interests accept both list and user response identifiers', () {
    expect(
      ProfileInterest.fromJson({'id': 3, 'interest_text': 'Cinema'}).id,
      3,
    );
    expect(
      ProfileInterest.fromJson({'interest_id': 4, 'interest_text': 'Music'}).id,
      4,
    );
  });
}

const _empty = UserProfile(
  id: 1,
  firstName: 'Mila',
  lastName: '',
  dateOfBirth: null,
  city: '',
  aboutMe: '',
  status: 'online',
  isSubscription: false,
  interests: [],
  photos: [],
);

const _complete = UserProfile(
  id: 2,
  firstName: 'Mila',
  lastName: 'Stone',
  dateOfBirth: null,
  gender: 'female',
  city: 'Lisbon',
  aboutMe: 'Saved introduction',
  status: 'online',
  isSubscription: true,
  attributes: ProfileAttributes(
    height: 180,
    whatLookingFor: 'serious_relationship',
  ),
  interests: [ProfileInterest(id: 1, label: 'Travel')],
  photos: [ProfilePhoto(id: 1, url: '/primary.jpg', isAvatar: true)],
);
