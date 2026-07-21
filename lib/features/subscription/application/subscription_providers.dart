import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/config.dart';
import '../../auth/application/auth_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../domain/subscription_models.dart';
import '../domain/subscription_repository.dart';

enum SubscriptionStatus {
  initial,
  loading,
  plansLoaded,
  empty,
  creatingCheckout,
  awaitingPayment,
  checkingStatus,
  confirmed,
  failed,
  cancelled,
  timedOut,
  error,
}

class SubscriptionState {
  const SubscriptionState({
    this.status = SubscriptionStatus.initial,
    this.plans = const [],
    this.selectedPlanId,
    this.activeSubscription,
    this.checkout,
    this.payment,
    this.error,
    this.pollAttempt = 0,
  });

  final SubscriptionStatus status;
  final List<SubscriptionPlan> plans;
  final int? selectedPlanId;
  final ActiveSubscription? activeSubscription;
  final CheckoutResponse? checkout;
  final PaymentStatusResponse? payment;
  final Object? error;
  final int pollAttempt;

  bool get isBusy =>
      status == SubscriptionStatus.creatingCheckout ||
      status == SubscriptionStatus.checkingStatus;
  bool get canCheckout =>
      selectedPlanId != null &&
      !isBusy &&
      status != SubscriptionStatus.awaitingPayment;

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    List<SubscriptionPlan>? plans,
    int? selectedPlanId,
    bool clearSelectedPlan = false,
    ActiveSubscription? activeSubscription,
    bool clearActiveSubscription = false,
    CheckoutResponse? checkout,
    PaymentStatusResponse? payment,
    Object? error,
    bool clearError = false,
    int? pollAttempt,
  }) => SubscriptionState(
    status: status ?? this.status,
    plans: plans ?? this.plans,
    selectedPlanId: clearSelectedPlan
        ? null
        : selectedPlanId ?? this.selectedPlanId,
    activeSubscription: clearActiveSubscription
        ? null
        : activeSubscription ?? this.activeSubscription,
    checkout: checkout ?? this.checkout,
    payment: payment ?? this.payment,
    error: clearError ? null : error ?? this.error,
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
    _pollGeneration++;
    state = state.copyWith(
      status: SubscriptionStatus.loading,
      clearError: true,
    );
    try {
      final results = await Future.wait<Object?>([
        _repository.getPlans(),
        _repository.getActiveSubscription(),
      ]);
      final plans = results[0]! as List<SubscriptionPlan>;
      final active = results[1] as ActiveSubscription?;
      state = SubscriptionState(
        status: plans.isEmpty
            ? SubscriptionStatus.empty
            : SubscriptionStatus.plansLoaded,
        plans: plans,
        selectedPlanId: plans.isEmpty ? null : plans.first.id,
        activeSubscription: active,
      );
    } on Object catch (error) {
      state = state.copyWith(status: SubscriptionStatus.error, error: error);
    }
  }

  void selectPlan(int id) {
    if (state.isBusy || !state.plans.any((plan) => plan.id == id)) {
      return;
    }
    state = state.copyWith(selectedPlanId: id, clearError: true);
  }

  Future<void> createCheckout() async {
    final selected = state.selectedPlanId;
    if (selected == null ||
        state.isBusy ||
        state.status == SubscriptionStatus.awaitingPayment) {
      return;
    }
    _pollGeneration++;
    state = state.copyWith(
      status: SubscriptionStatus.creatingCheckout,
      clearError: true,
      pollAttempt: 0,
    );
    try {
      final checkout = await _repository.createCheckout(
        selected,
        const Uuid().v4(),
      );
      final url = checkout.paymentUrl;
      if (url == null) {
        throw const FormatException('Backend did not return a payment URL');
      }
      if (!await ref.read(paymentUrlLauncherProvider).open(url)) {
        throw StateError('Could not open the payment form');
      }
      state = state.copyWith(
        status: SubscriptionStatus.awaitingPayment,
        checkout: checkout,
      );
      final generation = ++_pollGeneration;
      unawaited(_pollPayment(generation));
    } on Object catch (error) {
      state = state.copyWith(status: SubscriptionStatus.error, error: error);
    }
  }

  Future<void> checkPaymentStatus() async {
    final orderId = state.checkout?.orderId;
    if (orderId == null || state.status == SubscriptionStatus.checkingStatus) {
      return;
    }
    await _check(orderId);
  }

  Future<void> _pollPayment(int generation) async {
    final config = ref.read(subscriptionPollConfigProvider);
    final orderId = state.checkout?.orderId;
    if (orderId == null) {
      return;
    }
    for (var attempt = 1; attempt <= config.maxAttempts; attempt++) {
      await Future<void>.delayed(config.interval);
      if (generation != _pollGeneration) {
        return;
      }
      state = state.copyWith(pollAttempt: attempt);
      final terminal = await _check(orderId);
      if (terminal || generation != _pollGeneration) {
        return;
      }
    }
    if (generation == _pollGeneration &&
        state.status == SubscriptionStatus.awaitingPayment) {
      state = state.copyWith(status: SubscriptionStatus.timedOut);
    }
  }

  Future<bool> _check(String orderId) async {
    final previous = state.status;
    state = state.copyWith(
      status: SubscriptionStatus.checkingStatus,
      clearError: true,
    );
    try {
      final payment = await _repository.getPaymentStatus(orderId);
      switch (payment.status) {
        case PaymentStatus.succeeded:
          final active =
              payment.subscription ?? await _repository.getActiveSubscription();
          state = state.copyWith(
            status: SubscriptionStatus.confirmed,
            payment: payment,
            activeSubscription: active,
          );
          _pollGeneration++;
          await ref.read(subscriptionProfileRefreshProvider)();
          return true;
        case PaymentStatus.failed:
          state = state.copyWith(
            status: SubscriptionStatus.failed,
            payment: payment,
          );
          _pollGeneration++;
          return true;
        case PaymentStatus.canceled:
          state = state.copyWith(
            status: SubscriptionStatus.cancelled,
            payment: payment,
          );
          _pollGeneration++;
          return true;
        case PaymentStatus.refunded:
        case PaymentStatus.partiallyRefunded:
          state = state.copyWith(
            status: SubscriptionStatus.failed,
            payment: payment,
          );
          _pollGeneration++;
          return true;
        case PaymentStatus.pending:
        case PaymentStatus.requiresAction:
        case PaymentStatus.processing:
          state = state.copyWith(
            status: SubscriptionStatus.awaitingPayment,
            payment: payment,
          );
          return false;
      }
    } on Object catch (error) {
      state = state.copyWith(status: previous, error: error);
      return false;
    }
  }

  Future<void> completeDemo({required bool success}) async {
    if (!AppConfig.isDemoMode || state.checkout == null || state.isBusy) {
      return;
    }
    try {
      final payment = await _repository.setDemoPaymentResult(
        state.checkout!.orderId,
        success: success,
      );
      state = state.copyWith(payment: payment);
      await checkPaymentStatus();
    } on Object catch (error) {
      state = state.copyWith(status: SubscriptionStatus.error, error: error);
    }
  }

  Future<void> cancelRenewal() async {
    if (state.isBusy || state.activeSubscription == null) {
      return;
    }
    state = state.copyWith(
      status: SubscriptionStatus.checkingStatus,
      clearError: true,
    );
    try {
      final active = await _repository.cancelRenewal();
      state = state.copyWith(
        status: SubscriptionStatus.plansLoaded,
        activeSubscription: active,
      );
    } on Object catch (error) {
      state = state.copyWith(status: SubscriptionStatus.error, error: error);
    }
  }
}
