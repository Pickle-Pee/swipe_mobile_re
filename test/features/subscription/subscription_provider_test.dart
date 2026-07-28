import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/subscription/application/subscription_providers.dart';
import 'package:swipe_mobile_re/features/subscription/domain/subscription_models.dart';
import 'package:swipe_mobile_re/features/subscription/domain/subscription_repository.dart';

void main() {
  test('loads plans and access as separate state axes', () async {
    final repository = FakeRepository();
    final container = scope(repository);
    addTearDown(container.dispose);

    await container.read(subscriptionControllerProvider.notifier).load();

    final plans = container.read(subscriptionControllerProvider);
    final access = container.read(subscriptionAccessControllerProvider);
    expect(plans.plansStatus, SubscriptionPlansStatus.data);
    expect(plans.checkoutStatus, CheckoutStatus.idle);
    expect(plans.selectedPlanId, 1);
    expect(access.status, SubscriptionAccessStatus.inactive);
  });

  test('loads empty and plans error without fake fallback plans', () async {
    final empty = scope(FakeRepository(plans: const []));
    await empty.read(subscriptionControllerProvider.notifier).load();
    expect(
      empty.read(subscriptionControllerProvider).plansStatus,
      SubscriptionPlansStatus.empty,
    );
    expect(empty.read(subscriptionControllerProvider).plans, isEmpty);
    empty.dispose();

    final failed = scope(FakeRepository(plansError: Exception('offline')));
    await failed.read(subscriptionControllerProvider.notifier).load();
    expect(
      failed.read(subscriptionControllerProvider).plansStatus,
      SubscriptionPlansStatus.error,
    );
    expect(failed.read(subscriptionControllerProvider).plans, isEmpty);
    failed.dispose();
  });

  test('selects only a real active plan and preserves it on refresh', () async {
    final repository = FakeRepository(
      plans: const [
        plan,
        SubscriptionPlan(
          id: 2,
          name: 'Unavailable',
          priceMinor: 99900,
          currency: 'RUB',
          durationDays: 90,
          isActive: false,
          renewable: false,
        ),
        SubscriptionPlan(
          id: 3,
          name: 'Premium 60',
          priceMinor: 79900,
          currency: 'RUB',
          durationDays: 60,
          isActive: true,
          renewable: false,
        ),
      ],
    );
    final container = scope(repository);
    addTearDown(container.dispose);
    final controller = container.read(subscriptionControllerProvider.notifier);
    await controller.load();

    controller.selectPlan(2);
    expect(container.read(subscriptionControllerProvider).selectedPlanId, 1);
    controller.selectPlan(3);
    expect(container.read(subscriptionControllerProvider).selectedPlanId, 3);
    await controller.loadPlans();
    expect(container.read(subscriptionControllerProvider).selectedPlanId, 3);
  });

  test(
    'prevents double checkout and confirms only from backend status',
    () async {
      final checkoutCompleter = Completer<CheckoutResponse>();
      final repository = FakeRepository(
        checkoutCompleter: checkoutCompleter,
        paymentStatus: PaymentStatus.succeeded,
      );
      final launcher = FakeLauncher();
      var refreshes = 0;
      final container = scope(
        repository,
        launcher: launcher,
        refresh: () async => refreshes++,
      );
      addTearDown(container.dispose);
      final controller = container.read(
        subscriptionControllerProvider.notifier,
      );
      await controller.load();

      final first = controller.createCheckout();
      final second = controller.createCheckout();
      expect(repository.checkoutCalls, 1);
      checkoutCompleter.complete(checkout);
      await Future.wait([first, second]);

      expect(launcher.urls.single.host, 'pay.test');
      expect(
        container.read(subscriptionControllerProvider).checkoutStatus,
        CheckoutStatus.awaitingPayment,
      );
      expect(
        container.read(subscriptionAccessControllerProvider).hasPremiumAccess,
        isFalse,
      );

      await controller.checkPaymentStatus();
      expect(
        container.read(subscriptionControllerProvider).checkoutStatus,
        CheckoutStatus.confirmed,
      );
      expect(
        container.read(subscriptionAccessControllerProvider).hasPremiumAccess,
        isTrue,
      );
      expect(refreshes, 1);
    },
  );

  test('payment success without backend activation stays locked', () async {
    final repository = FakeRepository(
      paymentStatus: PaymentStatus.succeeded,
      activateOnSuccess: false,
    );
    final container = scope(repository);
    addTearDown(container.dispose);
    final controller = container.read(subscriptionControllerProvider.notifier);
    await controller.load();
    await controller.createCheckout();
    await controller.checkPaymentStatus();

    expect(
      container.read(subscriptionControllerProvider).checkoutStatus,
      CheckoutStatus.verificationError,
    );
    expect(
      container.read(subscriptionAccessControllerProvider).hasPremiumAccess,
      isFalse,
    );
  });

  test('maps payment failure, cancellation and timeout', () async {
    for (final entry in {
      PaymentStatus.failed: CheckoutStatus.failed,
      PaymentStatus.canceled: CheckoutStatus.cancelled,
    }.entries) {
      final container = scope(FakeRepository(paymentStatus: entry.key));
      await container.read(subscriptionControllerProvider.notifier).load();
      await container
          .read(subscriptionControllerProvider.notifier)
          .createCheckout();
      await container
          .read(subscriptionControllerProvider.notifier)
          .checkPaymentStatus();
      expect(
        container.read(subscriptionControllerProvider).checkoutStatus,
        entry.value,
      );
      container.dispose();
    }

    final timeout = scope(
      FakeRepository(),
      config: const SubscriptionPollConfig(
        interval: Duration.zero,
        maxAttempts: 1,
      ),
    );
    await timeout.read(subscriptionControllerProvider.notifier).load();
    await timeout
        .read(subscriptionControllerProvider.notifier)
        .createCheckout();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(
      timeout.read(subscriptionControllerProvider).checkoutStatus,
      CheckoutStatus.timedOut,
    );
    timeout.dispose();
  });

  test('launch retry reopens one checkout without another API call', () async {
    final launcher = FakeLauncher(result: false);
    final repository = FakeRepository();
    final container = scope(repository, launcher: launcher);
    addTearDown(container.dispose);
    final controller = container.read(subscriptionControllerProvider.notifier);
    await controller.load();
    await controller.createCheckout();

    expect(
      container.read(subscriptionControllerProvider).checkoutStatus,
      CheckoutStatus.launchError,
    );
    expect(repository.checkoutCalls, 1);

    launcher.result = true;
    await controller.reopenPayment();
    expect(
      container.read(subscriptionControllerProvider).checkoutStatus,
      CheckoutStatus.awaitingPayment,
    );
    expect(repository.checkoutCalls, 1);
    expect(launcher.urls, hasLength(2));
  });

  test('verification error can retry with selected plan preserved', () async {
    final repository = FakeRepository(statusError: Exception('offline'));
    final container = scope(repository);
    addTearDown(container.dispose);
    final controller = container.read(subscriptionControllerProvider.notifier);
    await controller.load();
    await controller.createCheckout();
    await controller.checkPaymentStatus();

    expect(
      container.read(subscriptionControllerProvider).checkoutStatus,
      CheckoutStatus.verificationError,
    );
    expect(container.read(subscriptionControllerProvider).selectedPlanId, 1);

    repository.statusError = null;
    repository.paymentStatus = PaymentStatus.pending;
    await controller.checkPaymentStatus();
    expect(
      container.read(subscriptionControllerProvider).checkoutStatus,
      CheckoutStatus.pending,
    );
    expect(container.read(subscriptionControllerProvider).selectedPlanId, 1);
  });
}

ProviderContainer scope(
  FakeRepository repository, {
  FakeLauncher? launcher,
  SubscriptionPollConfig config = const SubscriptionPollConfig(
    interval: Duration(days: 1),
    maxAttempts: 1,
  ),
  Future<void> Function()? refresh,
}) => ProviderContainer(
  overrides: [
    subscriptionRepositoryProvider.overrideWithValue(repository),
    paymentUrlLauncherProvider.overrideWithValue(launcher ?? FakeLauncher()),
    subscriptionPollConfigProvider.overrideWithValue(config),
    subscriptionProfileRefreshProvider.overrideWithValue(
      refresh ?? () async {},
    ),
  ],
);

class FakeLauncher implements PaymentUrlLauncher {
  FakeLauncher({this.result = true});

  bool result;
  final urls = <Uri>[];

  @override
  Future<bool> open(Uri url) async {
    urls.add(url);
    return result;
  }
}

class FakeRepository implements SubscriptionRepository {
  FakeRepository({
    this.plans = const [plan],
    this.activeValue,
    this.paymentStatus = PaymentStatus.pending,
    this.plansError,
    this.accessError,
    this.statusError,
    this.checkoutCompleter,
    this.activateOnSuccess = true,
  });

  final List<SubscriptionPlan> plans;
  ActiveSubscription? activeValue;
  PaymentStatus paymentStatus;
  final Object? plansError;
  final Object? accessError;
  Object? statusError;
  final Completer<CheckoutResponse>? checkoutCompleter;
  final bool activateOnSuccess;
  int checkoutCalls = 0;

  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    if (plansError != null) throw plansError!;
    return plans;
  }

  @override
  Future<ActiveSubscription?> getActiveSubscription() async {
    if (accessError != null) throw accessError!;
    return activeValue;
  }

  @override
  Future<CheckoutResponse> createCheckout(
    int subscriptionId,
    String idempotencyKey,
  ) async {
    checkoutCalls++;
    return checkoutCompleter?.future ?? checkout;
  }

  @override
  Future<PaymentStatusResponse> getPaymentStatus(String orderId) async {
    if (statusError != null) throw statusError!;
    final succeeded = paymentStatus == PaymentStatus.succeeded;
    if (succeeded && activateOnSuccess) activeValue ??= active;
    return PaymentStatusResponse(
      orderId: orderId,
      status: paymentStatus,
      subscriptionActivated: succeeded && activateOnSuccess,
      subscription: succeeded && activateOnSuccess ? activeValue : null,
      updatedAt: DateTime.utc(2026, 7, 13),
    );
  }

  @override
  Future<ActiveSubscription> cancelRenewal() => throw UnimplementedError();

  @override
  Future<PaymentStatusResponse> setDemoPaymentResult(
    String orderId, {
    required bool success,
  }) => getPaymentStatus(orderId);
}

const plan = SubscriptionPlan(
  id: 1,
  name: 'Premium',
  priceMinor: 49900,
  currency: 'RUB',
  durationDays: 30,
  isActive: true,
  renewable: false,
);

final checkout = CheckoutResponse(
  orderId: 'order-1',
  paymentUrl: Uri.parse('https://pay.test/1'),
  status: PaymentStatus.pending,
  amountMinor: 49900,
  currency: 'RUB',
);

final active = ActiveSubscription(
  subscriptionId: 1,
  name: 'Premium',
  startAt: DateTime.utc(2026, 7, 13),
  endAt: DateTime.utc(2026, 8, 12),
  renewable: false,
);
