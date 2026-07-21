import 'package:flutter_riverpod/flutter_riverpod.dart';

export '../../features/auth/application/auth_providers.dart';

// TODO: Replace these stubs with real implementations from your moved data layer.
// The purpose is to create stable provider entry-points that UI can depend on.

final userRepositoryProvider = Provider<dynamic>((ref) {
  // return UserRepository(api: ref.watch(apiClientProvider));
  return null;
});

final chatRepositoryProvider = Provider<dynamic>((ref) {
  // return ChatRepository(api: ref.watch(apiClientProvider));
  return null;
});

final discoveryRepositoryProvider = Provider<dynamic>((ref) {
  // return DiscoveryRepository(api: ref.watch(apiClientProvider));
  return null;
});

final subscriptionRepositoryProvider = Provider<dynamic>((ref) {
  // return SubscriptionRepository(api: ref.watch(apiClientProvider));
  return null;
});
