import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/currency_repository.dart';
import '../../../../core/network/dio_client.dart';

final currencyRepositoryProvider = Provider<CurrencyRepository>((ref) {
  return CurrencyRepository(dio: DioClient().dio);
});

class ConversionState {
  final bool isLoading;
  final double? convertedAmount;
  final String? errorMessage;

  const ConversionState({
    this.isLoading = false,
    this.convertedAmount,
    this.errorMessage,
  });

  ConversionState copyWith({
    bool? isLoading,
    double? convertedAmount,
    String? errorMessage,
  }) {
    return ConversionState(
      isLoading: isLoading ?? this.isLoading,
      convertedAmount: convertedAmount ?? this.convertedAmount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CurrencyNotifier extends Notifier<ConversionState> {
  @override
  ConversionState build() {
    return const ConversionState();
  }

  CurrencyRepository get _repository => CurrencyRepository(dio: DioClient().dio);

  Future<void> convertCurrency(double amount, String from, String to) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final response = await _repository.convertCurrency(amount, from, to);
      if (response.success && response.data != null) {
        state = state.copyWith(
          isLoading: false,
          convertedAmount: response.data!.amount,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message ?? 'Conversion failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const ConversionState();
  }
}

final currencyConverterProvider =
    NotifierProvider<CurrencyNotifier, ConversionState>(CurrencyNotifier.new);
