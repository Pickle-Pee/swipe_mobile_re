import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/core/config/config.dart';

void main() {
  group('EnvironmentConfig', () {
    test('demo uses Android emulator defaults and enables demo mode', () {
      final config = EnvironmentConfig.resolve(environment: 'demo');

      expect(config.environment, AppEnvironment.demo);
      expect(config.restApiUrl, 'http://10.0.2.2:8000');
      expect(config.socketIoUrl, 'http://10.0.2.2:8000');
      expect(config.demoMode, isTrue);
    });

    test('explicit URLs are normalized', () {
      final config = EnvironmentConfig.resolve(
        environment: 'development',
        restApiUrl: 'https://api.dev.example.test/',
        socketIoUrl: 'https://socket.dev.example.test///',
      );

      expect(config.restApiUrl, 'https://api.dev.example.test');
      expect(config.socketIoUrl, 'https://socket.dev.example.test');
      expect(config.demoMode, isFalse);
    });

    test('production requires explicit URLs', () {
      expect(
        () => EnvironmentConfig.resolve(environment: 'production'),
        throwsStateError,
      );
    });

    test('production rejects local URLs', () {
      expect(
        () => EnvironmentConfig.resolve(
          environment: 'production',
          restApiUrl: 'http://localhost:8000',
          socketIoUrl: 'https://socket.example.test',
        ),
        throwsStateError,
      );
    });

    test('production rejects demo mode', () {
      expect(
        () => EnvironmentConfig.resolve(
          environment: 'production',
          restApiUrl: 'https://api.example.test',
          socketIoUrl: 'https://socket.example.test',
          demoMode: 'true',
        ),
        throwsStateError,
      );
    });
  });
}
