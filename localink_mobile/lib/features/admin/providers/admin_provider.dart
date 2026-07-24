import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/admin_business_dto.dart';
import '../data/repositories/admin_repository.dart';

class AdminNotifier extends AsyncNotifier<List<AdminBusinessDto>> {
  @override
  Future<List<AdminBusinessDto>> build() async {
    return _fetch();
  }

  Future<List<AdminBusinessDto>> _fetch() async {
    final repo = ref.read(adminRepositoryProvider);
    return await repo.getAdminBusinesses();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  // Approve business (Status Enum Val: 2)
  Future<bool> approveBusiness(int id) async {
    final repo = ref.read(adminRepositoryProvider);
    try {
      final success = await repo.updateStatus(id, 2, null);
      if (success) {
        await refresh();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  // Reject business (Status Enum Val: 3)
  Future<bool> rejectBusiness(int id, String reason) async {
    final repo = ref.read(adminRepositoryProvider);
    try {
      final success = await repo.updateStatus(id, 3, reason);
      if (success) {
        await refresh();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  // Approve Temporary Closure
  Future<bool> approveTemporaryClosure(int id) async {
    final repo = ref.read(adminRepositoryProvider);
    try {
      final success = await repo.approveTemporaryClosure(id);
      if (success) {
        await refresh();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  // Reject Temporary Closure
  Future<bool> rejectTemporaryClosure(int id) async {
    final repo = ref.read(adminRepositoryProvider);
    try {
      final success = await repo.rejectTemporaryClosure(id);
      if (success) {
        await refresh();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  // Approve Permanent Deletion
  Future<bool> approvePermanentDeletion(int id) async {
    final repo = ref.read(adminRepositoryProvider);
    try {
      final success = await repo.approvePermanentDeletion(id);
      if (success) {
        await refresh();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  // Unflag Review
  Future<bool> unflagReview(int id) async {
    final repo = ref.read(adminRepositoryProvider);
    try {
      return await repo.unflagReview(id);
    } catch (e) {
      return false;
    }
  }

  // Delete Review
  Future<bool> deleteReview(int id) async {
    final repo = ref.read(adminRepositoryProvider);
    try {
      return await repo.deleteReview(id);
    } catch (e) {
      return false;
    }
  }

  // Upload Bulk Import
  Future<Map<String, dynamic>> uploadBulkImport(String filePath) async {
    final repo = ref.read(adminRepositoryProvider);
    try {
      return await repo.uploadBulkImport(filePath);
    } catch (e) {
      return {'success': false, 'message': 'Upload failed: $e'};
    }
  }
}

final adminBusinessesProvider = AsyncNotifierProvider<AdminNotifier, List<AdminBusinessDto>>(
  AdminNotifier.new,
);

final adminStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getAdminStats();
});

final adminFlaggedReviewsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getFlaggedReviews();
});

final adminUsersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getAdminUsers();
});
