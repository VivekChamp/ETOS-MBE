import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/project_model.dart';
import 'dart:developer';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ProjectRepository(dio);
});

class ProjectRepository {
  final Dio _dio;

  ProjectRepository(this._dio);

  Future<List<Project>> getProjects({
    String? searchText,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final response = await _dio.get(
        '/api/method/etos_mbe.etos_mbe.api.get_project_names',
        queryParameters: {
          if (searchText != null && searchText.isNotEmpty)
            'search_text': searchText,
          if (status != null && status != 'All') 'status': status,
          if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
          if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
        },
      );

      if (response.statusCode == 200) {
        log('🔵 [PROJECTS] Raw response: ${response.data}');

        final data = response.data;

        // Handle new API structure with message wrapper
        if (data['message'] != null) {
          final message = data['message'];
          if (message['status'] == 'success' && message['projects'] != null) {
            final List projectsList = message['projects'];
            log(
              '🟢 [PROJECTS] Found ${projectsList.length} projects (filters applied)',
            );
            return projectsList.map((e) => Project.fromJson(e)).toList();
          }
        }

        // Fallback for old structure
        if (data['status'] == 'success' && data['projects'] != null) {
          final List projectsList = data['projects'];
          return projectsList.map((e) => Project.fromJson(e)).toList();
        }

        log('⚠️ [PROJECTS] No projects in response');
        return [];
      } else {
        throw Exception('Failed to fetch projects');
      }
    } catch (e) {
      log("🔴 [PROJECTS] Error fetching projects: $e");
      throw Exception('Error fetching projects: $e');
    }
  }

  Future<Map<String, dynamic>> getProjectDetails(String id) async {
    try {
      final response = await _dio.get('/api/resource/Project/$id');
      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('Failed to load project details');
      }
    } catch (e) {
      throw Exception('Error fetching project details: $e');
    }
  }
}
