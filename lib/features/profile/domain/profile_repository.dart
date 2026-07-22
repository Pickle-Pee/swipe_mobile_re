import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'profile_models.dart';

abstract interface class ProfileRepository {
  Future<UserProfile> getCurrentProfile();
  Future<ProfileEditCatalog> getEditCatalog();
  Future<UserProfile> updateProfile(ProfileUpdate update);
  Future<UserProfile> saveProfile(ProfileSaveRequest request);
  Future<UserProfile> uploadPhoto(
    ProfilePhotoFile file, {
    bool isAvatar = false,
    ProgressCallback? onProgress,
  });
  Future<UserProfile> deletePhoto(int photoId, {bool wasAvatar = false});
  Future<UserProfile> setAvatar(int photoId);
}

class DioProfileRepository implements ProfileRepository {
  DioProfileRepository(this._apiClient);

  static const maxPhotoBytes = 10 * 1024 * 1024;
  static const supportedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  final ApiClient _apiClient;

  @override
  Future<UserProfile> getCurrentProfile() async {
    final responses = await Future.wait([
      _apiClient.get<Map<String, dynamic>>('/user/me'),
      _apiClient.get<Map<String, dynamic>>('/user/user/photos'),
    ]);
    final profileData = responses[0].data;
    final photosData = responses[1].data;
    if (profileData == null) {
      throw const FormatException('Empty profile response');
    }
    final photoItems = photosData?['photos'] as List<dynamic>? ?? const [];
    final photos = photoItems
        .whereType<Map<String, dynamic>>()
        .map(ProfilePhoto.fromJson)
        .toList(growable: false);
    return UserProfile.fromJson(profileData).withPhotos(photos);
  }

  @override
  Future<ProfileEditCatalog> getEditCatalog() async {
    final responses = await Future.wait([
      _apiClient.get<Map<String, dynamic>>('/interest/interests_list'),
      _apiClient.get<Map<String, dynamic>>('/attributes/'),
    ]);
    final interestsData = responses[0].data;
    final attributesData = responses[1].data;
    final interestItems =
        interestsData?['interests'] as List<dynamic>? ?? const [];
    final attributes = <String, List<ProfileAttributeOption>>{};
    if (attributesData != null) {
      for (final entry in attributesData.entries) {
        final value = entry.value;
        if (value is! List<dynamic>) continue;
        attributes[entry.key] = value
            .whereType<Map<String, dynamic>>()
            .map(ProfileAttributeOption.fromJson)
            .where((option) => option.description.trim().isNotEmpty)
            .toList(growable: false);
      }
    }
    return ProfileEditCatalog(
      interests: interestItems
          .whereType<Map<String, dynamic>>()
          .map(ProfileInterest.fromJson)
          .where(
            (interest) => interest.id > 0 && interest.label.trim().isNotEmpty,
          )
          .toList(growable: false),
      attributes: attributes,
    );
  }

  @override
  Future<UserProfile> updateProfile(ProfileUpdate update) async {
    if (!update.isEmpty) {
      await _apiClient.request<void>(
        '/user/update_user',
        method: 'PUT',
        data: update.toJson(),
      );
    }
    return getCurrentProfile();
  }

  @override
  Future<UserProfile> saveProfile(ProfileSaveRequest request) async {
    if (request.isEmpty) return getCurrentProfile();
    final completed = <ProfileSaveStage>[];
    try {
      if (!request.profile.isEmpty) {
        await _apiClient.request<void>(
          '/user/update_user',
          method: 'PUT',
          data: request.profile.toJson(),
        );
        completed.add(ProfileSaveStage.basicInfo);
      }
      final interests = request.interestIds;
      if (interests != null) {
        await _apiClient.post<void>(
          '/interest/add_interests',
          data: {'interest_ids': interests},
        );
        completed.add(ProfileSaveStage.interests);
      }
      if (request.attributeValues.isNotEmpty) {
        await _apiClient.post<void>(
          '/attributes/add_attributes',
          data: request.attributeValues,
        );
        completed.add(ProfileSaveStage.attributes);
      }
      final canonical = await getCurrentProfile();
      _verifySaved(request, canonical);
      return canonical;
    } on Object catch (error) {
      if (completed.isEmpty) rethrow;
      UserProfile? canonical;
      try {
        canonical = await getCurrentProfile();
      } on Object {
        // The original error remains the actionable failure. A later retry
        // will refresh canonical state before publishing success.
      }
      throw PartialProfileSaveException(
        completedStages: List.unmodifiable(completed),
        cause: error,
        canonicalProfile: canonical,
      );
    }
  }

  @override
  Future<UserProfile> uploadPhoto(
    ProfilePhotoFile file, {
    bool isAvatar = false,
    ProgressCallback? onProgress,
  }) async {
    _validatePhoto(file);
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes, filename: file.name),
    });
    await _apiClient.post<void>(
      '/service/upload/profile_photo',
      data: formData,
      queryParameters: {'is_avatar': isAvatar},
      onSendProgress: onProgress,
    );
    return getCurrentProfile();
  }

  @override
  Future<UserProfile> deletePhoto(int photoId, {bool wasAvatar = false}) async {
    await _apiClient.request<void>('/user/photos/$photoId', method: 'DELETE');
    var profile = await getCurrentProfile();
    if (wasAvatar && profile.photos.isNotEmpty && profile.avatarPhoto == null) {
      await _apiClient.post<void>(
        '/user/set_avatar/${profile.photos.first.id}',
      );
      profile = await getCurrentProfile();
    }
    return profile;
  }

  @override
  Future<UserProfile> setAvatar(int photoId) async {
    await _apiClient.post<void>('/user/set_avatar/$photoId');
    return getCurrentProfile();
  }

  void _verifySaved(ProfileSaveRequest request, UserProfile canonical) {
    final mismatches = <String>[];
    final update = request.profile;
    if (update.firstName != null && update.firstName != canonical.firstName) {
      mismatches.add('first_name');
    }
    if (update.dateOfBirth != null &&
        !_sameDate(update.dateOfBirth, canonical.dateOfBirth)) {
      mismatches.add('date_of_birth');
    }
    if (update.gender != null && update.gender != canonical.gender) {
      mismatches.add('gender');
    }
    if (update.city != null && update.city != canonical.city) {
      mismatches.add('city_name');
    }
    if (update.aboutMe != null && update.aboutMe != canonical.aboutMe) {
      mismatches.add('about_me');
    }
    final interests = request.interestIds;
    if (interests != null &&
        interests
            .toSet()
            .difference(
              canonical.interests.map((interest) => interest.id).toSet(),
            )
            .isNotEmpty) {
      mismatches.add('interests');
    }
    if (interests != null &&
        canonical.interests
            .map((interest) => interest.id)
            .toSet()
            .difference(interests.toSet())
            .isNotEmpty) {
      mismatches.add('interests');
    }
    for (final entry in request.attributeValues.entries) {
      if (canonical.attributes.valueFor(entry.key) != entry.value) {
        mismatches.add(entry.key);
      }
    }
    if (mismatches.isNotEmpty) {
      throw ProfileSaveVerificationException(
        mismatches.toSet().toList(growable: false),
      );
    }
  }

  void _validatePhoto(ProfilePhotoFile file) {
    final extension = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : '';
    if (!supportedExtensions.contains(extension)) {
      throw const InvalidProfilePhotoException(
        'Choose a JPG, PNG, or WebP image',
      );
    }
    if (file.bytes.isEmpty) {
      throw const InvalidProfilePhotoException('The selected image is empty');
    }
    if (file.bytes.length > maxPhotoBytes) {
      throw const InvalidProfilePhotoException(
        'The selected image must be 10 MB or smaller',
      );
    }
    if (!_matchesImageSignature(extension, file.bytes)) {
      throw const InvalidProfilePhotoException(
        'The selected file is not a valid image',
      );
    }
  }

  bool _matchesImageSignature(String extension, List<int> bytes) {
    bool startsWith(List<int> signature) {
      if (bytes.length < signature.length) return false;
      for (var index = 0; index < signature.length; index++) {
        if (bytes[index] != signature[index]) return false;
      }
      return true;
    }

    if (extension == 'jpg' || extension == 'jpeg') {
      return startsWith(const [0xFF, 0xD8, 0xFF]);
    }
    if (extension == 'png') {
      return startsWith(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    }
    return bytes.length >= 12 &&
        String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
        String.fromCharCodes(bytes.skip(8).take(4)) == 'WEBP';
  }
}

bool _sameDate(DateTime? left, DateTime? right) =>
    left?.year == right?.year &&
    left?.month == right?.month &&
    left?.day == right?.day;
