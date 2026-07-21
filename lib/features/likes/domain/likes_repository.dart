import '../../../core/network/api_client.dart';
import 'likes_models.dart';

abstract interface class LikesRepository {
  Future<LikesData> getLikes();
}

class DioLikesRepository implements LikesRepository {
  DioLikesRepository(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<LikesData> getLikes() async {
    final responses = await Future.wait([
      _apiClient.get<List<dynamic>>('/likes/liked_me'),
      _apiClient.get<List<dynamic>>('/likes/liked_users'),
      _apiClient.get<List<dynamic>>('/likes/favorites'),
    ]);
    final likedMe = _parseUnique(responses[0].data);
    final likedUsers = _parseUnique(responses[1].data);
    final favorites = _parseUnique(responses[2].data);
    final mutualById = <int, LikesUser>{};
    for (final user in [...likedMe, ...likedUsers]) {
      if (user.mutual) mutualById[user.id] = user;
    }
    return LikesData(
      likedMe: likedMe,
      likedUsers: likedUsers,
      favorites: favorites,
      mutual: mutualById.values.toList(),
    );
  }

  List<LikesUser> _parseUnique(List<dynamic>? raw) {
    final byId = <int, LikesUser>{};
    for (final item in raw ?? const []) {
      if (item is Map<String, dynamic>) {
        final user = LikesUser.fromJson(item);
        byId[user.id] = user;
      }
    }
    return byId.values.toList();
  }
}
