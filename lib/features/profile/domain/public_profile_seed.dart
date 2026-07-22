import '../../discovery/domain/discovery_models.dart';
import 'profile_models.dart';

PublicUserProfile? publicProfileSeedFromDiscovery(DiscoveryProfile? source) {
  if (source == null) return null;
  final photoUrl = source.photoUrl?.trim();
  return PublicUserProfile(
    id: source.id,
    firstName: source.firstName,
    lastName: '',
    dateOfBirth: source.dateOfBirth,
    gender: '',
    city: source.city,
    aboutMe: source.aboutMe,
    avatarUrl: source.photoUrl,
    interests: source.interests
        .map(
          (interest) => ProfileInterest(id: interest.id, label: interest.label),
        )
        .toList(growable: false),
    photos: photoUrl == null || photoUrl.isEmpty
        ? const []
        : [ProfilePhoto(id: -1, url: photoUrl, isAvatar: true)],
    facts: source.attributes,
  );
}
