import 'package:flutter/material.dart';

import '../../../shared/media/app_network_image.dart';
import '../../../shared/theme/tokens.dart';
import '../../../shared/ui/discovery_components.dart';
import '../../../shared/ui/liquid_ui.dart';
import '../../../shared/ui/midnight_components.dart';
import '../application/profile_providers.dart';
import '../domain/profile_models.dart';
import 'own_profile_components.dart';

class EditProfileSection extends StatelessWidget {
  const EditProfileSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.space20),
      decoration: BoxDecoration(
        color: AppTokens.surfaceSolid,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(color: AppTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: AppTokens.iconStandard,
                  color: AppTokens.textSecondary,
                ),
                const SizedBox(width: AppTokens.space8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTokens.space8),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: AppTokens.space16),
          child,
        ],
      ),
    );
  }
}

class ProfileSaveBar extends StatelessWidget {
  const ProfileSaveBar({
    super.key,
    required this.dirty,
    required this.valid,
    required this.saving,
    required this.onSave,
    this.photoBusy = false,
  });

  final bool dirty;
  final bool valid;
  final bool saving;
  final VoidCallback? onSave;
  final bool photoBusy;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      key: const Key('profile-save-bar'),
      level: GlassLevel.overlay,
      radius: AppTokens.radiusXLarge,
      padding: const EdgeInsets.all(AppTokens.space8),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: AppTokens.space12),
              child: Text(
                saving
                    ? 'Saving changes…'
                    : photoBusy
                    ? 'Finish the photo update first'
                    : dirty
                    ? valid
                          ? 'Unsaved changes'
                          : 'Fix highlighted fields'
                    : 'Everything is saved',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space8),
          PrimaryActionButton(
            key: const Key('edit-profile-save'),
            label: 'Save',
            icon: Icons.check_rounded,
            loading: saving,
            expanded: false,
            onPressed: dirty && valid && !saving && !photoBusy ? onSave : null,
          ),
        ],
      ),
    );
  }
}

class EditableInterestChip extends StatelessWidget {
  const EditableInterestChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, ${selected ? 'selected' : 'not selected'}',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppTokens.minTouchTarget),
        child: FilterChip(
          showCheckmark: true,
          selected: selected,
          label: Text(label, overflow: TextOverflow.ellipsis),
          onSelected: onSelected,
          selectedColor: AppTokens.brandViolet.withValues(alpha: 0.28),
          backgroundColor: AppTokens.backgroundElevated,
          side: BorderSide(
            color: selected
                ? AppTokens.brandViolet.withValues(alpha: 0.64)
                : AppTokens.glassBorder,
          ),
        ),
      ),
    );
  }
}

class InterestSelector extends StatelessWidget {
  const InterestSelector({
    super.key,
    required this.interests,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<ProfileInterest> interests;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    if (interests.isEmpty) {
      return const Text('No interests are available right now.');
    }
    return Wrap(
      spacing: AppTokens.space8,
      runSpacing: AppTokens.space8,
      children: interests
          .map(
            (interest) => EditableInterestChip(
              key: ValueKey<String>('edit-interest-${interest.id}'),
              label: interest.label,
              selected: selectedIds.contains(interest.id),
              onSelected: (_) => onToggle(interest.id),
            ),
          )
          .toList(growable: false),
    );
  }
}

class ProfilePhotoManager extends StatelessWidget {
  const ProfilePhotoManager({
    super.key,
    required this.state,
    required this.onAdd,
    required this.onRetryUpload,
    required this.onDelete,
    required this.onSetPrimary,
    this.imageProviderBuilder = appNetworkImage,
  });

  final ProfileState state;
  final VoidCallback onAdd;
  final VoidCallback onRetryUpload;
  final ValueChanged<ProfilePhoto> onDelete;
  final ValueChanged<int> onSetPrimary;
  final OwnProfileImageProviderBuilder imageProviderBuilder;

  @override
  Widget build(BuildContext context) {
    final photos = state.profile?.photos ?? const <ProfilePhoto>[];
    final busy = state.isPhotoBusy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JPG, PNG, or WebP · up to 10 MB per image',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (state.photoOperation == ProfilePhotoOperation.uploading) ...[
          const SizedBox(height: AppTokens.space12),
          PhotoUploadProgress(progress: state.uploadProgress),
        ],
        if (state.photoError != null) ...[
          const SizedBox(height: AppTokens.space12),
          _PhotoError(
            message: profileErrorMessage(state.photoError),
            onRetry: state.canRetryPhotoUpload ? onRetryUpload : null,
          ),
        ],
        const SizedBox(height: AppTokens.space16),
        LayoutBuilder(
          key: const Key('profile-photo-manager'),
          builder: (context, constraints) {
            const spacing = AppTokens.space12;
            final tileWidth = (constraints.maxWidth - spacing) / 2;
            final tileHeight = tileWidth / 0.76;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: List<Widget>.generate(photos.length + 1, (index) {
                final Widget tile;
                if (index == photos.length) {
                  tile = AddPhotoTile(enabled: !busy, onTap: onAdd);
                } else {
                  final photo = photos[index];
                  tile = EditableProfilePhoto(
                    key: ValueKey<String>('editable-photo-${photo.id}'),
                    photo: photo,
                    imageProvider: imageProviderBuilder(photo.url),
                    busy: state.photoTargetId == photo.id && busy,
                    controlsEnabled: !busy,
                    onDelete: () => onDelete(photo),
                    onSetPrimary: photo.isAvatar
                        ? null
                        : () => onSetPrimary(photo.id),
                  );
                }
                return SizedBox(
                  width: tileWidth,
                  height: tileHeight,
                  child: tile,
                );
              }),
            );
          },
        ),
        const SizedBox(height: AppTokens.space12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: AppTokens.iconCompact,
              color: AppTokens.textMuted,
            ),
            const SizedBox(width: AppTokens.space8),
            Expanded(
              child: Text(
                'Photo order cannot be changed yet because the current '
                'server does not store a stable order.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class EditableProfilePhoto extends StatelessWidget {
  const EditableProfilePhoto({
    super.key,
    required this.photo,
    required this.imageProvider,
    required this.busy,
    required this.controlsEnabled,
    required this.onDelete,
    required this.onSetPrimary,
  });

  final ProfilePhoto photo;
  final ImageProvider<Object>? imageProvider;
  final bool busy;
  final bool controlsEnabled;
  final VoidCallback onDelete;
  final VoidCallback? onSetPrimary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: photo.isAvatar ? 'Primary profile photo' : 'Profile photo',
      child: Container(
        decoration: BoxDecoration(
          color: AppTokens.backgroundElevated,
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          border: Border.all(
            color: photo.isAvatar
                ? AppTokens.warning.withValues(alpha: 0.58)
                : AppTokens.glassBorder,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _EditablePhotoImage(imageProvider: imageProvider),
                  if (photo.isAvatar)
                    const Positioned(
                      left: AppTokens.space8,
                      top: AppTokens.space8,
                      child: _PrimaryBadge(),
                    ),
                  if (busy)
                    const ColoredBox(
                      color: AppTokens.scrim,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                if (!photo.isAvatar)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: controlsEnabled ? onSetPrimary : null,
                      icon: const Icon(Icons.star_outline_rounded, size: 18),
                      label: const Text('Primary'),
                    ),
                  )
                else
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Primary',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTokens.warning),
                      ),
                    ),
                  ),
                SizedBox.square(
                  dimension: AppTokens.minTouchTarget,
                  child: IconButton(
                    key: ValueKey<String>('delete-photo-${photo.id}'),
                    tooltip: 'Delete photo',
                    onPressed: controlsEnabled ? onDelete : null,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppTokens.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddPhotoTile extends StatelessWidget {
  const AddPhotoTile({super.key, required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.backgroundElevated,
      borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
      child: InkWell(
        key: const Key('add-profile-photo'),
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        onTap: enabled ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
            border: Border.all(color: AppTokens.glassBorder),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 34),
              SizedBox(height: AppTokens.space8),
              Text('Add photo'),
            ],
          ),
        ),
      ),
    );
  }
}

class PhotoUploadProgress extends StatelessWidget {
  const PhotoUploadProgress({super.key, required this.progress});
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final value = progress;
    return Semantics(
      liveRegion: true,
      label: value == null
          ? 'Uploading photo'
          : 'Uploading photo ${(value * 100).round()} percent',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value == null
                ? 'Uploading photo…'
                : 'Uploading photo · ${(value * 100).round()}%',
          ),
          const SizedBox(height: AppTokens.space8),
          LinearProgressIndicator(value: value),
        ],
      ),
    );
  }
}

enum UnsavedChangesChoice { save, discard, keepEditing }

class UnsavedChangesDialog extends StatelessWidget {
  const UnsavedChangesDialog({
    super.key,
    required this.canSave,
    required this.saving,
  });

  final bool canSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('unsaved-profile-dialog'),
      backgroundColor: AppTokens.surfaceSolid,
      title: const Text('Save your changes?'),
      content: const Text(
        'Your profile draft has changes that have not been saved yet.',
      ),
      actions: [
        TextButton(
          key: const Key('keep-editing-profile'),
          onPressed: saving
              ? null
              : () => Navigator.pop(context, UnsavedChangesChoice.keepEditing),
          child: const Text('Keep editing'),
        ),
        TextButton(
          key: const Key('discard-profile-changes'),
          onPressed: saving
              ? null
              : () => Navigator.pop(context, UnsavedChangesChoice.discard),
          child: const Text('Discard'),
        ),
        FilledButton(
          key: const Key('save-profile-changes-dialog'),
          onPressed: canSave && !saving
              ? () => Navigator.pop(context, UnsavedChangesChoice.save)
              : null,
          child: const Text('Save changes'),
        ),
      ],
    );
  }
}

class _PrimaryBadge extends StatelessWidget {
  const _PrimaryBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space8,
        vertical: AppTokens.space4,
      ),
      decoration: BoxDecoration(
        color: AppTokens.scrim,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: AppTokens.warning),
          SizedBox(width: AppTokens.space4),
          Text('Primary', style: TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _EditablePhotoImage extends StatelessWidget {
  const _EditablePhotoImage({required this.imageProvider});
  final ImageProvider<Object>? imageProvider;

  @override
  Widget build(BuildContext context) {
    final provider = imageProvider;
    if (provider == null) return const ProfileMediaPlaceholder();
    final decodeWidth = (180 * MediaQuery.devicePixelRatioOf(context))
        .ceil()
        .clamp(1, 1024)
        .toInt();
    return Image(
      image: ResizeImage.resizeIfNeeded(decodeWidth, null, provider),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ProfileMediaPlaceholder(),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return const SkeletonLoader(radius: 0);
      },
    );
  }
}

class _PhotoError extends StatelessWidget {
  const _PhotoError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('profile-photo-error'),
        padding: const EdgeInsets.all(AppTokens.space12),
        decoration: BoxDecoration(
          color: AppTokens.backgroundElevated,
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          border: Border.all(color: AppTokens.error.withValues(alpha: 0.52)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTokens.error),
            const SizedBox(width: AppTokens.space8),
            Expanded(child: Text(message)),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
