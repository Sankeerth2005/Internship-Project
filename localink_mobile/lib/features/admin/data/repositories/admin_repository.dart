import 'package:dio/dio.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/network/dio_client.dart';
import '../models/admin_business_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminRepository {
  final Dio dio;

  AdminRepository({required this.dio});

  Future<Options> _getAuthOptions() async {
    final token = await SecureStorageService.getToken();
    return Options(
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  // GET ALL BUSINESSES FOR ADMIN
  Future<List<AdminBusinessDto>> getAdminBusinesses() async {
    final options = await _getAuthOptions();
    final response = await dio.get(
      'admin/businesses',
      options: options,
    );
    final list = response.data as List? ?? [];
    return list.map((e) => AdminBusinessDto.fromJson(e)).toList();
  }

  // UPDATE BUSINESS STATUS
  Future<bool> updateStatus(int id, int statusEnumVal, String? rejectionReason) async {
    final options = await _getAuthOptions();
    final response = await dio.put(
      'admin/business/$id/status',
      data: {
        'status': statusEnumVal, // 0 = Pending, 1 = Approved, 2 = Rejected
        'rejectionReason': rejectionReason,
      },
      options: options,
    );
    return response.statusCode == 200;
  }

  // APPROVE TEMPORARY CLOSURE
  Future<bool> approveTemporaryClosure(int id) async {
    final options = await _getAuthOptions();
    final response = await dio.put(
      'admin/business/$id/temporary-closure/approve',
      options: options,
    );
    return response.statusCode == 200;
  }

  // REJECT TEMPORARY CLOSURE
  Future<bool> rejectTemporaryClosure(int id) async {
    final options = await _getAuthOptions();
    final response = await dio.put(
      'admin/business/$id/temporary-closure/reject',
      options: options,
    );
    return response.statusCode == 200;
  }

  // APPROVE PERMANENT DELETION
  Future<bool> approvePermanentDeletion(int id) async {
    final options = await _getAuthOptions();
    final response = await dio.delete(
      'admin/business/$id/delete',
      options: options,
    );
    return response.statusCode == 200;
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(dio: DioClient().dio);
});
