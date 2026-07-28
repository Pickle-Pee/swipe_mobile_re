import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/config/config.dart';
import 'application/subscription_providers.dart';
import 'presentation/subscription_components.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(ref.read(subscriptionControllerProvider.notifier).load);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final subscription = ref.read(subscriptionControllerProvider);
    if (subscription.canVerify) {
      unawaited(
        ref.read(subscriptionControllerProvider.notifier).checkPaymentStatus(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionControllerProvider);
    final access = ref.watch(subscriptionAccessControllerProvider);
    final controller = ref.read(subscriptionControllerProvider.notifier);
    return SubscriptionView(
      state: state,
      access: access,
      isDemoMode: AppConfig.isDemoMode,
      onBack: _back,
      onRefresh: controller.load,
      onRetry: () => unawaited(controller.load()),
      onSelectPlan: controller.selectPlan,
      onCreateCheckout: () => unawaited(controller.createCheckout()),
      onReopenPayment: () => unawaited(controller.reopenPayment()),
      onVerifyPayment: () => unawaited(controller.checkPaymentStatus()),
      onDemoResult: (success) =>
          unawaited(controller.completeDemo(success: success)),
      onOpenLikes: () => context.go(Routes.likes),
    );
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.likes);
    }
  }
}
