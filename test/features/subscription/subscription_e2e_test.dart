import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/subscription/application/subscription_providers.dart';
import 'package:swipe_mobile_re/features/subscription/domain/subscription_models.dart';
import 'package:swipe_mobile_re/features/subscription/domain/subscription_repository.dart';
import 'package:swipe_mobile_re/features/subscription/subscription_screen.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  testWidgets('checkout stays locked until backend activates Premium', (
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
        child: MaterialApp(
          theme: AppTheme.midnight(),
          home: const SubscriptionScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('E2E Premium'), findsOneWidget);
    final continueButton = find.text('Continue to payment');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(repository.checkoutCalls, 1);
    expect(launcher.urls.single, Uri.parse('https://pay.test/e2e'));
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -360));
    await tester.pumpAndSettle();
    expect(find.text('Check payment'), findsOneWidget);
    expect(find.text('Premium is active'), findsNothing);

    repository.paymentStatus = PaymentStatus.succeeded;
    await tester.tap(find.text('Check payment'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Premium is active'), findsOneWidget);
    expect(find.text('E2E Premium'), findsOneWidget);
    expect(find.text('Access until 12.08.2026'), findsOneWidget);
    expect(find.textContaining('Auto-renewal'), findsNothing);
    expect(find.textContaining('Turn off'), findsNothing);
    expect(profileRefreshes, 1);
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
        endAt: DateTime.utc(2026, 8, 12, 12),
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
  Future<ActiveSubscription> cancelRenewal() => throw UnimplementedError();

  @override
  Future<PaymentStatusResponse> setDemoPaymentResult(
    String orderId, {
    required bool success,
  }) => throw UnimplementedError();
}
