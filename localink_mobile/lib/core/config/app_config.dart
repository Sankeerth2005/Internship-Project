class AppConfig {
  static const String geoapifyApiKey = String.fromEnvironment(
    'GEOAPIFY_API_KEY',
    defaultValue: '8850f08de04f408ea18d8c8942d90394',
  );
}
