class AppConfig {
  static const baseAppUrl = String.fromEnvironment(
    'BASE_APP_URL',
    defaultValue: 'https://example.com',
  );

  static const baseAppSocketUrl = String.fromEnvironment(
    'BASE_APP_SOCKET_URL',
    defaultValue: 'https://example.com',
  );
}
