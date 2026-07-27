class AppPackageInfo {
  const AppPackageInfo({
    required this.appName,
    required this.version,
    required this.buildNumber,
  });

  final String appName;
  final String version;
  final String buildNumber;

  factory AppPackageInfo.fromPlatform(Map<Object?, Object?> value) {
    String requiredString(String key) {
      final raw = value[key];
      if (raw is String && raw.trim().isNotEmpty) return raw.trim();
      throw FormatException('Missing package field: $key');
    }

    return AppPackageInfo(
      appName: requiredString('appName'),
      version: requiredString('version'),
      buildNumber: requiredString('buildNumber'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppPackageInfo &&
      other.appName == appName &&
      other.version == version &&
      other.buildNumber == buildNumber;

  @override
  int get hashCode => Object.hash(appName, version, buildNumber);
}

enum AppInformationStatus { initial, loading, data, error }

class AppInformationState {
  const AppInformationState({
    this.status = AppInformationStatus.initial,
    this.packageInfo,
    this.error,
  });

  final AppInformationStatus status;
  final AppPackageInfo? packageInfo;
  final Object? error;
}

enum DeleteAccountStatus { initial, deleting, error, deleted }

class DeleteAccountState {
  const DeleteAccountState({
    this.status = DeleteAccountStatus.initial,
    this.error,
  });

  final DeleteAccountStatus status;
  final Object? error;

  bool get isDeleting => status == DeleteAccountStatus.deleting;
}
