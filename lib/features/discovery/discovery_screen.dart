import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/config/config.dart';
import '../../core/network/api_exception.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';
import 'application/discovery_providers.dart';
import 'domain/discovery_models.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(ref.read(discoveryControllerProvider.notifier).load);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoveryControllerProvider);
    final profile = state.current;
    return Scaffold(
      body: AppGradientScaffold(
        child: Column(
          children: [
            Padding(
              padding: AppTokens.screenPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discovery',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go(Routes.likes),
                        icon: const Icon(Icons.favorite_border),
                      ),
                      IconButton(
                        onPressed: () => context.go(Routes.chats),
                        icon: const Icon(Icons.chat_bubble_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: _body(state, profile)),
            if (profile != null)
              Padding(
                padding: AppTokens.screenPadding,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: state.isProcessing ? null : _pass,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTokens.border),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Pass'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        label: state.isProcessing ? 'Please wait…' : 'Like',
                        onPressed: state.isProcessing ? () {} : _like,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    label: 'Profile',
                    icon: Icons.person_outline,
                    onTap: () => context.go(Routes.profile),
                  ),
                  _NavItem(
                    label: 'Settings',
                    icon: Icons.settings_outlined,
                    onTap: () => context.go(Routes.settings),
                  ),
                  _NavItem(
                    label: 'Premium',
                    icon: Icons.workspace_premium_outlined,
                    onTap: () => context.go(Routes.premium),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(DiscoveryState state, DiscoveryProfile? profile) {
    if (state.status == DiscoveryStatus.loading && profile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == DiscoveryStatus.error && profile == null) {
      return _MessageState(
        message: _errorMessage(state.error),
        button: 'Try again',
        onPressed: _reload,
      );
    }
    if (profile == null) {
      return _MessageState(
        message: 'No more profiles right now',
        button: 'Reload profiles',
        onPressed: _reload,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Expanded(child: _ProfileCard(profile: profile)),
          if (state.status == DiscoveryStatus.error) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage(state.error),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  void _reload() => ref.read(discoveryControllerProvider.notifier).load();
  void _like() => ref.read(discoveryControllerProvider.notifier).like();
  void _pass() => ref.read(discoveryControllerProvider.notifier).pass();

  String _errorMessage(Object? error) => error is ApiException
      ? error.message
      : 'Could not complete the request. Please try again.';
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});
  final DiscoveryProfile profile;

  @override
  Widget build(BuildContext context) {
    final age = profile.age;
    return GlassSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: profile.photoUrl == null
                ? const DecoratedBox(
                    decoration: BoxDecoration(gradient: AppTokens.coolGradient),
                    child: Icon(Icons.person, size: 80, color: Colors.white70),
                  )
                : Image.network(
                    _mediaUrl(profile.photoUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const DecoratedBox(
                      decoration:
                          BoxDecoration(gradient: AppTokens.coolGradient),
                      child:
                          Icon(Icons.broken_image_outlined, size: 64),
                    ),
                  ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [profile.firstName, if (age != null) '$age'].join(', '),
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  if (profile.city.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(profile.city),
                  ],
                  if (profile.aboutMe.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(profile.aboutMe),
                  ],
                  if (profile.interests.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.interests
                          .map((item) => PillTag(label: item.label))
                          .toList(),
                    ),
                  ],
                  if (profile.attributes.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    ...profile.attributes.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('${entry.key}: ${entry.value}'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.message,
    required this.button,
    required this.onPressed,
  });
  final String message;
  final String button;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: onPressed, child: Text(button)),
          ],
        ),
      );
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTokens.textSecondary),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTokens.textSecondary,
              ),
            ),
          ],
        ),
      );
}

String _mediaUrl(String value) {
  final uri = Uri.parse(value);
  return uri.hasScheme
      ? uri.toString()
      : Uri.parse(AppConfig.baseAppUrl).resolve(value).toString();
}
