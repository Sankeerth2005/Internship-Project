import 'package:dio/dio.dart';
import '../models/currency_models.dart';
import '../../../../core/network/dio_client.dart';

class CurrencyRepository {
  final Dio dio;

  CurrencyRepository({required this.dio});

  Future<CurrencyConversionResponse> convertCurrency(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    try {
      final response = await dio.get(
        'currency/convert',
        queryParameters: {
          'amount': amount,
          'from': fromCurrency,
          'to': toCurrency,
        },
      );

      if (response.data['success'] == true) {
        return CurrencyConversionResponse.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Currency conversion failed');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<ExchangeRatesResponse> getExchangeRates(String baseCurrency) async {
    try {
      final response = await dio.get(
        'currency/rates',
        queryParameters: {
          'baseCurrency': baseCurrency,
        },
      );

      if (response.data['success'] == true) {
        return ExchangeRatesResponse.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get exchange rates');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  String _handleDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final msg = data['message']?.toString();
      if (msg != null && msg.isNotEmpty && msg != "Something went wrong") return msg;
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your internet connection.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
