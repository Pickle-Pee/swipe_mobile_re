import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart';

import '../../app/router/routes.dart';
import '../../core/config/config.dart';
import '../../core/network/api_exception.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';
import 'application/profile_providers.dart';
import 'domain/profile_models.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(ref.read(profileControllerProvider.notifier).load);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final profile = state.profile;
    return Scaffold(
      body: AppGradientScaffold(
        child: RefreshIndicator(
          onRefresh: ref.read(profileControllerProvider.notifier).load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppTokens.screenPadding,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(Routes.discover),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Text(
                    'Profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (state.status == ProfileStatus.loading && profile == null)
                const Center(child: CircularProgressIndicator())
              else if (state.status == ProfileStatus.error && profile == null)
                _ErrorState(error: state.error, onRetry: _reload)
              else if (profile == null)
                _EmptyState(onRetry: _reload)
              else ...[
                _ProfileHeader(profile: profile),
                const SizedBox(height: 12),
                _PhotoSection(
                  profile: profile,
                  uploadProgress: state.uploadProgress,
                  onAdd: _uploadPhoto,
                  onSetAvatar: _setAvatar,
                ),
                const SizedBox(height: 12),
                _InterestSection(profile: profile),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => _editProfile(profile),
                    child: const Text('Edit profile'),
                  ),
                ),
                if (state.status == ProfileStatus.error) ...[
                  const SizedBox(height: 8),
                  _InlineError(error: state.error),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _reload() => ref.read(profileControllerProvider.notifier).load();
  void _uploadPhoto() =>
      ref.read(profileControllerProvider.notifier).pickAndUploadPhoto();
  void _setAvatar(int id) =>
      ref.read(profileControllerProvider.notifier).setAvatar(id);

  Future<void> _editProfile(UserProfile profile) async {
    final firstName = TextEditingController(text: profile.firstName);
    final city = TextEditingController(text: profile.city);
    final about = TextEditingController(text: profile.aboutMe);
    final update = await showDialog<ProfileUpdate>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstName,
                decoration: const InputDecoration(labelText: 'First name'),
              ),
              TextField(
                controller: city,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              TextField(
                controller: about,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'About me'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              ProfileUpdate(
                firstName: firstName.text.trim(),
                city: city.text.trim(),
                aboutMe: about.text.trim(),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    firstName.dispose();
    city.dispose();
    about.dispose();
    if (update != null) {
      await ref.read(profileControllerProvider.notifier).update(update);
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final avatar = profile.photos.where((photo) => photo.isAvatar).firstOrNull;
    final age = profile.age;
    return GlassSurface(
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundImage: avatar == null
                ? null
                : NetworkImage(_photoUrl(avatar.url)),
            child: avatar == null ? const Icon(Icons.person, size: 40) : null,
          ),
          const SizedBox(height: 10),
          Text(
            [
              [
                profile.firstName,
                profile.lastName,
              ].where((part) => part.isNotEmpty).join(' '),
              if (age != null) '$age',
            ].where((part) => part.isNotEmpty).join(', '),
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(profile.city.isEmpty ? 'City not specified' : profile.city),
          const SizedBox(height: 6),
          Text(
            profile.aboutMe.isEmpty ? 'No description yet' : profile.aboutMe,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              PillTag(
                label: profile.status.isEmpty ? 'offline' : profile.status,
              ),
              PillTag(
                label: profile.isSubscription ? 'Premium' : 'Free plan',
                color: AppTokens.pinkSoft,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.profile,
    required this.uploadProgress,
    required this.onAdd,
    required this.onSetAvatar,
  });

  final UserProfile profile;
  final double? uploadProgress;
  final VoidCallback onAdd;
  final ValueChanged<int> onSetAvatar;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Photos')),
              TextButton.icon(
                onPressed: uploadProgress == null ? onAdd : null,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add'),
              ),
            ],
          ),
          if (uploadProgress != null)
            LinearProgressIndicator(value: uploadProgress),
          if (profile.photos.isEmpty)
            const Text('No photos yet')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.photos
                  .map(
                    (photo) => GestureDetector(
                      onTap: photo.isAvatar
                          ? null
                          : () => onSetAvatar(photo.id),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _photoUrl(photo.url),
                              width: 86,
                              height: 86,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                width: 86,
                                height: 86,
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                          if (photo.isAvatar)
                            const Positioned(
                              right: 4,
                              top: 4,
                              child: Icon(Icons.star, color: Colors.amber),
                            ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _InterestSection extends StatelessWidget {
  const _InterestSection({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Interests'),
          const SizedBox(height: 8),
          if (profile.interests.isEmpty)
            const Text('No interests selected')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.interests
                  .map((interest) => PillTag(label: interest.label))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _InlineError(error: error),
      TextButton(onPressed: onRetry, child: const Text('Try again')),
    ],
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) => Text(
    error is ApiException
        ? (error! as ApiException).message
        : error is InvalidProfilePhotoException
        ? (error! as InvalidProfilePhotoException).message
        : 'Could not update the profile. Please try again.',
    style: TextStyle(color: Theme.of(context).colorScheme.error),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Text('Profile data is empty'),
      TextButton(onPressed: onRetry, child: const Text('Reload')),
    ],
  );
}

String _photoUrl(String value) {
  final uri = Uri.parse(value);
  return uri.hasScheme
      ? uri.toString()
      : Uri.parse(AppConfig.baseAppUrl).resolve(value).toString();
}
