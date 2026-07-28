import 'package:json_annotation/json_annotation.dart';

part 'currency_models.g.dart';

@JsonSerializable()
class CurrencyConversionResponse {
  final bool success;
  final String? message;
  final CurrencyConversionData? data;

  CurrencyConversionResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory CurrencyConversionResponse.fromJson(Map<String, dynamic> json) =>
      _$CurrencyConversionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CurrencyConversionResponseToJson(this);
}

@JsonSerializable()
class CurrencyConversionData {
  final double amount;
  final String from;
  final String to;

  CurrencyConversionData({
    required this.amount,
    required this.from,
    required this.to,
  });

  factory CurrencyConversionData.fromJson(Map<String, dynamic> json) =>
      _$CurrencyConversionDataFromJson(json);

  Map<String, dynamic> toJson() => _$CurrencyConversionDataToJson(this);
}

@JsonSerializable()
class ExchangeRatesResponse {
  final bool success;
  final String? message;
  final ExchangeRatesData? data;

  ExchangeRatesResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ExchangeRatesResponse.fromJson(Map<String, dynamic> json) =>
      _$ExchangeRatesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ExchangeRatesResponseToJson(this);
}

@JsonSerializable()
class ExchangeRatesData {
  final String baseCurrency;
  final Map<String, double> rates;

  ExchangeRatesData({
    required this.baseCurrency,
    required this.rates,
  });

  factory ExchangeRatesData.fromJson(Map<String, dynamic> json) =>
      _$ExchangeRatesDataFromJson(json);

  Map<String, dynamic> toJson() => _$ExchangeRatesDataToJson(this);
}
