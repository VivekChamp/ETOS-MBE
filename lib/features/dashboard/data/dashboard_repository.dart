import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return DashboardRepository(dio);
});

class DashboardRepository {
  final Dio _dio;
  // Using the same custom app path
  static const String _customApiPath = 'etos_mbe.etos_mbe.api';

  DashboardRepository(this._dio);

  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final response = await _dio.get(
        '/api/method/$_customApiPath.get_logged_in_user_info',
      );

      if (response.statusCode == 200) {
        if (response.data['message'] != null &&
            response.data['message']['status'] == 'success') {
          return response.data['message']['user'];
        }
        // Fallback or error
        throw Exception(
          response.data['message']?['message'] ?? 'Failed to get user info',
        );
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user info: $e');
    }
  }

  Future<List<dynamic>> getProjectNames() async {
    try {
      final response = await _dio.get(
        '/api/method/$_customApiPath.get_project_names',
      );
      if (response.statusCode == 200) {
        final data = response.data['message'];
        if (data['status'] == 'success') {
          return data['projects'];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _dio.get(
        '/api/method/$_customApiPath.get_dashboard_stats',
      );

      if (response.statusCode == 200) {
        final data = response.data['message'];
        if (data != null && data['status'] == 'success') {
          return data['data'];
        }
        throw Exception(data?['message'] ?? 'Failed to get stats');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching stats: $e');
    }
  }
}
