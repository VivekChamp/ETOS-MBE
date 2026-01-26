import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/task_model.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TaskRepository(dio);
});

class TaskRepository {
  final Dio _dio;

  TaskRepository(this._dio);

  Future<List<Task>> getTasks({
    String? searchText,
    String? status,
    String? priority,
  }) async {
    try {
      final response = await _dio.get(
        '/api/method/etos_mbe.etos_mbe.api.get_tasks',
        queryParameters: {
          if (searchText != null && searchText.isNotEmpty)
            'search_text': searchText,
          if (status != null && status != 'All') 'status': status,
          if (priority != null && priority != 'All') 'priority': priority,
        },
      );

      if (response.statusCode == 200) {
        final message = response.data['message'];
        if (message is Map && message.containsKey('data')) {
          final List data = message['data'];
          return data.map((e) => Task.fromJson(e)).toList();
        } else if (response.data['data'] != null) {
          if (response.data['message'] is Map) {
            final inner = response.data['message'];
            if (inner['data'] is List) {
              return (inner['data'] as List)
                  .map((e) => Task.fromJson(e))
                  .toList();
            }
          }
        }
        return [];
      } else {
        throw Exception('Failed to fetch tasks');
      }
    } catch (e) {
      throw Exception('Error fetching tasks: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getProjects() async {
    try {
      final response = await _dio.get(
        '/api/method/etos_mbe.etos_mbe.api.get_project_names',
      );
      if (response.statusCode == 200) {
        // Handle new API response structure with message wrapper
        final message = response.data['message'];
        if (message != null && message['projects'] != null) {
          return List<Map<String, dynamic>>.from(message['projects']);
        }
        // Fallback for old structure
        if (response.data['projects'] != null) {
          return List<Map<String, dynamic>>.from(response.data['projects']);
        }
        return [];
      } else {
        throw Exception('Failed to fetch projects');
      }
    } catch (e) {
      throw Exception('Error fetching projects: $e');
    }
  }

  Future<Map<String, dynamic>> getTaskDetails(String id) async {
    try {
      final response = await _dio.get('/api/resource/Task/$id');
      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('Failed to load task details');
      }
    } catch (e) {
      throw Exception('Error fetching task details: $e');
    }
  }

  Future<void> createTask(Map<String, dynamic> data) async {
    try {
      // Use custom API to handle creation + assignment
      final response = await _dio.post(
        '/api/method/etos_mbe.etos_mbe.api.create_task',
        data: {
          'subject': data['subject'],
          'description': data['description'],
          'date': data['exp_end_date'],
          'priority': data['priority'] ?? 'Medium',
          'assign_to': data['assign_to'], // List of emails
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create task');
      }

      final result = response.data['message'];
      if (result is Map && result['status'] == 'error') {
        throw Exception(result['message']);
      }
    } catch (e) {
      throw Exception('Error creating task: $e');
    }
  }

  Future<void> updateTaskStatus(String id, String status) async {
    try {
      await _dio.post(
        '/api/method/etos_mbe.etos_mbe.api.update_task_status',
        data: {'task_id': id, 'status': status},
      );
    } catch (e) {
      throw Exception('Error updating task status: $e');
    }
  }

  // Assignment Methods
  Future<List<Map<String, dynamic>>> getUsersForAssignment() async {
    try {
      final response = await _dio.get(
        '/api/method/etos_mbe.etos_mbe.api.get_users_for_assignment',
      );
      if (response.statusCode == 200) {
        final data = response.data['message'];
        if (data['status'] == 'success' && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Failed to fetch users');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  Future<Map<String, dynamic>> assignTask({
    required String taskId,
    required List<String> assignToUsers,
    String? completeBy,
    String? priority,
    String? comment,
  }) async {
    try {
      final response = await _dio.post(
        '/api/method/etos_mbe.etos_mbe.api.assign_task',
        data: {
          'task_id': taskId,
          'assign_to_users': assignToUsers,
          if (completeBy != null) 'complete_by': completeBy,
          if (priority != null) 'priority': priority,
          if (comment != null) 'comment': comment,
        },
      );
      if (response.statusCode == 200) {
        return response.data['message'];
      } else {
        throw Exception('Failed to assign task');
      }
    } catch (e) {
      throw Exception('Error assigning task: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTaskAssignments(String taskId) async {
    try {
      final response = await _dio.get(
        '/api/method/etos_mbe.etos_mbe.api.get_task_assignments',
        queryParameters: {'task_id': taskId},
      );
      if (response.statusCode == 200) {
        final data = response.data['message'];
        if (data['status'] == 'success' && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Failed to fetch assignments');
      }
    } catch (e) {
      throw Exception('Error fetching assignments: $e');
    }
  }

  Future<void> unassignTask(String taskId, String userEmail) async {
    try {
      await _dio.post(
        '/api/method/etos_mbe.etos_mbe.api.unassign_task',
        data: {'task_id': taskId, 'user_email': userEmail},
      );
    } catch (e) {
      throw Exception('Error unassigning task: $e');
    }
  }
}
