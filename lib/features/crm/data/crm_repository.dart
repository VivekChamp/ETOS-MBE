import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/lead_model.dart';
import 'dart:convert';

final crmRepositoryProvider = Provider<CRMRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CRMRepository(dio);
});

class CRMRepository {
  final Dio _dio;

  CRMRepository(this._dio);

  // FETCH LEADS -> Use Custom API for List (with filters)
  Future<List<Lead>> getLeads({
    String? searchText,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final response = await _dio.get(
        '/api/method/etos_mbe.etos_mbe.api.get_leads',
        queryParameters: {
          if (searchText != null && searchText.isNotEmpty)
            'search_text': searchText,
          if (status != null && status != 'All') 'status': status,
          if (fromDate != null) 'from_date': fromDate,
          if (toDate != null) 'to_date': toDate,
        },
      );

      if (response.statusCode == 200) {
        // Custom API returns {message: {status: success, leads: []}}
        final message = response.data['message'];
        if (message is Map) {
          if (message.containsKey('leads')) {
            final List data = message['leads'];
            return data.map((json) => Lead.fromJson(json)).toList();
          } else if (message.containsKey('data')) {
            final List data = message['data'];
            return data.map((json) => Lead.fromJson(json)).toList();
          }
        }
        return [];
      } else {
        throw Exception('Failed to fetch leads');
      }
    } catch (e) {
      throw Exception('Error fetching leads: $e');
    }
  }

  // CREATE LEAD -> Use Resource API (POST)
  Future<void> createLead(Map<String, dynamic> leadData) async {
    try {
      final response = await _dio.post('/api/resource/Lead', data: leadData);

      if (response.statusCode != 200) {
        throw Exception('Failed to create lead');
      }
    } catch (e) {
      throw Exception('Error creating lead: $e');
    }
  }

  // GET LEAD DETAILS -> Use Resource API
  Future<Map<String, dynamic>> getLeadDetails(String leadId) async {
    try {
      final response = await _dio.get('/api/resource/Lead/$leadId');

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('Failed to fetch lead details');
      }
    } catch (e) {
      throw Exception('Error fetching lead details: $e');
    }
  }

  // ASSIGN LEAD
  Future<Map<String, dynamic>> assignLead({
    required String leadId,
    required List<String> assignToUsers,
    String? completeBy,
    String? priority,
    String? comment,
  }) async {
    try {
      final response = await _dio.post(
        '/api/method/etos_mbe.etos_mbe.api.assign_lead',
        data: {
          'lead_id': leadId,
          'assign_to_users': assignToUsers,
          if (completeBy != null) 'complete_by': completeBy,
          if (priority != null) 'priority': priority,
          if (comment != null) 'comment': comment,
        },
      );
      if (response.statusCode == 200) {
        return response.data['message'];
      } else {
        throw Exception('Failed to assign lead');
      }
    } catch (e) {
      throw Exception('Error assigning lead: $e');
    }
  }

  // GET LEAD ASSIGNMENTS
  Future<List<Map<String, dynamic>>> getLeadAssignments(String leadId) async {
    try {
      final response = await _dio.get(
        '/api/method/etos_mbe.etos_mbe.api.get_lead_assignments',
        queryParameters: {'lead_id': leadId},
      );
      if (response.statusCode == 200) {
        final message = response.data['message'];
        if (message is Map && message.containsKey('data')) {
          return List<Map<String, dynamic>>.from(message['data']);
        }
        return [];
      } else {
        throw Exception('Failed to fetch lead assignments');
      }
    } catch (e) {
      throw Exception('Error fetching lead assignments: $e');
    }
  }
}
