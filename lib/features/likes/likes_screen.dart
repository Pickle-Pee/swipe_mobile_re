import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../discovery/domain/discovery_models.dart';
import '../subscription/application/subscription_providers.dart';
import 'application/likes_providers.dart';
import 'domain/likes_models.dart';
import 'presentation/likes_components.dart';

class LikesScreen extends ConsumerStatefulWidget {
  const LikesScreen({super.key});

  @override
  ConsumerState<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends ConsumerState<LikesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_ensureLoaded);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(likesControllerProvider);
    final access = ref.watch(subscriptionAccessControllerProvider);
    return LikesView(
      state: state,
      access: access,
      onBack: () => context.go(Routes.discover),
      onRetry: () => unawaited(_refresh()),
      onRefresh: _refresh,
      onSelectCategory: ref.read(likesControllerProvider.notifier).select,
      onOpenSubscription: () => unawaited(context.push(Routes.premium)),
      onOpenDiscovery: () => context.go(Routes.discover),
      onOpenProfile: _openProfile,
    );
  }

  Future<void> _ensureLoaded() async {
    final tasks = <Future<void>>[];
    if (ref.read(likesControllerProvider).status == LikesStatus.initial) {
      tasks.add(ref.read(likesControllerProvider.notifier).load());
    }
    tasks.add(
      ref.read(subscriptionAccessControllerProvider.notifier).ensureLoaded(),
    );
    await Future.wait(tasks);
  }

  Future<void> _refresh() => Future.wait([
    ref.read(likesControllerProvider.notifier).load(),
    ref.read(subscriptionAccessControllerProvider.notifier).refresh(),
  ]);

  void _openProfile(LikesUser user) {
    unawaited(
      context.push(
        Routes.publicProfileFromLikesFor(user.id),
        extra: _profileSeed(user),
      ),
    );
  }
}

DiscoveryProfile _profileSeed(LikesUser user) => DiscoveryProfile(
  id: user.id,
  firstName: user.firstName,
  dateOfBirth: user.dateOfBirth,
  city: user.city,
  aboutMe: user.aboutMe,
  photoUrl: user.avatarUrl,
  interests: const [],
  attributes: const {},
);
