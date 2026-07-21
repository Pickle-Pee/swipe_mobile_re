import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/subscription/application/subscription_providers.dart';
import 'package:swipe_mobile_re/features/subscription/domain/subscription_models.dart';
import 'package:swipe_mobile_re/features/subscription/domain/subscription_repository.dart';
import 'package:swipe_mobile_re/features/subscription/subscription_screen.dart';

void main() {
  testWidgets('renders backend plan and prevents double checkout', (
    tester,
  ) async {
    final repository = ScreenRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(repository),
          paymentUrlLauncherProvider.overrideWithValue(ScreenLauncher()),
          subscriptionPollConfigProvider.overrideWithValue(
            const SubscriptionPollConfig(
              interval: Duration.zero,
              maxAttempts: 1,
            ),
          ),
        ],
        child: const MaterialApp(home: SubscriptionScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Server Premium'), findsOneWidget);
    expect(find.text('499.00 ₽'), findsOneWidget);
    final continueButton = find.text('Continue');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.tap(continueButton);
    await tester.pump(const Duration(milliseconds: 10));
    expect(repository.checkoutCalls, 1);
    expect(find.text('Check payment'), findsOneWidget);
  });
}

class ScreenLauncher implements PaymentUrlLauncher {
  @override
  Future<bool> open(Uri url) async => true;
}

class ScreenRepository implements SubscriptionRepository {
  int checkoutCalls = 0;
  @override
  Future<List<SubscriptionPlan>> getPlans() async => const [
    SubscriptionPlan(
      id: 1,
      name: 'Server Premium',
      priceMinor: 49900,
      currency: 'RUB',
      durationDays: 30,
      isActive: true,
      renewable: false,
    ),
  ];
  @override
  Future<ActiveSubscription?> getActiveSubscription() async => null;
  @override
  Future<CheckoutResponse> createCheckout(
    int subscriptionId,
    String idempotencyKey,
  ) async {
    checkoutCalls++;
    return CheckoutResponse(
      orderId: 'order-1',
      paymentUrl: Uri.parse('https://pay.test'),
      status: PaymentStatus.pending,
      amountMinor: 49900,
      currency: 'RUB',
    );
  }

  @override
  Future<PaymentStatusResponse> getPaymentStatus(String orderId) async =>
      PaymentStatusResponse(
        orderId: orderId,
        status: PaymentStatus.pending,
        subscriptionActivated: false,
        updatedAt: DateTime.utc(2026, 7, 13),
      );
  @override
  Future<ActiveSubscription> cancelRenewal() => throw UnimplementedError();
  @override
  Future<PaymentStatusResponse> setDemoPaymentResult(
    String orderId, {
    required bool success,
  }) => getPaymentStatus(orderId);
}
