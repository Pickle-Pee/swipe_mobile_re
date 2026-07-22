import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../subscription/application/subscription_providers.dart';
import 'application/profile_providers.dart';
import 'domain/profile_models.dart';
import 'presentation/own_profile_components.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_ensureLoaded);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider);
    final access = ref.watch(subscriptionAccessControllerProvider);
    final premium = switch (access.status) {
      SubscriptionAccessStatus.active => true,
      SubscriptionAccessStatus.inactive => false,
      _ => null,
    };
    return OwnProfileView(
      state: profile,
      hasPremiumAccess: premium,
      subscriptionLoading:
          access.status == SubscriptionAccessStatus.initial ||
          access.status == SubscriptionAccessStatus.loading ||
          access.isRefreshing,
      onRefresh: _refresh,
      onRetry: () =>
          unawaited(ref.read(profileControllerProvider.notifier).load()),
      onEdit: () => _openEdit(),
      onPreview: () => context.push(Routes.profilePreview),
      onSettings: () => context.push(Routes.settings),
      onSubscription: () => context.push(Routes.premium),
      onEditStep: (step) => _openEdit(_sectionFor(step)),
    );
  }

  void _ensureLoaded() {
    final profile = ref.read(profileControllerProvider);
    if (profile.status == ProfileStatus.initial) {
      unawaited(ref.read(profileControllerProvider.notifier).load());
    }
    unawaited(
      ref.read(subscriptionAccessControllerProvider.notifier).ensureLoaded(),
    );
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(profileControllerProvider.notifier).load(),
      ref.read(subscriptionAccessControllerProvider.notifier).refresh(),
    ]);
  }

  void _openEdit([ProfileEditSection? section]) {
    context.push(Routes.editProfile, extra: section);
  }

  ProfileEditSection _sectionFor(ProfileCompletionStep step) => switch (step) {
    ProfileCompletionStep.primaryPhoto => ProfileEditSection.photos,
    ProfileCompletionStep.about => ProfileEditSection.about,
    ProfileCompletionStep.interests => ProfileEditSection.interests,
    ProfileCompletionStep.city => ProfileEditSection.basic,
    ProfileCompletionStep.lookingFor => ProfileEditSection.attributes,
  };
}
