import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/subscription/application/subscription_providers.dart';
import 'package:swipe_mobile_re/features/subscription/domain/subscription_models.dart';
import 'package:swipe_mobile_re/features/subscription/domain/subscription_repository.dart';

void main() {
  test('loads empty and error states', () async {
    final empty = scope(FakeRepository(plans: const []));
    await empty.read(subscriptionControllerProvider.notifier).load();
    expect(
      empty.read(subscriptionControllerProvider).status,
      SubscriptionStatus.empty,
    );
    empty.dispose();
    final failed = scope(FakeRepository(error: Exception('offline')));
    await failed.read(subscriptionControllerProvider.notifier).load();
    expect(
      failed.read(subscriptionControllerProvider).status,
      SubscriptionStatus.error,
    );
    failed.dispose();
  });

  test(
    'prevents double checkout and confirms only from backend status',
    () async {
      final repository = FakeRepository(paymentStatus: PaymentStatus.succeeded);
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
      await controller.createCheckout();
      await controller.createCheckout();
      expect(repository.checkoutCalls, 1);
      expect(launcher.urls.single.host, 'pay.test');
      expect(
        container.read(subscriptionControllerProvider).status,
        SubscriptionStatus.awaitingPayment,
      );
      await controller.checkPaymentStatus();
      expect(
        container.read(subscriptionControllerProvider).status,
        SubscriptionStatus.confirmed,
      );
      expect(refreshes, 1);
    },
  );

  test('maps failure, cancellation and timeout', () async {
    for (final entry in {
      PaymentStatus.failed: SubscriptionStatus.failed,
      PaymentStatus.canceled: SubscriptionStatus.cancelled,
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
        container.read(subscriptionControllerProvider).status,
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
      timeout.read(subscriptionControllerProvider).status,
      SubscriptionStatus.timedOut,
    );
    timeout.dispose();
  });

  test('cancel preserves paid end date', () async {
    final repository = FakeRepository(activeValue: active(renewable: true));
    final container = scope(repository);
    addTearDown(container.dispose);
    await container.read(subscriptionControllerProvider.notifier).load();
    final before = container
        .read(subscriptionControllerProvider)
        .activeSubscription!
        .endAt;
    await container
        .read(subscriptionControllerProvider.notifier)
        .cancelRenewal();
    final after = container
        .read(subscriptionControllerProvider)
        .activeSubscription!;
    expect(after.renewable, isFalse);
    expect(after.endAt, before);
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
  final urls = <Uri>[];
  @override
  Future<bool> open(Uri url) async {
    urls.add(url);
    return true;
  }
}

class FakeRepository implements SubscriptionRepository {
  FakeRepository({
    this.plans = const [
      SubscriptionPlan(
        id: 1,
        name: 'Premium',
        priceMinor: 49900,
        currency: 'RUB',
        durationDays: 30,
        isActive: true,
        renewable: false,
      ),
    ],
    this.activeValue,
    this.paymentStatus = PaymentStatus.pending,
    this.error,
  });
  final List<SubscriptionPlan> plans;
  ActiveSubscription? activeValue;
  final PaymentStatus paymentStatus;
  final Object? error;
  int checkoutCalls = 0;
  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    if (error != null) throw error!;
    return plans;
  }

  @override
  Future<ActiveSubscription?> getActiveSubscription() async => activeValue;
  @override
  Future<CheckoutResponse> createCheckout(
    int subscriptionId,
    String idempotencyKey,
  ) async {
    checkoutCalls++;
    return CheckoutResponse(
      orderId: 'order-1',
      paymentUrl: Uri.parse('https://pay.test/1'),
      status: PaymentStatus.pending,
      amountMinor: 49900,
      currency: 'RUB',
    );
  }

  @override
  Future<PaymentStatusResponse> getPaymentStatus(String orderId) async {
    final ok = paymentStatus == PaymentStatus.succeeded;
    if (ok) activeValue ??= active();
    return PaymentStatusResponse(
      orderId: orderId,
      status: paymentStatus,
      subscriptionActivated: ok,
      subscription: ok ? activeValue : null,
      updatedAt: DateTime.utc(2026, 7, 13),
    );
  }

  @override
  Future<ActiveSubscription> cancelRenewal() async {
    activeValue = ActiveSubscription(
      subscriptionId: activeValue!.subscriptionId,
      name: activeValue!.name,
      startAt: activeValue!.startAt,
      endAt: activeValue!.endAt,
      renewable: false,
    );
    return activeValue!;
  }

  @override
  Future<PaymentStatusResponse> setDemoPaymentResult(
    String orderId, {
    required bool success,
  }) => getPaymentStatus(orderId);
}

ActiveSubscription active({bool renewable = false}) => ActiveSubscription(
  subscriptionId: 1,
  name: 'Premium',
  startAt: DateTime.utc(2026, 7, 13),
  endAt: DateTime.utc(2026, 8, 12),
  renewable: renewable,
);
