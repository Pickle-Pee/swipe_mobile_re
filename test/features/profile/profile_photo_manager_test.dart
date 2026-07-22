import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/profile/application/profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/features/profile/presentation/edit_profile_components.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  testWidgets('photo manager exposes add, delete, and primary actions', (
    tester,
  ) async {
    var adds = 0;
    ProfilePhoto? deleted;
    int? primary;
    await _pump(
      tester,
      const ProfileState(status: ProfileStatus.data, profile: _profile),
      onAdd: () => adds++,
      onDelete: (photo) => deleted = photo,
      onSetPrimary: (id) => primary = id,
    );

    await tester.tap(find.byKey(const Key('add-profile-photo')));
    await tester.tap(find.text('Primary').last);
    await tester.tap(find.byKey(const ValueKey<String>('delete-photo-2')));

    expect(adds, 1);
    expect(primary, 2);
    expect(deleted?.id, 2);
    expect(
      find.textContaining('server does not store a stable order'),
      findsOneWidget,
    );
  });

  testWidgets('upload progress and local retry do not replace photo list', (
    tester,
  ) async {
    var retries = 0;
    await _pump(
      tester,
      ProfileState(
        status: ProfileStatus.data,
        profile: _profile,
        photoError: Exception('timeout'),
        canRetryPhotoUpload: true,
      ),
      onRetry: () => retries++,
    );

    expect(find.byKey(const Key('profile-photo-error')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('editable-photo-1')),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    expect(retries, 1);

    await _pump(
      tester,
      const ProfileState(
        status: ProfileStatus.data,
        profile: _profile,
        photoOperation: ProfilePhotoOperation.uploading,
        uploadProgress: 0.5,
      ),
    );
    expect(find.text('Uploading photo · 50%'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  ProfileState state, {
  VoidCallback? onAdd,
  VoidCallback? onRetry,
  ValueChanged<ProfilePhoto>? onDelete,
  ValueChanged<int>? onSetPrimary,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.midnight(),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ProfilePhotoManager(
            state: state,
            onAdd: onAdd ?? () {},
            onRetryUpload: onRetry ?? () {},
            onDelete: onDelete ?? (_) {},
            onSetPrimary: onSetPrimary ?? (_) {},
            imageProviderBuilder: (_) => null,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

const _profile = UserProfile(
  id: 1,
  firstName: 'Mila',
  lastName: '',
  dateOfBirth: null,
  city: 'Lisbon',
  aboutMe: '',
  status: '',
  isSubscription: false,
  interests: [],
  photos: [
    ProfilePhoto(id: 1, url: 'memory://primary', isAvatar: true),
    ProfilePhoto(id: 2, url: 'memory://alternate', isAvatar: false),
  ],
);
