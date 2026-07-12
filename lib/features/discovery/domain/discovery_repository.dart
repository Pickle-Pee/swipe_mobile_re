import '../../../core/network/api_client.dart';
import 'discovery_models.dart';

abstract interface class DiscoveryRepository {
  Future<List<DiscoveryProfile>> getProfiles();
  Future<DiscoveryReactionResult> react(
    int profileId,
    DiscoveryReaction reaction,
  );
}

class DioDiscoveryRepository implements DiscoveryRepository {
  DioDiscoveryRepository(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<List<DiscoveryProfile>> getProfiles() async {
    final response =
        await _apiClient.get<List<dynamic>>('/match/find_matches');
    final matches = response.data ?? const [];
    return Future.wait(
      matches.whereType<Map<String, dynamic>>().map((match) async {
        final id = match['user_id'] as int;
        final details =
            await _apiClient.get<Map<String, dynamic>>('/user/$id');
        return DiscoveryProfile.fromJson(match, details.data ?? const {});
      }),
    );
  }

  @override
  Future<DiscoveryReactionResult> react(
    int profileId,
    DiscoveryReaction reaction,
  ) async {
    final action = reaction == DiscoveryReaction.like ? 'like' : 'dislike';
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/likes/$action/$profileId',
    );
    return DiscoveryReactionResult(
      isMatch: response.data?['message'] == "It's a match!",
    );
  }
}
