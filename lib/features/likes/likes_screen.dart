import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/config/config.dart';
import '../../core/network/api_exception.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';
import 'application/likes_providers.dart';
import 'domain/likes_models.dart';

class LikesScreen extends ConsumerStatefulWidget {
  const LikesScreen({super.key});

  @override
  ConsumerState<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends ConsumerState<LikesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(ref.read(likesControllerProvider.notifier).load);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(likesControllerProvider);
    return Scaffold(
      body: AppGradientScaffold(
        child: Column(
          children: [
            Padding(
              padding: AppTokens.screenPadding,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(Routes.discover),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Text('Likes', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegmentedButton<LikesCategory>(
                segments: const [
                  ButtonSegment(
                    value: LikesCategory.likedMe,
                    label: Text('Liked me'),
                  ),
                  ButtonSegment(
                    value: LikesCategory.likedUsers,
                    label: Text('My likes'),
                  ),
                  ButtonSegment(
                    value: LikesCategory.favorites,
                    label: Text('Favorites'),
                  ),
                  ButtonSegment(
                    value: LikesCategory.mutual,
                    label: Text('Matches'),
                  ),
                ],
                selected: {state.category},
                onSelectionChanged: (selection) => ref
                    .read(likesControllerProvider.notifier)
                    .select(selection.first),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _content(state)),
          ],
        ),
      ),
    );
  }

  Widget _content(LikesState state) {
    if (state.status == LikesStatus.loading && state.data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == LikesStatus.error && state.data == null) {
      return _LikesMessage(
        message: _errorMessage(state.error),
        onRetry: _reload,
      );
    }
    if (state.visible.isEmpty) {
      return _LikesMessage(message: 'Nothing here yet', onRetry: _reload);
    }
    return RefreshIndicator(
      onRefresh: ref.read(likesControllerProvider.notifier).load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.visible.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, index) => _LikesTile(user: state.visible[index]),
      ),
    );
  }

  Future<void> _reload() => ref.read(likesControllerProvider.notifier).load();

  String _errorMessage(Object? error) => error is ApiException
      ? error.message
      : 'Could not load likes. Please try again.';
}

class _LikesTile extends StatelessWidget {
  const _LikesTile({required this.user});
  final LikesUser user;

  @override
  Widget build(BuildContext context) {
    final age = user.age;
    return GlassSurface(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.avatarUrl == null
              ? null
              : NetworkImage(_mediaUrl(user.avatarUrl!)),
          child: user.avatarUrl == null ? const Icon(Icons.person) : null,
        ),
        title: Text(
          [user.firstName, if (age != null) '$age'].join(', '),
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          [
            user.city,
            user.aboutMe,
          ].where((value) => value.isNotEmpty).join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          user.mutual ? Icons.favorite : Icons.favorite_border,
          color: AppTokens.pinkSoft,
        ),
      ),
    );
  }
}

class _LikesMessage extends StatelessWidget {
  const _LikesMessage({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: 10),
        TextButton(onPressed: onRetry, child: const Text('Reload')),
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
