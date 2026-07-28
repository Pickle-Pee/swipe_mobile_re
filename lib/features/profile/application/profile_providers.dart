import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/profile_models.dart';
import '../domain/profile_repository.dart';

const _unset = Object();

enum ProfileStatus { initial, loading, data, empty, error }

enum ProfilePhotoOperation { idle, picking, uploading, deleting, settingAvatar }

class ProfileState {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.error,
    this.photoOperation = ProfilePhotoOperation.idle,
    this.photoTargetId,
    this.uploadProgress,
    this.photoError,
    this.canRetryPhotoUpload = false,
  });

  final ProfileStatus status;
  final UserProfile? profile;
  final Object? error;
  final ProfilePhotoOperation photoOperation;
  final int? photoTargetId;
  final double? uploadProgress;
  final Object? photoError;
  final bool canRetryPhotoUpload;

  bool get isPhotoBusy => photoOperation != ProfilePhotoOperation.idle;

  ProfileState copyWith({
    ProfileStatus? status,
    Object? profile = _unset,
    Object? error = _unset,
    ProfilePhotoOperation? photoOperation,
    Object? photoTargetId = _unset,
    Object? uploadProgress = _unset,
    Object? photoError = _unset,
    bool? canRetryPhotoUpload,
  }) => ProfileState(
    status: status ?? this.status,
    profile: identical(profile, _unset)
        ? this.profile
        : profile as UserProfile?,
    error: identical(error, _unset) ? this.error : error,
    photoOperation: photoOperation ?? this.photoOperation,
    photoTargetId: identical(photoTargetId, _unset)
        ? this.photoTargetId
        : photoTargetId as int?,
    uploadProgress: identical(uploadProgress, _unset)
        ? this.uploadProgress
        : uploadProgress as double?,
    photoError: identical(photoError, _unset) ? this.photoError : photoError,
    canRetryPhotoUpload: canRetryPhotoUpload ?? this.canRetryPhotoUpload,
  );
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
  ProfilePhotoFile? _failedPhotoFile;
  Future<void>? _loadFuture;

  @override
  ProfileState build() {
    final userId = ref.watch(
      authControllerProvider.select((auth) => auth.user?.id),
    );
    _failedPhotoFile = null;
    _loadFuture = null;
    if (userId != null) Future.microtask(load);
    return const ProfileState();
  }

  Future<void> load() {
    final running = _loadFuture;
    if (running != null) return running;
    late final Future<void> tracked;
    tracked = _performLoad().whenComplete(() {
      if (identical(_loadFuture, tracked)) _loadFuture = null;
    });
    _loadFuture = tracked;
    return tracked;
  }

  Future<void> _performLoad() async {
    final userId = ref.read(authControllerProvider).user?.id;
    state = state.copyWith(
      status: ProfileStatus.loading,
      error: null,
      photoError: null,
    );
    try {
      final profile = await _repository.getCurrentProfile();
      if (ref.read(authControllerProvider).user?.id != userId) return;
      adopt(profile);
    } on Object catch (error) {
      if (ref.read(authControllerProvider).user?.id != userId) return;
      state = state.copyWith(status: ProfileStatus.error, error: error);
    }
  }

  Future<bool> update(ProfileUpdate update) async {
    try {
      adopt(await _repository.updateProfile(update));
      return true;
    } on Object catch (error) {
      state = state.copyWith(status: ProfileStatus.error, error: error);
      return false;
    }
  }

  Future<bool> pickAndUploadPhoto() async {
    if (state.isPhotoBusy) return false;
    _failedPhotoFile = null;
    state = state.copyWith(
      photoOperation: ProfilePhotoOperation.picking,
      photoError: null,
      uploadProgress: null,
      canRetryPhotoUpload: false,
    );
    try {
      final file = await ref.read(profilePhotoPickerProvider).pickFromGallery();
      if (file == null) {
        _finishPhotoOperation();
        return false;
      }
      return _uploadPhoto(file);
    } on Object catch (error) {
      _finishPhotoOperation(error: error);
      return false;
    }
  }

  Future<bool> retryPhotoUpload() async {
    final file = _failedPhotoFile;
    if (file == null || state.isPhotoBusy) return false;
    return _uploadPhoto(file);
  }

  Future<bool> _uploadPhoto(ProfilePhotoFile file) async {
    state = state.copyWith(
      photoOperation: ProfilePhotoOperation.uploading,
      photoError: null,
      uploadProgress: 0.0,
      canRetryPhotoUpload: false,
    );
    try {
      final profile = await _repository.uploadPhoto(
        file,
        isAvatar: state.profile?.photos.isEmpty ?? true,
        onProgress: (sent, total) {
          if (total <= 0 ||
              state.photoOperation != ProfilePhotoOperation.uploading) {
            return;
          }
          state = state.copyWith(uploadProgress: sent / total);
        },
      );
      _failedPhotoFile = null;
      adopt(profile);
      return true;
    } on Object catch (error) {
      _failedPhotoFile = file;
      _finishPhotoOperation(error: error, canRetry: true);
      return false;
    }
  }

  Future<bool> deletePhoto(ProfilePhoto photo) async {
    if (state.isPhotoBusy) return false;
    state = state.copyWith(
      photoOperation: ProfilePhotoOperation.deleting,
      photoTargetId: photo.id,
      photoError: null,
      canRetryPhotoUpload: false,
    );
    try {
      adopt(await _repository.deletePhoto(photo.id, wasAvatar: photo.isAvatar));
      return true;
    } on Object catch (error) {
      _finishPhotoOperation(error: error);
      return false;
    }
  }

  Future<bool> setAvatar(int photoId) async {
    if (state.isPhotoBusy) return false;
    state = state.copyWith(
      photoOperation: ProfilePhotoOperation.settingAvatar,
      photoTargetId: photoId,
      photoError: null,
      canRetryPhotoUpload: false,
    );
    try {
      adopt(await _repository.setAvatar(photoId));
      return true;
    } on Object catch (error) {
      _finishPhotoOperation(error: error);
      return false;
    }
  }

  void adopt(UserProfile profile) {
    final empty =
        profile.firstName.isEmpty &&
        profile.city.isEmpty &&
        profile.aboutMe.isEmpty &&
        profile.interests.isEmpty &&
        profile.photos.isEmpty;
    state = ProfileState(
      status: empty ? ProfileStatus.empty : ProfileStatus.data,
      profile: profile,
    );
  }

  void clearPhotoError() {
    state = state.copyWith(photoError: null, canRetryPhotoUpload: false);
    _failedPhotoFile = null;
  }

  void _finishPhotoOperation({Object? error, bool canRetry = false}) {
    state = state.copyWith(
      photoOperation: ProfilePhotoOperation.idle,
      photoTargetId: null,
      uploadProgress: null,
      photoError: error,
      canRetryPhotoUpload: canRetry,
    );
  }
}

enum ProfileEditCatalogStatus { idle, loading, data, error }

class ProfileEditState {
  const ProfileEditState({
    this.baseline,
    this.draft,
    this.catalog,
    this.catalogStatus = ProfileEditCatalogStatus.idle,
    this.isSaving = false,
    this.fieldErrors = const {},
    this.error,
  });

  final ProfileEditDraft? baseline;
  final ProfileEditDraft? draft;
  final ProfileEditCatalog? catalog;
  final ProfileEditCatalogStatus catalogStatus;
  final bool isSaving;
  final Map<String, String> fieldErrors;
  final Object? error;

  bool get isDirty {
    final original = baseline;
    final current = draft;
    return original != null && current != null && !original.sameValues(current);
  }

  bool get canSave => isDirty && !isSaving && fieldErrors.isEmpty;

  ProfileEditState copyWith({
    Object? baseline = _unset,
    Object? draft = _unset,
    Object? catalog = _unset,
    ProfileEditCatalogStatus? catalogStatus,
    bool? isSaving,
    Map<String, String>? fieldErrors,
    Object? error = _unset,
  }) => ProfileEditState(
    baseline: identical(baseline, _unset)
        ? this.baseline
        : baseline as ProfileEditDraft?,
    draft: identical(draft, _unset) ? this.draft : draft as ProfileEditDraft?,
    catalog: identical(catalog, _unset)
        ? this.catalog
        : catalog as ProfileEditCatalog?,
    catalogStatus: catalogStatus ?? this.catalogStatus,
    isSaving: isSaving ?? this.isSaving,
    fieldErrors: fieldErrors ?? this.fieldErrors,
    error: identical(error, _unset) ? this.error : error,
  );
}

final profileEditControllerProvider =
    NotifierProvider<ProfileEditController, ProfileEditState>(
      ProfileEditController.new,
    );

class ProfileEditController extends Notifier<ProfileEditState> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  ProfileEditState build() {
    ref.watch(authControllerProvider.select((auth) => auth.user?.id));
    return const ProfileEditState();
  }

  Future<void> begin(UserProfile profile) async {
    final draft = ProfileEditDraft.fromProfile(profile);
    final retainedCatalog = state.catalog;
    state = ProfileEditState(
      baseline: draft,
      draft: draft,
      catalog: retainedCatalog,
      catalogStatus: retainedCatalog == null
          ? ProfileEditCatalogStatus.loading
          : ProfileEditCatalogStatus.data,
    );
    if (retainedCatalog == null) await loadCatalog();
  }

  Future<void> loadCatalog() async {
    state = state.copyWith(
      catalogStatus: ProfileEditCatalogStatus.loading,
      error: null,
    );
    try {
      state = state.copyWith(
        catalog: await _repository.getEditCatalog(),
        catalogStatus: ProfileEditCatalogStatus.data,
      );
    } on Object catch (error) {
      state = state.copyWith(
        catalogStatus: ProfileEditCatalogStatus.error,
        error: error,
      );
    }
  }

  void updateFirstName(String value) => _update(
    (draft) => draft.copyWith(firstName: value),
    clearFieldError: 'first_name',
  );

  void updateDateOfBirth(DateTime value) => _update(
    (draft) => draft.copyWith(dateOfBirth: value),
    clearFieldError: 'date_of_birth',
  );

  void updateGender(String value) => _update(
    (draft) => draft.copyWith(gender: value),
    clearFieldError: 'gender',
  );

  void updateCity(String value) => _update(
    (draft) => draft.copyWith(city: value),
    clearFieldError: 'city_name',
  );

  void updateAboutMe(String value) => _update(
    (draft) => draft.copyWith(aboutMe: value),
    clearFieldError: 'about_me',
  );

  void updateHeight(String value) => _update(
    (draft) => draft.copyWith(heightText: value),
    clearFieldError: 'height',
  );

  void toggleInterest(int id) {
    final draft = state.draft;
    if (draft == null) return;
    final selected = [...draft.interestIds];
    selected.contains(id) ? selected.remove(id) : selected.add(id);
    _update((value) => value.copyWith(interestIds: selected));
  }

  void updateAttribute(String key, String? value) => _update(
    (draft) =>
        draft.copyWith(attributes: draft.attributes.copyWithValue(key, value)),
  );

  Future<UserProfile?> save() async {
    if (state.isSaving) return null;
    final baseline = state.baseline;
    final draft = state.draft;
    if (baseline == null || draft == null) return null;
    final errors = _validate(baseline, draft);
    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors, error: null);
      return null;
    }
    final request = ProfileSaveRequest.fromDraft(baseline, draft);
    if (request.isEmpty) return ref.read(profileControllerProvider).profile;
    state = state.copyWith(isSaving: true, fieldErrors: const {}, error: null);
    try {
      final profile = await _repository.saveProfile(request);
      ref.read(profileControllerProvider.notifier).adopt(profile);
      final canonical = ProfileEditDraft.fromProfile(profile);
      state = state.copyWith(
        baseline: canonical,
        draft: canonical,
        isSaving: false,
      );
      return profile;
    } on PartialProfileSaveException catch (error) {
      final canonical = error.canonicalProfile;
      if (canonical != null) {
        ref.read(profileControllerProvider.notifier).adopt(canonical);
        state = state.copyWith(
          baseline: ProfileEditDraft.fromProfile(canonical),
          isSaving: false,
          error: error,
        );
      } else {
        state = state.copyWith(isSaving: false, error: error);
      }
      return null;
    } on Object catch (error) {
      state = state.copyWith(isSaving: false, error: error);
      return null;
    }
  }

  void discard() {
    final baseline = state.baseline;
    state = state.copyWith(draft: baseline, fieldErrors: const {}, error: null);
  }

  void clearError() => state = state.copyWith(error: null);

  void _update(
    ProfileEditDraft Function(ProfileEditDraft draft) change, {
    String? clearFieldError,
  }) {
    final draft = state.draft;
    if (draft == null || state.isSaving) return;
    final changed = change(draft);
    final baseline = state.baseline;
    final errors = baseline == null
        ? <String, String>{}
        : _validate(baseline, changed);
    if (clearFieldError != null && errors[clearFieldError] == null) {
      errors.remove(clearFieldError);
    }
    state = state.copyWith(draft: changed, fieldErrors: errors, error: null);
  }

  Map<String, String> _validate(
    ProfileEditDraft baseline,
    ProfileEditDraft draft,
  ) {
    final errors = <String, String>{};
    if (draft.firstName.trim().isEmpty) {
      errors['first_name'] = 'First name is required';
    }
    if (draft.dateOfBirth == null) {
      errors['date_of_birth'] = 'Date of birth is required';
    }
    if (draft.gender.trim().isEmpty) {
      errors['gender'] = 'Choose a gender';
    }
    if (draft.city.trim().isEmpty) {
      errors['city_name'] = 'City is required';
    }
    if (baseline.aboutMe.trim().isNotEmpty && draft.aboutMe.trim().isEmpty) {
      errors['about_me'] =
          'The current server cannot clear an existing introduction';
    }
    final height = draft.heightText.trim();
    if (height.isNotEmpty && int.tryParse(height) == null) {
      errors['height'] = 'Height must be a whole number';
    }
    return errors;
  }
}
