import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(dio: DioClient().dio);
});

final userProfileProvider = FutureProvider<UserProfileDto>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return await repo.getProfile();
});
