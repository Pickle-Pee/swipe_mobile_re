import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/theme/tokens.dart';
import '../../../shared/ui/liquid_ui.dart';
import '../../../shared/ui/midnight_components.dart';
import '../application/subscription_providers.dart';
import '../domain/subscription_models.dart';

class SubscriptionView extends StatelessWidget {
  const SubscriptionView({
    super.key,
    required this.state,
    required this.access,
    required this.isDemoMode,
    required this.onBack,
    required this.onRefresh,
    required this.onRetry,
    required this.onSelectPlan,
    required this.onCreateCheckout,
    required this.onReopenPayment,
    required this.onVerifyPayment,
    required this.onDemoResult,
    required this.onOpenLikes,
  });

  final SubscriptionState state;
  final SubscriptionAccessState access;
  final bool isDemoMode;
  final VoidCallback onBack;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectPlan;
  final VoidCallback onCreateCheckout;
  final VoidCallback onReopenPayment;
  final VoidCallback onVerifyPayment;
  final ValueChanged<bool> onDemoResult;
  final VoidCallback onOpenLikes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.backgroundBase,
      body: AppGradientScaffold(
        safeArea: false,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space12,
                  AppTokens.space8,
                  AppTokens.space12,
                  0,
                ),
                child: AppTopBar(
                  key: const Key('subscription-top-bar'),
                  title: 'Premium',
                  leading: GlassIconButton(
                    icon: Icons.arrow_back_rounded,
                    semanticLabel: 'Back',
                    tooltip: 'Back',
                    onPressed: onBack,
                  ),
                  actions: [if (isDemoMode) const _DemoBadge()],
                ),
              ),
              if (state.plansStatus == SubscriptionPlansStatus.loading ||
                  access.isRefreshing)
                const LinearProgressIndicator(
                  key: Key('subscription-refresh-progress'),
                  minHeight: 2,
                  color: AppTokens.brandViolet,
                  backgroundColor: Colors.transparent,
                  semanticsLabel: 'Refreshing Premium status',
                ),
              Expanded(child: _content(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final accessLoading =
        access.status == SubscriptionAccessStatus.initial ||
        access.status == SubscriptionAccessStatus.loading;
    if (accessLoading ||
        (state.plansStatus == SubscriptionPlansStatus.loading &&
            state.plans.isEmpty)) {
      return const SubscriptionLoadingView(key: Key('subscription-loading'));
    }

    final active = access.activeSubscription;
    if (access.hasPremiumAccess && active != null) {
      return ActiveSubscriptionView(
        key: const Key('subscription-active'),
        active: active,
        onOpenLikes: onOpenLikes,
        onRefresh: onRefresh,
      );
    }

    if (access.status == SubscriptionAccessStatus.error) {
      return _CenteredState(
        child: ErrorState(
          key: const Key('subscription-access-error'),
          title: 'Could not check Premium',
          message:
              'We could not confirm whether Premium is active. Try again before starting a payment.',
          actionLabel: 'Try again',
          onAction: onRetry,
        ),
      );
    }

    if (state.plansStatus == SubscriptionPlansStatus.error &&
        state.plans.isEmpty) {
      return _CenteredState(
        child: ErrorState(
          key: const Key('subscription-plans-error'),
          title: 'Plans are unavailable',
          message: subscriptionErrorMessage(state.plansError),
          actionLabel: 'Try again',
          onAction: onRetry,
        ),
      );
    }

    if (state.plansStatus == SubscriptionPlansStatus.empty ||
        state.plans.isEmpty) {
      return _CenteredState(
        child: EmptyState(
          key: const Key('subscription-plans-empty'),
          title: 'No plans right now',
          message:
              'The backend did not return an available Premium plan. Please check again later.',
          actionLabel: 'Reload',
          onAction: onRetry,
          icon: Icons.workspace_premium_outlined,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const Key('subscription-plans-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space16,
          AppTokens.space16,
          AppTokens.space16,
          AppTokens.space40,
        ),
        children: [
          const SubscriptionHero(),
          const SizedBox(height: AppTokens.space20),
          Text(
            'Choose your plan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTokens.space12),
          for (final plan in state.plans) ...[
            SubscriptionPlanCard(
              key: ValueKey<String>('subscription-plan-${plan.id}'),
              plan: plan,
              selected: state.selectedPlanId == plan.id,
              loading: state.isCheckoutBusy && state.selectedPlanId == plan.id,
              onTap: state.isCheckoutBusy || !plan.isActive
                  ? null
                  : () => onSelectPlan(plan.id),
            ),
            if (plan != state.plans.last)
              const SizedBox(height: AppTokens.space12),
          ],
          const SizedBox(height: AppTokens.space16),
          if (state.plansError != null) ...[
            SubscriptionStatusPanel(
              key: const Key('subscription-stale-plans-error'),
              icon: Icons.cloud_off_rounded,
              title: 'Plans could not be refreshed',
              message: 'Your previously loaded plans are still shown.',
              tone: SubscriptionStatusTone.warning,
              actionLabel: 'Retry',
              onAction: onRetry,
            ),
            const SizedBox(height: AppTokens.space12),
          ],
          if (access.error != null) ...[
            SubscriptionStatusPanel(
              key: const Key('subscription-access-refresh-error'),
              icon: Icons.cloud_off_rounded,
              title: 'Premium status could not be refreshed',
              message: 'Retry the backend check before starting a new payment.',
              tone: SubscriptionStatusTone.warning,
              actionLabel: 'Retry',
              onAction: onRetry,
            ),
            const SizedBox(height: AppTokens.space12),
          ],
          if (state.checkoutStatus != CheckoutStatus.idle)
            _CheckoutStatusContent(
              state: state,
              onReopenPayment: onReopenPayment,
              onVerifyPayment: onVerifyPayment,
            ),
          if (state.checkoutStatus != CheckoutStatus.idle)
            const SizedBox(height: AppTokens.space12),
          if (isDemoMode &&
              state.checkout != null &&
              state.checkoutStatus != CheckoutStatus.confirmed &&
              state.checkoutStatus != CheckoutStatus.failed &&
              state.checkoutStatus != CheckoutStatus.cancelled)
            _DemoPaymentPanel(
              busy: state.isCheckoutBusy,
              onResult: onDemoResult,
            ),
          if (isDemoMode &&
              state.checkout != null &&
              state.checkoutStatus != CheckoutStatus.confirmed &&
              state.checkoutStatus != CheckoutStatus.failed &&
              state.checkoutStatus != CheckoutStatus.cancelled)
            const SizedBox(height: AppTokens.space12),
          SubscriptionCheckoutButton(
            status: state.checkoutStatus,
            enabled:
                state.canCreateCheckout &&
                access.status == SubscriptionAccessStatus.inactive &&
                access.error == null,
            onPressed: onCreateCheckout,
          ),
          const SizedBox(height: AppTokens.space12),
          Text(
            'Payment opens on the bank page. The app does not store card details, and Premium activates only after backend confirmation.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTokens.textMuted),
          ),
        ],
      ),
    );
  }
}

class SubscriptionHero extends StatelessWidget {
  const SubscriptionHero({super.key});

  @override
  Widget build(BuildContext context) {
    return _SolidSurface(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppTokens.ctaGradient,
              shape: BoxShape.circle,
              boxShadow: AppTokens.brandShadow(),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppTokens.textPrimary,
              size: 30,
            ),
          ),
          const SizedBox(height: AppTokens.space16),
          Text(
            'See who already likes you',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTokens.space8),
          Text(
            'Premium unlocks your real incoming Likes so you can open a profile and like them back.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

class SubscriptionPlanCard extends StatelessWidget {
  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.loading,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = plan.isActive && onTap != null;
    final status = !plan.isActive
        ? 'Unavailable'
        : selected
        ? 'Selected'
        : 'Select';
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label:
          '${plan.name}, ${formatSubscriptionPrice(plan.priceMinor, plan.currency)}, ${formatSubscriptionPeriod(plan.durationDays)}, $status',
      onTap: enabled ? onTap : null,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? AppTokens.brandViolet.withValues(alpha: 0.14)
            : AppTokens.surfaceSolid,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppTokens.motionTab,
            constraints: const BoxConstraints(minHeight: 112),
            padding: const EdgeInsets.all(AppTokens.space16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
              border: Border.all(
                width: selected ? 1.5 : 1,
                color: selected ? AppTokens.brandViolet : AppTokens.glassBorder,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppTokens.space4),
                  child: loading
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          !plan.isActive
                              ? Icons.block_rounded
                              : selected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: !plan.isActive
                              ? AppTokens.textMuted
                              : selected
                              ? AppTokens.brandViolet
                              : AppTokens.textSecondary,
                        ),
                ),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppTokens.space4),
                      Text(
                        formatSubscriptionPeriod(plan.durationDays),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTokens.textSecondary,
                        ),
                      ),
                      if (plan.description?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: AppTokens.space8),
                        Text(
                          plan.description!.trim(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (!plan.isActive) ...[
                        const SizedBox(height: AppTokens.space8),
                        Text(
                          'Unavailable',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppTokens.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.space8),
                Flexible(
                  child: Text(
                    formatSubscriptionPrice(plan.priceMinor, plan.currency),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: plan.isActive
                          ? AppTokens.textPrimary
                          : AppTokens.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SubscriptionCheckoutButton extends StatelessWidget {
  const SubscriptionCheckoutButton({
    super.key,
    required this.status,
    required this.enabled,
    required this.onPressed,
  });

  final CheckoutStatus status;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final loading = status == CheckoutStatus.creating;
    return PrimaryActionButton(
      key: const Key('subscription-checkout-button'),
      label: loading ? 'Creating checkout' : 'Continue to payment',
      icon: loading ? null : Icons.open_in_new_rounded,
      loading: loading,
      onPressed: enabled ? onPressed : null,
    );
  }
}

enum SubscriptionStatusTone { neutral, success, warning, error }

class SubscriptionStatusPanel extends StatelessWidget {
  const SubscriptionStatusPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.tone = SubscriptionStatusTone.neutral,
    this.actionLabel,
    this.onAction,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final SubscriptionStatusTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      SubscriptionStatusTone.neutral => AppTokens.brandViolet,
      SubscriptionStatusTone.success => AppTokens.success,
      SubscriptionStatusTone.warning => AppTokens.warning,
      SubscriptionStatusTone.error => AppTokens.error,
    };
    return _SolidSurface(
      borderColor: color.withValues(alpha: 0.5),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (loading)
              SizedBox.square(
                dimension: AppTokens.iconNavigation,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: color,
                ),
              )
            else
              Icon(icon, color: color, size: AppTokens.iconNavigation),
            const SizedBox(width: AppTokens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space4),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTokens.textSecondary,
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: AppTokens.space12),
                    SecondaryActionButton(
                      label: actionLabel!,
                      onPressed: onAction,
                      expanded: false,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentVerificationView extends StatelessWidget {
  const PaymentVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubscriptionStatusPanel(
      key: Key('subscription-verifying'),
      icon: Icons.sync_rounded,
      title: 'Checking subscription status',
      message: 'We are asking the backend whether Premium has been activated.',
      loading: true,
    );
  }
}

class ActiveSubscriptionView extends StatelessWidget {
  const ActiveSubscriptionView({
    super.key,
    required this.active,
    required this.onOpenLikes,
    required this.onRefresh,
  });

  final ActiveSubscription active;
  final VoidCallback onOpenLikes;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space20,
          AppTokens.space32,
          AppTokens.space20,
          AppTokens.space40,
        ),
        children: [
          _SolidSurface(
            borderColor: AppTokens.success.withValues(alpha: 0.55),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTokens.success.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 38,
                    color: AppTokens.success,
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
                Text(
                  'Premium is active',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTokens.space8),
                Text(
                  active.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTokens.space12),
                Text(
                  'Access until ${formatSubscriptionDate(active.endAt)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTokens.space24),
                PrimaryActionButton(
                  key: const Key('subscription-open-likes'),
                  label: 'Open Likes',
                  icon: Icons.favorite_rounded,
                  onPressed: onOpenLikes,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SubscriptionLoadingView extends StatelessWidget {
  const SubscriptionLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTokens.space16),
      children: const [
        SkeletonLoader(height: 190, radius: AppTokens.radiusLarge),
        SizedBox(height: AppTokens.space20),
        SkeletonLoader(height: 112, radius: AppTokens.radiusLarge),
        SizedBox(height: AppTokens.space12),
        SkeletonLoader(height: 112, radius: AppTokens.radiusLarge),
        SizedBox(height: AppTokens.space20),
        SkeletonLoader(height: AppTokens.standardButtonHeight, radius: 999),
      ],
    );
  }
}

class _CheckoutStatusContent extends StatelessWidget {
  const _CheckoutStatusContent({
    required this.state,
    required this.onReopenPayment,
    required this.onVerifyPayment,
  });

  final SubscriptionState state;
  final VoidCallback onReopenPayment;
  final VoidCallback onVerifyPayment;

  @override
  Widget build(BuildContext context) {
    return switch (state.checkoutStatus) {
      CheckoutStatus.idle => const SizedBox.shrink(),
      CheckoutStatus.creating => const SubscriptionStatusPanel(
        key: Key('subscription-creating-checkout'),
        icon: Icons.hourglass_top_rounded,
        title: 'Creating secure checkout',
        message: 'Please wait while the backend prepares the payment.',
        loading: true,
      ),
      CheckoutStatus.openingPayment => const SubscriptionStatusPanel(
        key: Key('subscription-opening-payment'),
        icon: Icons.open_in_new_rounded,
        title: 'Opening payment page',
        message: 'Complete the payment in the external bank page.',
        loading: true,
      ),
      CheckoutStatus.creationError => SubscriptionStatusPanel(
        key: const Key('subscription-checkout-error'),
        icon: Icons.error_outline_rounded,
        title: 'Could not create checkout',
        message: subscriptionErrorMessage(state.checkoutError),
        tone: SubscriptionStatusTone.error,
      ),
      CheckoutStatus.launchError => SubscriptionStatusPanel(
        key: const Key('subscription-launch-error'),
        icon: Icons.open_in_browser_rounded,
        title: 'Payment page did not open',
        message:
            'The existing checkout is safe to reopen. No second checkout will be created.',
        tone: SubscriptionStatusTone.error,
        actionLabel: 'Open payment page',
        onAction: onReopenPayment,
      ),
      CheckoutStatus.awaitingPayment => SubscriptionStatusPanel(
        key: const Key('subscription-awaiting-payment'),
        icon: Icons.open_in_new_rounded,
        title: 'Payment page opened',
        message:
            'Returning to the app is not proof of payment. Check the backend status when you are ready.',
        actionLabel: 'Check payment',
        onAction: onVerifyPayment,
      ),
      CheckoutStatus.verifying => const PaymentVerificationView(),
      CheckoutStatus.pending => SubscriptionStatusPanel(
        key: const Key('subscription-payment-pending'),
        icon: Icons.schedule_rounded,
        title: 'Payment is still pending',
        message:
            'Premium is not active yet. You can ask the backend to check again.',
        tone: SubscriptionStatusTone.warning,
        actionLabel: 'Check again',
        onAction: onVerifyPayment,
      ),
      CheckoutStatus.confirmed => const SubscriptionStatusPanel(
        key: Key('subscription-payment-confirmed'),
        icon: Icons.check_circle_rounded,
        title: 'Premium is active',
        message: 'The backend confirmed your active subscription.',
        tone: SubscriptionStatusTone.success,
      ),
      CheckoutStatus.failed => SubscriptionStatusPanel(
        key: const Key('subscription-payment-failed'),
        icon: Icons.error_outline_rounded,
        title: 'Payment failed',
        message:
            state.payment?.failureMessage ??
            'Premium was not activated. You can start a new checkout manually.',
        tone: SubscriptionStatusTone.error,
      ),
      CheckoutStatus.cancelled => const SubscriptionStatusPanel(
        key: Key('subscription-payment-cancelled'),
        icon: Icons.cancel_outlined,
        title: 'Payment was cancelled',
        message:
            'Premium was not activated. You can start a new checkout when ready.',
        tone: SubscriptionStatusTone.warning,
      ),
      CheckoutStatus.timedOut => SubscriptionStatusPanel(
        key: const Key('subscription-payment-timeout'),
        icon: Icons.schedule_rounded,
        title: 'Confirmation is taking longer',
        message:
            'Premium is not active yet. Check the same payment again without creating a new checkout.',
        tone: SubscriptionStatusTone.warning,
        actionLabel: 'Check again',
        onAction: onVerifyPayment,
      ),
      CheckoutStatus.verificationError => SubscriptionStatusPanel(
        key: const Key('subscription-verification-error'),
        icon: Icons.cloud_off_rounded,
        title: 'Could not verify payment',
        message:
            'We could not read the latest backend status. Premium remains locked until confirmation.',
        tone: SubscriptionStatusTone.error,
        actionLabel: 'Retry verification',
        onAction: onVerifyPayment,
      ),
    };
  }
}

class _DemoPaymentPanel extends StatelessWidget {
  const _DemoPaymentPanel({required this.busy, required this.onResult});

  final bool busy;
  final ValueChanged<bool> onResult;

  @override
  Widget build(BuildContext context) {
    return _SolidSurface(
      borderColor: AppTokens.success.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demo payment result',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTokens.space8),
          Text(
            'These controls send the result to the demo backend. They do not unlock Premium locally.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTokens.textSecondary),
          ),
          const SizedBox(height: AppTokens.space12),
          Wrap(
            spacing: AppTokens.space8,
            runSpacing: AppTokens.space8,
            children: [
              SecondaryActionButton(
                label: 'Demo failure',
                onPressed: busy ? null : () => onResult(false),
                expanded: false,
              ),
              SecondaryActionButton(
                label: 'Demo success',
                onPressed: busy ? null : () => onResult(true),
                expanded: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppTokens.minTouchTarget),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space12),
      decoration: BoxDecoration(
        color: AppTokens.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: AppTokens.success.withValues(alpha: 0.34)),
      ),
      child: Text(
        'Demo',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppTokens.success,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SolidSurface extends StatelessWidget {
  const _SolidSurface({required this.child, this.borderColor});

  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.space20),
      decoration: BoxDecoration(
        color: AppTokens.surfaceSolid,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(color: borderColor ?? AppTokens.glassBorder),
        boxShadow: AppTokens.surfaceShadow(),
      ),
      child: child,
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTokens.space20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - AppTokens.space40).clamp(
              0,
              double.infinity,
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

String subscriptionErrorMessage(Object? error) => error is ApiException
    ? error.message
    : error is FormatException
    ? 'The server returned an invalid subscription response.'
    : 'Could not complete the subscription request. Please try again.';

String formatSubscriptionPrice(int minor, String currency) {
  final negative = minor < 0;
  final absolute = minor.abs();
  final units = absolute ~/ 100;
  final cents = absolute % 100;
  final grouped = units.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '\u00A0',
  );
  final amount =
      '${negative ? '-' : ''}$grouped${cents == 0 ? '' : '.${cents.toString().padLeft(2, '0')}'}';
  return currency.toUpperCase() == 'RUB'
      ? '$amount\u00A0₽'
      : '$amount\u00A0${currency.toUpperCase()}';
}

String formatSubscriptionPeriod(int days) => days == 1 ? '1 day' : '$days days';

String formatSubscriptionDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
}
