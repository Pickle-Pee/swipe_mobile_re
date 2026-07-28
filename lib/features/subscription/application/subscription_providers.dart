import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/config.dart';
import '../../auth/application/auth_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../domain/subscription_models.dart';
import '../domain/subscription_repository.dart';

enum SubscriptionPlansStatus { initial, loading, data, empty, error }

enum CheckoutStatus {
  idle,
  creating,
  openingPayment,
  creationError,
  launchError,
  awaitingPayment,
  verifying,
  pending,
  confirmed,
  failed,
  cancelled,
  timedOut,
  verificationError,
}

class SubscriptionState {
  const SubscriptionState({
    this.plansStatus = SubscriptionPlansStatus.initial,
    this.checkoutStatus = CheckoutStatus.idle,
    this.plans = const [],
    this.selectedPlanId,
    this.checkout,
    this.payment,
    this.plansError,
    this.checkoutError,
    this.pollAttempt = 0,
  });

  final SubscriptionPlansStatus plansStatus;
  final CheckoutStatus checkoutStatus;
  final List<SubscriptionPlan> plans;
  final int? selectedPlanId;
  final CheckoutResponse? checkout;
  final PaymentStatusResponse? payment;
  final Object? plansError;
  final Object? checkoutError;
  final int pollAttempt;

  SubscriptionPlan? get selectedPlan {
    final selected = selectedPlanId;
    if (selected == null) return null;
    for (final plan in plans) {
      if (plan.id == selected) return plan;
    }
    return null;
  }

  bool get isCheckoutBusy =>
      checkoutStatus == CheckoutStatus.creating ||
      checkoutStatus == CheckoutStatus.openingPayment ||
      checkoutStatus == CheckoutStatus.verifying;

  bool get hasOpenCheckout => const {
    CheckoutStatus.openingPayment,
    CheckoutStatus.launchError,
    CheckoutStatus.awaitingPayment,
    CheckoutStatus.verifying,
    CheckoutStatus.pending,
    CheckoutStatus.timedOut,
    CheckoutStatus.verificationError,
  }.contains(checkoutStatus);

  bool get canCreateCheckout =>
      plansStatus == SubscriptionPlansStatus.data &&
      selectedPlan?.isActive == true &&
      !isCheckoutBusy &&
      !hasOpenCheckout;

  bool get canVerify =>
      checkout != null &&
      !isCheckoutBusy &&
      const {
        CheckoutStatus.awaitingPayment,
        CheckoutStatus.pending,
        CheckoutStatus.timedOut,
        CheckoutStatus.verificationError,
      }.contains(checkoutStatus);

  SubscriptionState copyWith({
    SubscriptionPlansStatus? plansStatus,
    CheckoutStatus? checkoutStatus,
    List<SubscriptionPlan>? plans,
    int? selectedPlanId,
    bool clearSelectedPlan = false,
    CheckoutResponse? checkout,
    bool clearCheckout = false,
    PaymentStatusResponse? payment,
    bool clearPayment = false,
    Object? plansError,
    bool clearPlansError = false,
    Object? checkoutError,
    bool clearCheckoutError = false,
    int? pollAttempt,
  }) => SubscriptionState(
    plansStatus: plansStatus ?? this.plansStatus,
    checkoutStatus: checkoutStatus ?? this.checkoutStatus,
    plans: plans ?? this.plans,
    selectedPlanId: clearSelectedPlan
        ? null
        : selectedPlanId ?? this.selectedPlanId,
    checkout: clearCheckout ? null : checkout ?? this.checkout,
    payment: clearPayment ? null : payment ?? this.payment,
    plansError: clearPlansError ? null : plansError ?? this.plansError,
    checkoutError: clearCheckoutError
        ? null
        : checkoutError ?? this.checkoutError,
    pollAttempt: pollAttempt ?? this.pollAttempt,
  );
}

abstract interface class PaymentUrlLauncher {
  Future<bool> open(Uri url);
}

class ExternalPaymentUrlLauncher implements PaymentUrlLauncher {
  @override
  Future<bool> open(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);
}

class SubscriptionPollConfig {
  const SubscriptionPollConfig({
    this.interval = const Duration(seconds: 3),
    this.maxAttempts = 5,
  });

  final Duration interval;
  final int maxAttempts;
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return DioSubscriptionRepository(ref.watch(apiClientProvider));
});

enum SubscriptionAccessStatus { initial, loading, inactive, active, error }

class SubscriptionAccessState {
  const SubscriptionAccessState({
    this.status = SubscriptionAccessStatus.initial,
    this.activeSubscription,
    this.error,
    this.isRefreshing = false,
  });

  final SubscriptionAccessStatus status;
  final ActiveSubscription? activeSubscription;
  final Object? error;
  final bool isRefreshing;

  bool get isResolved =>
      status == SubscriptionAccessStatus.inactive ||
      status == SubscriptionAccessStatus.active;
  bool get hasPremiumAccess =>
      status == SubscriptionAccessStatus.active && activeSubscription != null;
}

final subscriptionAccessControllerProvider =
    NotifierProvider<SubscriptionAccessController, SubscriptionAccessState>(
      SubscriptionAccessController.new,
    );

class SubscriptionAccessController extends Notifier<SubscriptionAccessState> {
  SubscriptionRepository get _repository =>
      ref.read(subscriptionRepositoryProvider);

  @override
  SubscriptionAccessState build() => const SubscriptionAccessState();

  Future<void> ensureLoaded() async {
    if (state.status != SubscriptionAccessStatus.initial) return;
    await refresh();
  }

  Future<void> refresh() async {
    final retained = state.isResolved ? state : null;
    state = retained == null
        ? const SubscriptionAccessState(
            status: SubscriptionAccessStatus.loading,
          )
        : SubscriptionAccessState(
            status: retained.status,
            activeSubscription: retained.activeSubscription,
            isRefreshing: true,
          );
    try {
      final active = await _repository.getActiveSubscription();
      state = SubscriptionAccessState(
        status: active == null
            ? SubscriptionAccessStatus.inactive
            : SubscriptionAccessStatus.active,
        activeSubscription: active,
      );
    } on Object catch (error) {
      state = retained == null
          ? SubscriptionAccessState(
              status: SubscriptionAccessStatus.error,
              error: error,
            )
          : SubscriptionAccessState(
              status: retained.status,
              activeSubscription: retained.activeSubscription,
              error: error,
            );
    }
  }

  void updateFromConfirmed(ActiveSubscription active) {
    state = SubscriptionAccessState(
      status: SubscriptionAccessStatus.active,
      activeSubscription: active,
    );
  }
}

final paymentUrlLauncherProvider = Provider<PaymentUrlLauncher>((ref) {
  return ExternalPaymentUrlLauncher();
});

final subscriptionPollConfigProvider = Provider<SubscriptionPollConfig>((ref) {
  return const SubscriptionPollConfig();
});

final subscriptionProfileRefreshProvider = Provider<Future<void> Function()>((
  ref,
) {
  return ref.read(profileControllerProvider.notifier).load;
});

final subscriptionControllerProvider =
    NotifierProvider<SubscriptionController, SubscriptionState>(
      SubscriptionController.new,
    );

class SubscriptionController extends Notifier<SubscriptionState> {
  SubscriptionRepository get _repository =>
      ref.read(subscriptionRepositoryProvider);
  int _pollGeneration = 0;

  @override
  SubscriptionState build() {
    ref.onDispose(() => _pollGeneration++);
    return const SubscriptionState();
  }

  Future<void> load() async {
    await Future.wait([
      loadPlans(),
      ref.read(subscriptionAccessControllerProvider.notifier).refresh(),
    ]);
  }

  Future<void> loadPlans() async {
    state = state.copyWith(
      plansStatus: SubscriptionPlansStatus.loading,
      clearPlansError: true,
    );
    try {
      final plans = await _repository.getPlans();
      final retainedSelection = state.selectedPlanId;
      final selectionStillValid = plans.any(
        (plan) => plan.id == retainedSelection && plan.isActive,
      );
      final fallback = _firstActivePlan(plans)?.id;
      state = state.copyWith(
        plansStatus: plans.isEmpty
            ? SubscriptionPlansStatus.empty
            : SubscriptionPlansStatus.data,
        plans: plans,
        selectedPlanId: selectionStillValid ? retainedSelection : fallback,
        clearSelectedPlan: !selectionStillValid && fallback == null,
        clearPlansError: true,
      );
    } on Object catch (error) {
      state = state.copyWith(
        plansStatus: SubscriptionPlansStatus.error,
        plansError: error,
      );
    }
  }

  void selectPlan(int id) {
    if (state.isCheckoutBusy ||
        !state.plans.any((plan) => plan.id == id && plan.isActive)) {
      return;
    }
    state = state.copyWith(selectedPlanId: id, clearCheckoutError: true);
  }

  Future<void> createCheckout() async {
    final selected = state.selectedPlan;
    if (selected == null || !state.canCreateCheckout) return;

    _pollGeneration++;
    state = state.copyWith(
      checkoutStatus: CheckoutStatus.creating,
      clearCheckout: true,
      clearPayment: true,
      clearCheckoutError: true,
      pollAttempt: 0,
    );
    try {
      final checkout = await _repository.createCheckout(
        selected.id,
        const Uuid().v4(),
      );
      final url = checkout.paymentUrl;
      if (url == null) {
        throw const FormatException('Backend did not return a payment URL');
      }
      state = state.copyWith(
        checkoutStatus: CheckoutStatus.openingPayment,
        checkout: checkout,
      );
      await _openPaymentUrl(url);
    } on Object catch (error) {
      if (state.checkoutStatus == CheckoutStatus.openingPayment) {
        state = state.copyWith(
          checkoutStatus: CheckoutStatus.launchError,
          checkoutError: error,
        );
      } else {
        state = state.copyWith(
          checkoutStatus: CheckoutStatus.creationError,
          checkoutError: error,
        );
      }
    }
  }

  Future<void> reopenPayment() async {
    final url = state.checkout?.paymentUrl;
    if (url == null ||
        state.checkoutStatus != CheckoutStatus.launchError ||
        state.isCheckoutBusy) {
      return;
    }
    state = state.copyWith(
      checkoutStatus: CheckoutStatus.openingPayment,
      clearCheckoutError: true,
    );
    try {
      await _openPaymentUrl(url);
    } on Object catch (error) {
      state = state.copyWith(
        checkoutStatus: CheckoutStatus.launchError,
        checkoutError: error,
      );
    }
  }

  Future<void> _openPaymentUrl(Uri url) async {
    if (!await ref.read(paymentUrlLauncherProvider).open(url)) {
      throw StateError('Could not open the payment form');
    }
    state = state.copyWith(
      checkoutStatus: CheckoutStatus.awaitingPayment,
      clearCheckoutError: true,
    );
    final generation = ++_pollGeneration;
    unawaited(_pollPayment(generation));
  }

  Future<void> checkPaymentStatus() async {
    final orderId = state.checkout?.orderId;
    if (orderId == null || state.isCheckoutBusy) return;
    await _check(orderId);
  }

  Future<void> _pollPayment(int generation) async {
    final config = ref.read(subscriptionPollConfigProvider);
    final orderId = state.checkout?.orderId;
    if (orderId == null) return;
    if (config.maxAttempts <= 0) return;

    for (var attempt = 1; attempt <= config.maxAttempts; attempt++) {
      await Future<void>.delayed(config.interval);
      if (generation != _pollGeneration) return;
      state = state.copyWith(pollAttempt: attempt);
      final terminal = await _check(orderId);
      if (terminal || generation != _pollGeneration) return;
    }
    if (generation == _pollGeneration &&
        const {
          CheckoutStatus.awaitingPayment,
          CheckoutStatus.pending,
        }.contains(state.checkoutStatus)) {
      state = state.copyWith(checkoutStatus: CheckoutStatus.timedOut);
    }
  }

  Future<bool> _check(String orderId) async {
    state = state.copyWith(
      checkoutStatus: CheckoutStatus.verifying,
      clearCheckoutError: true,
    );
    try {
      final payment = await _repository.getPaymentStatus(orderId);
      switch (payment.status) {
        case PaymentStatus.succeeded:
          final active =
              payment.subscription ?? await _repository.getActiveSubscription();
          if (active == null) {
            throw StateError(
              'Payment succeeded but the backend has not activated Premium',
            );
          }
          state = state.copyWith(
            checkoutStatus: CheckoutStatus.confirmed,
            payment: payment,
            clearCheckoutError: true,
          );
          ref
              .read(subscriptionAccessControllerProvider.notifier)
              .updateFromConfirmed(active);
          _pollGeneration++;
          await ref.read(subscriptionProfileRefreshProvider)();
          return true;
        case PaymentStatus.failed:
          state = state.copyWith(
            checkoutStatus: CheckoutStatus.failed,
            payment: payment,
          );
          _pollGeneration++;
          return true;
        case PaymentStatus.canceled:
          state = state.copyWith(
            checkoutStatus: CheckoutStatus.cancelled,
            payment: payment,
          );
          _pollGeneration++;
          return true;
        case PaymentStatus.refunded:
        case PaymentStatus.partiallyRefunded:
          state = state.copyWith(
            checkoutStatus: CheckoutStatus.failed,
            payment: payment,
          );
          _pollGeneration++;
          return true;
        case PaymentStatus.pending:
        case PaymentStatus.requiresAction:
        case PaymentStatus.processing:
          state = state.copyWith(
            checkoutStatus: CheckoutStatus.pending,
            payment: payment,
          );
          return false;
      }
    } on Object catch (error) {
      state = state.copyWith(
        checkoutStatus: CheckoutStatus.verificationError,
        checkoutError: error,
      );
      _pollGeneration++;
      return true;
    }
  }

  Future<void> completeDemo({required bool success}) async {
    if (!AppConfig.isDemoMode ||
        state.checkout == null ||
        state.isCheckoutBusy) {
      return;
    }
    try {
      await _repository.setDemoPaymentResult(
        state.checkout!.orderId,
        success: success,
      );
      await checkPaymentStatus();
    } on Object catch (error) {
      state = state.copyWith(
        checkoutStatus: CheckoutStatus.verificationError,
        checkoutError: error,
      );
    }
  }
}

SubscriptionPlan? _firstActivePlan(List<SubscriptionPlan> plans) {
  for (final plan in plans) {
    if (plan.isActive) return plan;
  }
  return null;
}
