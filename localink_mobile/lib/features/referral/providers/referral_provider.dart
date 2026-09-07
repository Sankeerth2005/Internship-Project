import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../data/models/referral_impact.dart';
import '../data/repositories/referral_repository.dart';

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  return ReferralRepository(dio: DioClient().dio);
});

final referralImpactProvider =
    FutureProvider.autoDispose<ReferralImpact>((ref) async {
  return ref.watch(referralRepositoryProvider).getMyImpact();
});
