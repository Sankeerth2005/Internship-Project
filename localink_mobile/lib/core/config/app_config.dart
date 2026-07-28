class AppConfig {
  static String get geoapifyApiKey => const String.fromEnvironment(
    'GEOAPIFY_API_KEY',
    defaultValue: '26ff7eefc12b41da90c9ef7084f08c15',
  );
  
  static String get currencyApiKey => const String.fromEnvironment(
    'CURRENCY_API_KEY',
    defaultValue: 'apv_5ac90720-8e15-494a-9e6c-2a16599017d3',
  );
  
  static bool get isConfigured => geoapifyApiKey.isNotEmpty && currencyApiKey.isNotEmpty;
}
