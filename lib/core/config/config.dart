enum AppEnvironment {
  demo,
  development,
  production;

  static AppEnvironment parse(String value) {
    return switch (value.trim().toLowerCase()) {
      'demo' => AppEnvironment.demo,
      'development' || 'dev' => AppEnvironment.development,
      'production' || 'prod' => AppEnvironment.production,
      _ => throw ArgumentError.value(
        value,
        'APP_ENV',
        'Unsupported environment',
      ),
    };
  }
}

class EnvironmentConfig {
  const EnvironmentConfig({
    required this.environment,
    required this.restApiUrl,
    required this.socketIoUrl,
    required this.demoMode,
  });

  final AppEnvironment environment;
  final String restApiUrl;
  final String socketIoUrl;
  final bool demoMode;

  static EnvironmentConfig resolve({
    required String environment,
    String restApiUrl = '',
    String socketIoUrl = '',
    String demoMode = '',
  }) {
    final parsedEnvironment = AppEnvironment.parse(environment);
    final defaultRestApiUrl = switch (parsedEnvironment) {
      AppEnvironment.demo ||
      AppEnvironment.development => 'http://10.0.2.2:1024',
      AppEnvironment.production => '',
    };
    final defaultSocketIoUrl = switch (parsedEnvironment) {
      AppEnvironment.demo ||
      AppEnvironment.development => 'http://10.0.2.2:1025',
      AppEnvironment.production => '',
    };
    final resolvedRestUrl = _normalizeUrl(
      restApiUrl.isEmpty ? defaultRestApiUrl : restApiUrl,
      'REST_API_URL',
    );
    final resolvedSocketUrl = _normalizeUrl(
      socketIoUrl.isEmpty ? defaultSocketIoUrl : socketIoUrl,
      'SOCKET_IO_URL',
    );
    final resolvedDemoMode = demoMode.isEmpty
        ? parsedEnvironment == AppEnvironment.demo
        : _parseBool(demoMode);

    if (parsedEnvironment == AppEnvironment.production) {
      _rejectLocalUrl(resolvedRestUrl, 'REST_API_URL');
      _rejectLocalUrl(resolvedSocketUrl, 'SOCKET_IO_URL');
      if (resolvedDemoMode) {
        throw StateError('DEMO_MODE cannot be enabled in production');
      }
    }

    return EnvironmentConfig(
      environment: parsedEnvironment,
      restApiUrl: resolvedRestUrl,
      socketIoUrl: resolvedSocketUrl,
      demoMode: resolvedDemoMode,
    );
  }

  static String _normalizeUrl(String value, String name) {
    final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(normalized);
    if (normalized.isEmpty ||
        uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw StateError('$name must be an absolute HTTP(S) URL');
    }
    return normalized;
  }

  static bool _parseBool(String value) {
    return switch (value.trim().toLowerCase()) {
      'true' => true,
      'false' => false,
      _ => throw ArgumentError.value(
        value,
        'DEMO_MODE',
        'Expected true or false',
      ),
    };
  }

  static void _rejectLocalUrl(String value, String name) {
    final host = Uri.parse(value).host.toLowerCase();
    if (host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '::1' ||
        host == '10.0.2.2') {
      throw StateError('$name cannot point to a local host in production');
    }
  }
}

class AppConfig {
  AppConfig._();

  static const _environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
  static const _restApiUrl = String.fromEnvironment('REST_API_URL');
  static const _socketIoUrl = String.fromEnvironment('SOCKET_IO_URL');
  static const _demoMode = String.fromEnvironment('DEMO_MODE');

  static final EnvironmentConfig current = EnvironmentConfig.resolve(
    environment: _environment,
    restApiUrl: _restApiUrl,
    socketIoUrl: _socketIoUrl,
    demoMode: _demoMode,
  );

  // Existing network code keeps these accessors; all values now come from the
  // centralized environment configuration above.
  static String get baseAppUrl => current.restApiUrl;
  static String get baseAppSocketUrl => current.socketIoUrl;
  static bool get isDemoMode => current.demoMode;
  static AppEnvironment get environment => current.environment;
}
