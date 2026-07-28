// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrencyConversionResponse _$CurrencyConversionResponseFromJson(
  Map<String, dynamic> json,
) => CurrencyConversionResponse(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: json['data'] == null
      ? null
      : CurrencyConversionData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CurrencyConversionResponseToJson(
  CurrencyConversionResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

CurrencyConversionData _$CurrencyConversionDataFromJson(
  Map<String, dynamic> json,
) => CurrencyConversionData(
  amount: (json['amount'] as num).toDouble(),
  from: json['from'] as String,
  to: json['to'] as String,
);

Map<String, dynamic> _$CurrencyConversionDataToJson(
  CurrencyConversionData instance,
) => <String, dynamic>{
  'amount': instance.amount,
  'from': instance.from,
  'to': instance.to,
};

ExchangeRatesResponse _$ExchangeRatesResponseFromJson(
  Map<String, dynamic> json,
) => ExchangeRatesResponse(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: json['data'] == null
      ? null
      : ExchangeRatesData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ExchangeRatesResponseToJson(
  ExchangeRatesResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

ExchangeRatesData _$ExchangeRatesDataFromJson(Map<String, dynamic> json) =>
    ExchangeRatesData(
      baseCurrency: json['baseCurrency'] as String,
      rates: (json['rates'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
    );

Map<String, dynamic> _$ExchangeRatesDataToJson(ExchangeRatesData instance) =>
    <String, dynamic>{
      'baseCurrency': instance.baseCurrency,
      'rates': instance.rates,
    };
