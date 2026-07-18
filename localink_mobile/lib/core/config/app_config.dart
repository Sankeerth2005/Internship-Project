class AppConfig {
  static const String geoapifyApiKey = String.fromEnvironment(
    'GEOAPIFY_API_KEY',
    defaultValue: 'feb3435b6a114f87a463088cd085394d',
  );
}
