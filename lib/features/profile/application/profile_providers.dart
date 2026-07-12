import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/profile_models.dart';
import '../domain/profile_repository.dart';

enum ProfileStatus { initial, loading, data, empty, error }

class ProfileState {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.error,
    this.uploadProgress,
  });

  final ProfileStatus status;
  final UserProfile? profile;
  final Object? error;
  final double? uploadProgress;
}

abstract interface class ProfilePhotoPicker {
  Future<ProfilePhotoFile?> pickFromGallery();
}

class ImagePickerProfilePhotoPicker implements ProfilePhotoPicker {
  ImagePickerProfilePhotoPicker([ImagePicker? picker])
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<ProfilePhotoFile?> pickFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    if (await file.length() > DioProfileRepository.maxPhotoBytes) {
      throw const InvalidProfilePhotoException(
        'The selected image must be 10 MB or smaller',
      );
    }
    return ProfilePhotoFile(name: file.name, bytes: await file.readAsBytes());
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return DioProfileRepository(ref.watch(apiClientProvider));
});

final profilePhotoPickerProvider = Provider<ProfilePhotoPicker>((ref) {
  return ImagePickerProfilePhotoPicker();
});

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);

class ProfileController extends Notifier<ProfileState> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  ProfileState build() =>
      const ProfileState(status: ProfileStatus.loading);

  Future<void> load() async {
    state = ProfileState(
      status: ProfileStatus.loading,
      profile: state.profile,
    );
    try {
      _setProfile(await _repository.getCurrentProfile());
    } on Object catch (error) {
      state = ProfileState(
        status: ProfileStatus.error,
        profile: state.profile,
        error: error,
      );
    }
  }

  Future<bool> update(ProfileUpdate update) async {
    try {
      _setProfile(await _repository.updateProfile(update));
      return true;
    } on Object catch (error) {
      state = ProfileState(
        status: ProfileStatus.error,
        profile: state.profile,
        error: error,
      );
      return false;
    }
  }

  Future<void> pickAndUploadPhoto() async {
    try {
      final file =
          await ref.read(profilePhotoPickerProvider).pickFromGallery();
      if (file == null) return;
      state = ProfileState(
        status: state.status,
        profile: state.profile,
        uploadProgress: 0,
      );
      final profile = await _repository.uploadPhoto(
        file,
        isAvatar: state.profile?.photos.isEmpty ?? true,
        onProgress: (sent, total) {
          if (total > 0) {
            state = ProfileState(
              status: state.status,
              profile: state.profile,
              uploadProgress: sent / total,
            );
          }
        },
      );
      _setProfile(profile);
    } on Object catch (error) {
      state = ProfileState(
        status: ProfileStatus.error,
        profile: state.profile,
        error: error,
      );
    }
  }

  Future<void> setAvatar(int photoId) async {
    try {
      _setProfile(await _repository.setAvatar(photoId));
    } on Object catch (error) {
      state = ProfileState(
        status: ProfileStatus.error,
        profile: state.profile,
        error: error,
      );
    }
  }

  void _setProfile(UserProfile profile) {
    final empty = profile.firstName.isEmpty &&
        profile.city.isEmpty &&
        profile.aboutMe.isEmpty &&
        profile.interests.isEmpty &&
        profile.photos.isEmpty;
    state = ProfileState(
      status: empty ? ProfileStatus.empty : ProfileStatus.data,
      profile: profile,
    );
  }
}
