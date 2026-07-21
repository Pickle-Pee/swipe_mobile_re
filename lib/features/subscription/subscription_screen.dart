import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/config/config.dart';
import '../../core/network/api_exception.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';
import 'application/subscription_providers.dart';
import 'domain/subscription_models.dart';

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
    if (state == AppLifecycleState.resumed) {
      final subscription = ref.read(subscriptionControllerProvider);
      if (subscription.checkout != null &&
          {
            SubscriptionStatus.awaitingPayment,
            SubscriptionStatus.timedOut,
          }.contains(subscription.status)) {
        ref.read(subscriptionControllerProvider.notifier).checkPaymentStatus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionControllerProvider);
    return Scaffold(
      body: AppGradientScaffold(
        child: RefreshIndicator(
          onRefresh: ref.read(subscriptionControllerProvider.notifier).load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppTokens.screenPadding,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(Routes.discover),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Text(
                    'Premium',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  if (AppConfig.isDemoMode)
                    const PillTag(label: 'Demo payment', color: AppTokens.mint),
                ],
              ),
              const SizedBox(height: 8),
              if (state.activeSubscription case final active?) ...[
                _ActiveSubscriptionCard(
                  active: active,
                  busy: state.isBusy,
                  onCancel: active.renewable ? _confirmCancel : null,
                ),
                const SizedBox(height: 12),
              ],
              ..._content(state),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(SubscriptionState state) {
    if (state.status == SubscriptionStatus.loading && state.plans.isEmpty) {
      return const [
        SizedBox(height: 180),
        Center(child: CircularProgressIndicator()),
      ];
    }
    if (state.status == SubscriptionStatus.error && state.plans.isEmpty) {
      return [
        _MessageCard(message: _errorMessage(state.error)),
        TextButton(onPressed: _reload, child: const Text('Try again')),
      ];
    }
    if (state.plans.isEmpty) {
      return [
        const _MessageCard(
          message: 'No subscription plans are available right now.',
        ),
        TextButton(onPressed: _reload, child: const Text('Reload')),
      ];
    }
    return [
      const GlassSurface(
        child: Column(
          children: [
            Icon(Icons.auto_awesome, color: AppTokens.blueSoft, size: 40),
            SizedBox(height: 10),
            Text(
              'Deepen Your Connections',
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
            SizedBox(height: 8),
            Text(
              'Choose a plan. Your subscription becomes active only after backend confirmation.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      for (final plan in state.plans) ...[
        _PlanCard(
          plan: plan,
          selected: state.selectedPlanId == plan.id,
          onTap: state.isBusy
              ? null
              : () => ref
                    .read(subscriptionControllerProvider.notifier)
                    .selectPlan(plan.id),
        ),
        const SizedBox(height: 10),
      ],
      if (state.error != null) ...[
        _MessageCard(message: _errorMessage(state.error)),
        const SizedBox(height: 10),
      ],
      if (state.status == SubscriptionStatus.confirmed)
        const _MessageCard(message: 'Payment confirmed. Premium is active.'),
      if (state.status == SubscriptionStatus.failed)
        _MessageCard(
          message:
              state.payment?.failureMessage ??
              'Payment failed. Your subscription was not activated.',
        ),
      if (state.status == SubscriptionStatus.cancelled)
        const _MessageCard(message: 'Payment was cancelled.'),
      if (state.status == SubscriptionStatus.timedOut)
        const _MessageCard(
          message:
              'Confirmation is taking longer than expected. You can check again.',
        ),
      if ({
        SubscriptionStatus.awaitingPayment,
        SubscriptionStatus.checkingStatus,
      }.contains(state.status))
        const _MessageCard(
          message:
              'Waiting for confirmation from the backend. Returning from the browser is not proof of payment.',
        ),
      const SizedBox(height: 14),
      if (state.checkout != null &&
          {
            SubscriptionStatus.awaitingPayment,
            SubscriptionStatus.timedOut,
          }.contains(state.status))
        OutlinedButton.icon(
          onPressed: state.isBusy ? null : _checkPayment,
          icon: const Icon(Icons.refresh),
          label: const Text('Check payment'),
        ),
      if (AppConfig.isDemoMode &&
          state.checkout != null &&
          {
            SubscriptionStatus.awaitingPayment,
            SubscriptionStatus.timedOut,
          }.contains(state.status)) ...[
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: state.isBusy ? null : () => _completeDemo(false),
                child: const Text('Demo failure'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: state.isBusy ? null : () => _completeDemo(true),
                child: const Text('Demo success'),
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 10),
      AbsorbPointer(
        absorbing: !state.canCheckout,
        child: Opacity(
          opacity: state.canCheckout ? 1 : 0.5,
          child: GradientButton(
            label: state.status == SubscriptionStatus.creatingCheckout
                ? 'Creating checkout…'
                : 'Continue',
            onPressed: _createCheckout,
          ),
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Payment is completed on the bank page. The app never stores card details.',
        style: TextStyle(fontSize: 11),
        textAlign: TextAlign.center,
      ),
    ];
  }

  Future<void> _reload() =>
      ref.read(subscriptionControllerProvider.notifier).load();
  Future<void> _createCheckout() =>
      ref.read(subscriptionControllerProvider.notifier).createCheckout();
  Future<void> _checkPayment() =>
      ref.read(subscriptionControllerProvider.notifier).checkPaymentStatus();
  Future<void> _completeDemo(bool success) => ref
      .read(subscriptionControllerProvider.notifier)
      .completeDemo(success: success);

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Turn off auto-renewal?'),
        content: const Text(
          'Your paid access remains active until the displayed end date.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Turn off'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(subscriptionControllerProvider.notifier).cancelRenewal();
    }
  }

  String _errorMessage(Object? error) => error is ApiException
      ? error.message
      : error is FormatException
      ? 'The server returned an invalid subscription response.'
      : 'Could not complete the subscription request. Please try again.';
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });
  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GlassSurface(
    borderColor: selected ? AppTokens.blueSoft : AppTokens.border,
    child: ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: AppTokens.blueSoft,
      ),
      title: Text(plan.name, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        [
          if (plan.description?.isNotEmpty == true) plan.description!,
          '${plan.durationDays} days',
        ].join(' • '),
      ),
      trailing: Text(
        _money(plan.priceMinor, plan.currency),
        style: const TextStyle(color: AppTokens.blueSoft, fontSize: 18),
      ),
    ),
  );
}

class _ActiveSubscriptionCard extends StatelessWidget {
  const _ActiveSubscriptionCard({
    required this.active,
    required this.busy,
    required this.onCancel,
  });
  final ActiveSubscription active;
  final bool busy;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) => GlassSurface(
    borderColor: AppTokens.mint,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active subscription',
          style: TextStyle(color: AppTokens.mint),
        ),
        const SizedBox(height: 6),
        Text(
          active.name,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        Text('Until ${_date(active.endAt)}'),
        Text(active.renewable ? 'Auto-renewal is on' : 'Auto-renewal is off'),
        if (onCancel != null)
          TextButton(
            onPressed: busy ? null : onCancel,
            child: const Text('Turn off auto-renewal'),
          ),
      ],
    ),
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => GlassSurface(child: Text(message));
}

String _money(int minor, String currency) {
  final amount = (minor / 100).toStringAsFixed(2);
  return currency == 'RUB' ? '$amount ₽' : '$amount $currency';
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
