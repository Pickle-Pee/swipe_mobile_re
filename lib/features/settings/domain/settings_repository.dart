import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import 'settings_models.dart';

abstract interface class SettingsRepository {
  Future<void> deleteAccount();
}

class DioSettingsRepository implements SettingsRepository {
  DioSettingsRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<void> deleteAccount() =>
      _apiClient.request<void>('/user/delete_user', method: 'DELETE');
}

abstract interface class AppInformationSource {
  Future<AppPackageInfo> load();
}

class PlatformAppInformationSource implements AppInformationSource {
  const PlatformAppInformationSource();

  static const _channel = MethodChannel(
    'com.example.swipe_mobile_re/app_information',
  );

  @override
  Future<AppPackageInfo> load() async {
    final value = await _channel.invokeMethod<Map<Object?, Object?>>(
      'getPackageInfo',
    );
    if (value == null) {
      throw const FormatException('Platform returned no package information');
    }
    return AppPackageInfo.fromPlatform(value);
  }
}
