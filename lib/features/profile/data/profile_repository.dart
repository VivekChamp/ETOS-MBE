import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/employee_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfileRepository(dio);
});

class ProfileRepository {
  final Dio _dio;
  // Use custom api to find the ID first is good, but dashboard already has it.
  // We assume we pass the EmployeeID to this repository.

  ProfileRepository(this._dio);

  Future<Employee> getEmployeeDetails(String employeeId) async {
    try {
      final response = await _dio.get('/api/resource/Employee/$employeeId');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return Employee.fromJson(data);
      } else {
        throw Exception('Failed to fetch employee details');
      }
    } catch (e) {
      throw Exception('Error fetching employee details: $e');
    }
  }
}
