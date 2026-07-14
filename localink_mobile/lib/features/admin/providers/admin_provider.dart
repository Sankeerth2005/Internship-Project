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
}

final adminBusinessesProvider = AsyncNotifierProvider<AdminNotifier, List<AdminBusinessDto>>(
  AdminNotifier.new,
);
