import 'package:dio/dio.dart';
import '../models/referral_impact.dart';

class ReferralRepository {
  final Dio dio;

  ReferralRepository({required this.dio});

  Future<ReferralImpact> getMyImpact() async {
    try {
      final response = await dio.get('referral/me');
      final body = response.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        return ReferralImpact.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      throw Exception(
        (body is Map ? body['message'] : null)?.toString() ??
            'Failed to load referral impact',
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message'].toString());
      }
      throw Exception(e.message ?? 'Network error loading referral impact');
    }
  }
}
