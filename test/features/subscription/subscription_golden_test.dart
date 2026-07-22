import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/subscription/application/subscription_providers.dart';
import 'package:swipe_mobile_re/features/subscription/domain/subscription_models.dart';
import 'package:swipe_mobile_re/features/subscription/presentation/subscription_components.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  const size = Size(390, 844);

  setUpAll(() async {
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
  });

  testWidgets('Subscription plans golden', (tester) async {
    await pumpSubscriptionGolden(tester, plansState, size: size);
    await expectSubscriptionGolden(tester, 'goldens/subscription_plans.png');
  });

  testWidgets('Subscription selected plan golden', (tester) async {
    await pumpSubscriptionGolden(
      tester,
      plansState.copyWith(selectedPlanId: 2),
      size: size,
    );
    await expectSubscriptionGolden(
      tester,
      'goldens/subscription_selected_plan.png',
    );
  });

  testWidgets('Subscription loading golden', (tester) async {
    await pumpSubscriptionGolden(
      tester,
      const SubscriptionState(plansStatus: SubscriptionPlansStatus.loading),
      access: const SubscriptionAccessState(
        status: SubscriptionAccessStatus.loading,
      ),
      size: size,
    );
    await expectSubscriptionGolden(tester, 'goldens/subscription_loading.png');
  });

  testWidgets('Subscription checkout error golden', (tester) async {
    await pumpSubscriptionGolden(
      tester,
      plansState.copyWith(
        checkoutStatus: CheckoutStatus.creationError,
        checkoutError: Exception('offline'),
      ),
      size: size,
      revealStatus: true,
    );
    await expectSubscriptionGolden(
      tester,
      'goldens/subscription_checkout_error.png',
    );
  });

  testWidgets('Subscription verifying golden', (tester) async {
    await pumpSubscriptionGolden(
      tester,
      plansState.copyWith(
        checkoutStatus: CheckoutStatus.verifying,
        checkout: checkout,
      ),
      size: size,
      revealStatus: true,
    );
    await expectSubscriptionGolden(
      tester,
      'goldens/subscription_verifying.png',
    );
  });

  testWidgets('Subscription pending golden', (tester) async {
    await pumpSubscriptionGolden(
      tester,
      plansState.copyWith(
        checkoutStatus: CheckoutStatus.pending,
        checkout: checkout,
        payment: pendingPayment,
      ),
      size: size,
      revealStatus: true,
    );
    await expectSubscriptionGolden(tester, 'goldens/subscription_pending.png');
  });

  testWidgets('Subscription active golden', (tester) async {
    await pumpSubscriptionGolden(
      tester,
      plansState,
      access: activeAccess,
      size: size,
    );
    await expectSubscriptionGolden(tester, 'goldens/subscription_active.png');
  });

  testWidgets('Subscription verification error golden', (tester) async {
    await pumpSubscriptionGolden(
      tester,
      plansState.copyWith(
        checkoutStatus: CheckoutStatus.verificationError,
        checkout: checkout,
        checkoutError: Exception('offline'),
      ),
      size: size,
      revealStatus: true,
    );
    await expectSubscriptionGolden(
      tester,
      'goldens/subscription_verification_error.png',
    );
  });
}

Future<void> pumpSubscriptionGolden(
  WidgetTester tester,
  SubscriptionState state, {
  required Size size,
  SubscriptionAccessState access = inactiveAccess,
  bool revealStatus = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.midnight(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          devicePixelRatio: 1,
          disableAnimations: true,
        ),
        child: TickerMode(
          enabled: false,
          child: RepaintBoundary(
            key: const Key('subscription-golden-surface'),
            child: SubscriptionView(
              state: state,
              access: access,
              isDemoMode: false,
              onBack: () {},
              onRefresh: () async {},
              onRetry: () {},
              onSelectPlan: (_) {},
              onCreateCheckout: () {},
              onReopenPayment: () {},
              onVerifyPayment: () {},
              onDemoResult: (_) {},
              onOpenLikes: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (revealStatus) {
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -460));
    await tester.pumpAndSettle();
  }
}

Future<void> expectSubscriptionGolden(WidgetTester tester, String path) =>
    expectLater(
      find.byKey(const Key('subscription-golden-surface')),
      matchesGoldenFile(path),
    );

const plansState = SubscriptionState(
  plansStatus: SubscriptionPlansStatus.data,
  plans: plans,
  selectedPlanId: 1,
);

const plans = [
  SubscriptionPlan(
    id: 1,
    name: 'Premium 30',
    description: 'Unlock your real incoming Likes',
    priceMinor: 49900,
    currency: 'RUB',
    durationDays: 30,
    isActive: true,
    renewable: false,
  ),
  SubscriptionPlan(
    id: 2,
    name: 'Premium 90',
    description: 'Premium access for ninety days',
    priceMinor: 99900,
    currency: 'RUB',
    durationDays: 90,
    isActive: true,
    renewable: false,
  ),
];

final checkout = CheckoutResponse(
  orderId: 'golden-order',
  paymentUrl: Uri.parse('https://pay.test/golden'),
  status: PaymentStatus.pending,
  amountMinor: 49900,
  currency: 'RUB',
);

final pendingPayment = PaymentStatusResponse(
  orderId: 'golden-order',
  status: PaymentStatus.pending,
  subscriptionActivated: false,
  updatedAt: DateTime.utc(2026, 7, 22),
);

const inactiveAccess = SubscriptionAccessState(
  status: SubscriptionAccessStatus.inactive,
);

final activeAccess = SubscriptionAccessState(
  status: SubscriptionAccessStatus.active,
  activeSubscription: ActiveSubscription(
    subscriptionId: 1,
    name: 'Premium 30',
    startAt: DateTime.utc(2026, 7, 22, 12),
    endAt: DateTime.utc(2026, 8, 21, 12),
    renewable: false,
  ),
);
