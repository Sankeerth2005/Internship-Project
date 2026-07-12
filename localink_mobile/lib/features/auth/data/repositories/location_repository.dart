import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/location_models.dart';

class LocationRepository {
  final Dio dio;
  
  // Cache variables
  List<Country>? _cachedCountries;
  final Map<String, List<StateModel>> _cachedStates = {};
  final Map<String, List<CityModel>> _cachedCities = {};

  LocationRepository({required this.dio});

  Future<List<Country>> getCountries() async {
    if (_cachedCountries != null) return _cachedCountries!;
    try {
      final response = await dio.get('location/countries');
      final data = response.data;
      final List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is String) {
        list = jsonDecode(data) as List;
      } else {
        throw Exception('Unexpected response format: ${data.runtimeType}');
      }
      _cachedCountries = list.map((json) => Country.fromJson(json as Map<String, dynamic>)).toList();
      return _cachedCountries!;
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to load countries');
    }
  }

  Future<List<StateModel>> getStates(String countryIso2) async {
    if (_cachedStates.containsKey(countryIso2)) return _cachedStates[countryIso2]!;
    try {
      final response = await dio.get('location/states/$countryIso2');
      final data = response.data;
      final List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is String) {
        list = jsonDecode(data) as List;
      } else {
        throw Exception('Unexpected response format: ${data.runtimeType}');
      }
      _cachedStates[countryIso2] = list.map((json) => StateModel.fromJson(json as Map<String, dynamic>)).toList();
      return _cachedStates[countryIso2]!;
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to load states');
    }
  }

  Future<List<CityModel>> getCities(
    String countryIso2,
    String stateIso2,
  ) async {
    final cacheKey = '${countryIso2}_$stateIso2';
    if (_cachedCities.containsKey(cacheKey)) return _cachedCities[cacheKey]!;
    try {
      final response = await dio.get(
        'location/cities/$countryIso2/$stateIso2',
      );
      final data = response.data;
      final List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is String) {
        list = jsonDecode(data) as List;
      } else {
        throw Exception('Unexpected response format: ${data.runtimeType}');
      }
      _cachedCities[cacheKey] = list.map((json) => CityModel.fromJson(json as Map<String, dynamic>)).toList();
      return _cachedCities[cacheKey]!;
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to load cities');
    }
  }

  Future<PincodeValidationResponse> validatePincode(String postcode) async {
    try {
      final response = await dio.get(
        'BusinessPincode/validate',
        queryParameters: {'postcode': postcode},
      );
      final data = response.data;
      if (data is String) {
        return PincodeValidationResponse.fromJson(jsonDecode(data) as Map<String, dynamic>);
      }
      return PincodeValidationResponse.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to validate pincode');
    }
  }
}
