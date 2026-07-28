import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/subscription/application/subscription_providers.dart';
import 'package:swipe_mobile_re/features/subscription/domain/subscription_models.dart';
import 'package:swipe_mobile_re/features/subscription/domain/subscription_repository.dart';
import 'package:swipe_mobile_re/features/subscription/presentation/subscription_components.dart';
import 'package:swipe_mobile_re/features/subscription/subscription_screen.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  test('formats backend price and period without invented discounts', () {
    expect(formatSubscriptionPrice(49900, 'RUB'), '499\u00A0₽');
    expect(formatSubscriptionPrice(1234567, 'RUB'), '12\u00A0345.67\u00A0₽');
    expect(formatSubscriptionPrice(999, 'USD'), '9.99\u00A0USD');
    expect(formatSubscriptionPeriod(1), '1 day');
    expect(formatSubscriptionPeriod(30), '30 days');
  });

  group('SubscriptionView', () {
    testWidgets('renders only real backend plans and default selection', (
      tester,
    ) async {
      await pumpView(tester, plansState());

      expect(find.text('Server Premium'), findsOneWidget);
      expect(find.textContaining('499'), findsOneWidget);
      expect(find.text('30 days'), findsOneWidget);
      expect(find.text('Selected'), findsNothing);
      final card = tester.widget<SubscriptionPlanCard>(
        find.byType(SubscriptionPlanCard),
      );
      expect(card.plan.id, 7);
      expect(card.selected, isTrue);
      expect(find.textContaining('popular'), findsNothing);
      expect(find.textContaining('discount'), findsNothing);
    });

    testWidgets('plan selection is explicit and unavailable plan is disabled', (
      tester,
    ) async {
      var selected = 0;
      await pumpView(
        tester,
        SubscriptionState(
          plansStatus: SubscriptionPlansStatus.data,
          plans: const [serverPlan, unavailablePlan],
          selectedPlanId: 7,
        ),
        onSelectPlan: (id) => selected = id,
      );

      await tester.tap(find.text('Unavailable plan'));
      expect(selected, 0);
      await tester.tap(find.text('Server Premium'));
      expect(selected, 7);
      expect(find.text('Unavailable'), findsOneWidget);
    });

    testWidgets('shows loading, empty and plans error states', (tester) async {
      await pumpView(
        tester,
        const SubscriptionState(plansStatus: SubscriptionPlansStatus.loading),
        access: const SubscriptionAccessState(
          status: SubscriptionAccessStatus.inactive,
        ),
      );
      expect(find.byKey(const Key('subscription-loading')), findsOneWidget);

      await pumpView(
        tester,
        const SubscriptionState(plansStatus: SubscriptionPlansStatus.empty),
      );
      expect(find.text('No plans right now'), findsOneWidget);

      var retries = 0;
      await pumpView(
        tester,
        SubscriptionState(
          plansStatus: SubscriptionPlansStatus.error,
          plansError: Exception('offline'),
        ),
        onRetry: () => retries++,
      );
      expect(find.text('Plans are unavailable'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
    });

    testWidgets('renders checkout errors, pending and verification states', (
      tester,
    ) async {
      await pumpView(
        tester,
        plansState(
          checkoutStatus: CheckoutStatus.creationError,
          checkoutError: Exception('offline'),
        ),
      );
      expect(find.text('Could not create checkout'), findsOneWidget);

      await pumpView(
        tester,
        plansState(
          checkoutStatus: CheckoutStatus.verifying,
          checkout: checkout,
        ),
      );
      expect(find.text('Checking subscription status'), findsOneWidget);

      var checks = 0;
      await pumpView(
        tester,
        plansState(checkoutStatus: CheckoutStatus.pending, checkout: checkout),
        onVerify: () => checks++,
      );
      expect(find.text('Payment is still pending'), findsOneWidget);
      await tester.tap(find.text('Check again'));
      expect(checks, 1);

      await pumpView(
        tester,
        plansState(
          checkoutStatus: CheckoutStatus.verificationError,
          checkout: checkout,
        ),
      );
      expect(find.text('Could not verify payment'), findsOneWidget);
      expect(find.text('Premium is active'), findsNothing);
    });

    testWidgets('launch error reopens existing checkout', (tester) async {
      var reopened = 0;
      await pumpView(
        tester,
        plansState(
          checkoutStatus: CheckoutStatus.launchError,
          checkout: checkout,
        ),
        onReopen: () => reopened++,
      );

      await tester.tap(find.text('Open payment page'));
      expect(reopened, 1);
      expect(find.textContaining('No second checkout'), findsOneWidget);
    });

    testWidgets('active view has no recurrent billing controls', (
      tester,
    ) async {
      var likes = 0;
      await pumpView(
        tester,
        plansState(),
        access: SubscriptionAccessState(
          status: SubscriptionAccessStatus.active,
          activeSubscription: active(renewable: true),
        ),
        onOpenLikes: () => likes++,
      );

      expect(find.text('Premium is active'), findsOneWidget);
      expect(find.text('Access until 12.08.2026'), findsOneWidget);
      expect(find.textContaining('Auto-renewal'), findsNothing);
      expect(find.textContaining('Turn off'), findsNothing);
      await tester.tap(find.text('Open Likes'));
      expect(likes, 1);
    });

    testWidgets('long plan fits compact viewport at text scale 1.3', (
      tester,
    ) async {
      await pumpView(
        tester,
        const SubscriptionState(
          plansStatus: SubscriptionPlansStatus.data,
          plans: [longPlan],
          selectedPlanId: 99,
        ),
        size: const Size(320, 568),
        textScale: 1.3,
      );

      await scrollSubscriptionTo(tester, find.text(longPlan.name));
      expect(find.text(longPlan.name), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('SubscriptionScreen blocks double checkout tap', (tester) async {
    final repository = ScreenRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(repository),
          paymentUrlLauncherProvider.overrideWithValue(ScreenLauncher()),
          subscriptionProfileRefreshProvider.overrideWithValue(() async {}),
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
    expect(find.text('Server Premium'), findsOneWidget);

    final continueButton = find.text('Continue to payment');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.tap(continueButton);
    expect(repository.checkoutCalls, 1);

    repository.checkoutCompleter.complete(checkout);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -360));
    await tester.pumpAndSettle();
    expect(find.text('Check payment'), findsOneWidget);
  });

  testWidgets('lifecycle resume verifies backend status and activates access', (
    tester,
  ) async {
    final repository = ScreenRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(repository),
          paymentUrlLauncherProvider.overrideWithValue(ScreenLauncher()),
          subscriptionProfileRefreshProvider.overrideWithValue(() async {}),
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
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue to payment'));
    await tester.tap(find.text('Continue to payment'));
    repository.checkoutCompleter.complete(checkout);
    await tester.pumpAndSettle();

    repository.paymentStatus = PaymentStatus.succeeded;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(repository.statusCalls, 1);
    expect(find.text('Premium is active'), findsOneWidget);
  });
}

Future<void> scrollSubscriptionTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    220,
    scrollable: find.byType(Scrollable).last,
  );
}

Future<void> pumpView(
  WidgetTester tester,
  SubscriptionState state, {
  SubscriptionAccessState access = const SubscriptionAccessState(
    status: SubscriptionAccessStatus.inactive,
  ),
  VoidCallback? onRetry,
  ValueChanged<int>? onSelectPlan,
  VoidCallback? onReopen,
  VoidCallback? onVerify,
  VoidCallback? onOpenLikes,
  Size size = const Size(390, 844),
  double textScale = 1,
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
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: SubscriptionView(
          state: state,
          access: access,
          isDemoMode: false,
          onBack: () {},
          onRefresh: () async {},
          onRetry: onRetry ?? () {},
          onSelectPlan: onSelectPlan ?? (_) {},
          onCreateCheckout: () {},
          onReopenPayment: onReopen ?? () {},
          onVerifyPayment: onVerify ?? () {},
          onDemoResult: (_) {},
          onOpenLikes: onOpenLikes ?? () {},
        ),
      ),
    ),
  );
  await tester.pump();
}

SubscriptionState plansState({
  CheckoutStatus checkoutStatus = CheckoutStatus.idle,
  CheckoutResponse? checkout,
  Object? checkoutError,
}) => SubscriptionState(
  plansStatus: SubscriptionPlansStatus.data,
  checkoutStatus: checkoutStatus,
  plans: const [serverPlan],
  selectedPlanId: 7,
  checkout: checkout,
  checkoutError: checkoutError,
);

const serverPlan = SubscriptionPlan(
  id: 7,
  name: 'Server Premium',
  description: 'Unlock incoming Likes',
  priceMinor: 49900,
  currency: 'RUB',
  durationDays: 30,
  isActive: true,
  renewable: false,
);

const unavailablePlan = SubscriptionPlan(
  id: 8,
  name: 'Unavailable plan',
  priceMinor: 89900,
  currency: 'RUB',
  durationDays: 90,
  isActive: false,
  renewable: false,
);

const longPlan = SubscriptionPlan(
  id: 99,
  name: 'A deliberately long backend subscription plan name',
  description:
      'A long real backend description that must wrap cleanly without clipping on a compact viewport.',
  priceMinor: 1234567,
  currency: 'RUB',
  durationDays: 365,
  isActive: true,
  renewable: false,
);

final checkout = CheckoutResponse(
  orderId: 'order-1',
  paymentUrl: Uri.parse('https://pay.test'),
  status: PaymentStatus.pending,
  amountMinor: 49900,
  currency: 'RUB',
);

ActiveSubscription active({bool renewable = false}) => ActiveSubscription(
  subscriptionId: 7,
  name: 'Server Premium',
  startAt: DateTime.utc(2026, 7, 13),
  endAt: DateTime.utc(2026, 8, 12, 12),
  renewable: renewable,
);

class ScreenLauncher implements PaymentUrlLauncher {
  @override
  Future<bool> open(Uri url) async => true;
}

class ScreenRepository implements SubscriptionRepository {
  final checkoutCompleter = Completer<CheckoutResponse>();
  int checkoutCalls = 0;
  int statusCalls = 0;
  PaymentStatus paymentStatus = PaymentStatus.pending;
  ActiveSubscription? activeValue;

  @override
  Future<List<SubscriptionPlan>> getPlans() async => const [serverPlan];

  @override
  Future<ActiveSubscription?> getActiveSubscription() async => activeValue;

  @override
  Future<CheckoutResponse> createCheckout(
    int subscriptionId,
    String idempotencyKey,
  ) {
    checkoutCalls++;
    return checkoutCompleter.future;
  }

  @override
  Future<PaymentStatusResponse> getPaymentStatus(String orderId) async {
    statusCalls++;
    if (paymentStatus == PaymentStatus.succeeded) {
      activeValue ??= active();
    }
    return PaymentStatusResponse(
      orderId: orderId,
      status: paymentStatus,
      subscriptionActivated: paymentStatus == PaymentStatus.succeeded,
      subscription: activeValue,
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
