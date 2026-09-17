import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../data/models/share_models.dart';
import '../data/repositories/share_repository.dart';

final shareRepositoryProvider = Provider<ShareRepository>((ref) {
  return ShareRepository(dio: DioClient().dio);
});

final shareViewProvider = FutureProvider.autoDispose
    .family<BusinessShareView, String>((ref, publicToken) async {
  return ref.watch(shareRepositoryProvider).getShare(publicToken);
});
