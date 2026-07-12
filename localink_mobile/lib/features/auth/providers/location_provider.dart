import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/repositories/location_repository.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(dio: DioClient().dio);
});
