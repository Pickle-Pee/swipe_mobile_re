import '../../../core/network/api_client.dart';
import 'profile_models.dart';

abstract interface class PublicProfileRepository {
  Future<PublicUserProfile> getProfile(int userId);
}

class DioPublicProfileRepository implements PublicProfileRepository {
  DioPublicProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<PublicUserProfile> getProfile(int userId) async {
    final responses = await Future.wait([
      _apiClient.get<Map<String, dynamic>>('/user/$userId'),
      _apiClient.get<Map<String, dynamic>>('/user/user/photos/$userId'),
    ]);
    final details = responses[0].data;
    if (details == null) {
      throw const FormatException('Empty public profile response');
    }
    final rawPhotos =
        responses[1].data?['photos'] as List<dynamic>? ?? const [];
    final photos = rawPhotos
        .whereType<Map<String, dynamic>>()
        .map(ProfilePhoto.fromJson)
        .toList(growable: false);
    return PublicUserProfile.fromJson(details, photos: photos);
  }
}
