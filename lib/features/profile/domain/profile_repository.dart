import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'profile_models.dart';

abstract interface class ProfileRepository {
  Future<UserProfile> getCurrentProfile();
  Future<UserProfile> updateProfile(ProfileUpdate update);
  Future<UserProfile> uploadPhoto(
    ProfilePhotoFile file, {
    bool isAvatar = false,
    ProgressCallback? onProgress,
  });
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
        .toList();
    return UserProfile.fromJson(profileData).withPhotos(photos);
  }

  @override
  Future<UserProfile> updateProfile(ProfileUpdate update) async {
    await _apiClient.request<void>(
      '/user/update_user',
      method: 'PUT',
      data: update.toJson(),
    );
    return getCurrentProfile();
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
  Future<UserProfile> setAvatar(int photoId) async {
    await _apiClient.post<void>('/user/set_avatar/$photoId');
    return getCurrentProfile();
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
