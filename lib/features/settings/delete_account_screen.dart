import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/network/api_exception.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/midnight_components.dart';
import 'application/settings_providers.dart';
import 'domain/settings_models.dart';
import 'presentation/settings_components.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(ref.read(deleteAccountControllerProvider.notifier).reset);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deleteAccountControllerProvider);
    return PopScope(
      canPop: !state.isDeleting,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && state.isDeleting) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wait for account deletion to finish'),
            ),
          );
        }
      },
      child: SettingsPageScaffold(
        title: 'Delete account',
        onBack: state.isDeleting ? () {} : _back,
        child: state.isDeleting
            ? const Center(
                key: Key('delete-account-progress'),
                child: Padding(
                  padding: EdgeInsets.all(AppTokens.space32),
                  child: DeleteAccountProgressView(),
                ),
              )
            : ListView(
                key: const Key('delete-account-warning'),
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space20,
                  104,
                  AppTokens.space20,
                  AppTokens.space40,
                ),
                children: [
                  _DeletionWarning(),
                  if (state.status == DeleteAccountStatus.error) ...[
                    const SizedBox(height: AppTokens.space16),
                    SettingsInlineMessage(
                      key: const Key('delete-account-error'),
                      message: _deleteErrorMessage(state.error),
                      isError: true,
                    ),
                  ],
                  const SizedBox(height: AppTokens.space24),
                  FilledButton.icon(
                    key: const Key('delete-account-continue'),
                    onPressed: _requestDeletion,
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: Text(
                      state.status == DeleteAccountStatus.error
                          ? 'Review and retry deletion'
                          : 'Continue to final confirmation',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTokens.error,
                      foregroundColor: AppTokens.backgroundBase,
                      minimumSize: const Size.fromHeight(
                        AppTokens.standardButtonHeight,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.space8),
                  SecondaryActionButton(
                    label: 'Keep my account',
                    onPressed: _back,
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _requestDeletion() async {
    final state = ref.read(deleteAccountControllerProvider);
    if (state.isDeleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DeleteAccountConfirmation(),
    );
    if (confirmed != true || !mounted) return;
    final deleted = await ref
        .read(deleteAccountControllerProvider.notifier)
        .deleteAccount();
    if (!mounted || !deleted) return;
    context.go(Routes.welcome);
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.accountSettings);
    }
  }
}

class _DeletionWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          'Permanent action. The backend marks this account deleted and '
          'disconnects it from existing chats. Swipe has no restore flow.',
      child: Container(
        padding: const EdgeInsets.all(AppTokens.space20),
        decoration: BoxDecoration(
          color: AppTokens.surfaceSolid,
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          border: Border.all(color: AppTokens.error.withValues(alpha: 0.44)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppTokens.error,
              size: AppTokens.iconProminent,
            ),
            const SizedBox(height: AppTokens.space12),
            Text(
              'Permanent account deletion',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTokens.space12),
            const Text(
              'The backend will mark this account deleted and disconnect it '
              'from existing chats.',
            ),
            const SizedBox(height: AppTokens.space8),
            const Text(
              'Chat and message records may be retained. The current API does '
              'not confirm subscription cancellation or provide an account '
              'restore flow.',
              style: TextStyle(color: AppTokens.textSecondary),
            ),
            const SizedBox(height: AppTokens.space8),
            const Text(
              'Your private session data is removed from this device only '
              'after the backend confirms deletion.',
              style: TextStyle(color: AppTokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

String _deleteErrorMessage(Object? error) {
  if (error is NetworkApiException) {
    return 'Swipe could not reach the server. Your account is still active '
        'and your draft session was kept.';
  }
  if (error is UnauthorizedApiException) {
    return 'Your session could not authorize this deletion. The account was '
        'not treated as deleted.';
  }
  if (error is ApiException) {
    return 'The server did not confirm account deletion. Your account and '
        'local session remain active.';
  }
  return 'Account deletion did not finish. Your account and local session '
      'remain active.';
}
