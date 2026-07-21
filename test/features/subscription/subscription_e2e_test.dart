import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/subscription/application/subscription_providers.dart';
import 'package:swipe_mobile_re/features/subscription/domain/subscription_models.dart';
import 'package:swipe_mobile_re/features/subscription/domain/subscription_repository.dart';
import 'package:swipe_mobile_re/features/subscription/subscription_screen.dart';

void main() {
  testWidgets('complete checkout, confirmation and cancel renewal flow', (
    tester,
  ) async {
    final repository = E2eSubscriptionRepository();
    final launcher = RecordingLauncher();
    var profileRefreshes = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(repository),
          paymentUrlLauncherProvider.overrideWithValue(launcher),
          subscriptionProfileRefreshProvider.overrideWithValue(
            () async => profileRefreshes++,
          ),
          subscriptionPollConfigProvider.overrideWithValue(
            const SubscriptionPollConfig(maxAttempts: 0),
          ),
        ],
        child: const MaterialApp(home: SubscriptionScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('E2E Premium'), findsOneWidget);
    final continueButton = find.text('Continue');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump(const Duration(milliseconds: 10));

    expect(repository.checkoutCalls, 1);
    expect(launcher.urls.single, Uri.parse('https://pay.test/e2e'));
    expect(find.text('Check payment'), findsOneWidget);

    repository.paymentStatus = PaymentStatus.succeeded;
    await tester.tap(find.text('Check payment'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Payment confirmed. Premium is active.'), findsOneWidget);
    expect(find.text('Active subscription'), findsOneWidget);
    expect(find.text('Until 12.08.2026'), findsOneWidget);
    expect(find.text('Auto-renewal is on'), findsOneWidget);
    expect(profileRefreshes, 1);

    final cancelButton = find.text('Turn off auto-renewal');
    await tester.ensureVisible(cancelButton);
    await tester.tap(cancelButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(TextButton, 'Turn off'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(repository.cancelCalls, 1);
    expect(find.text('Auto-renewal is off'), findsOneWidget);
    expect(find.text('Until 12.08.2026'), findsOneWidget);
  });
}

class RecordingLauncher implements PaymentUrlLauncher {
  final urls = <Uri>[];

  @override
  Future<bool> open(Uri url) async {
    urls.add(url);
    return true;
  }
}

class E2eSubscriptionRepository implements SubscriptionRepository {
  PaymentStatus paymentStatus = PaymentStatus.pending;
  int checkoutCalls = 0;
  int cancelCalls = 0;
  ActiveSubscription? activeSubscription;

  @override
  Future<List<SubscriptionPlan>> getPlans() async => const [
    SubscriptionPlan(
      id: 7,
      name: 'E2E Premium',
      priceMinor: 49900,
      currency: 'RUB',
      durationDays: 30,
      isActive: true,
      renewable: true,
    ),
  ];

  @override
  Future<ActiveSubscription?> getActiveSubscription() async =>
      activeSubscription;

  @override
  Future<CheckoutResponse> createCheckout(
    int subscriptionId,
    String idempotencyKey,
  ) async {
    checkoutCalls++;
    expect(subscriptionId, 7);
    expect(idempotencyKey, isNotEmpty);
    return CheckoutResponse(
      orderId: 'e2e-order',
      paymentUrl: Uri.parse('https://pay.test/e2e'),
      status: PaymentStatus.pending,
      amountMinor: 49900,
      currency: 'RUB',
    );
  }

  @override
  Future<PaymentStatusResponse> getPaymentStatus(String orderId) async {
    expect(orderId, 'e2e-order');
    if (paymentStatus == PaymentStatus.succeeded) {
      activeSubscription ??= ActiveSubscription(
        subscriptionId: 7,
        name: 'E2E Premium',
        startAt: DateTime.utc(2026, 7, 13),
        endAt: DateTime.utc(2026, 8, 12),
        renewable: true,
      );
    }
    return PaymentStatusResponse(
      orderId: orderId,
      status: paymentStatus,
      subscriptionActivated: paymentStatus == PaymentStatus.succeeded,
      subscription: activeSubscription,
      updatedAt: DateTime.utc(2026, 7, 13),
    );
  }

  @override
  Future<ActiveSubscription> cancelRenewal() async {
    cancelCalls++;
    final current = activeSubscription!;
    activeSubscription = ActiveSubscription(
      subscriptionId: current.subscriptionId,
      name: current.name,
      startAt: current.startAt,
      endAt: current.endAt,
      renewable: false,
    );
    return activeSubscription!;
  }

  @override
  Future<PaymentStatusResponse> setDemoPaymentResult(
    String orderId, {
    required bool success,
  }) => throw UnimplementedError();
}
