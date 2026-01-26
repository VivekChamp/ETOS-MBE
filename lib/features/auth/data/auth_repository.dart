import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import '../../../../core/network/dio_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final cookieJar = ref.watch(cookieJarProvider);
  return AuthRepository(dio, cookieJar);
});

class AuthRepository {
  final Dio _dio;
  final CookieJar _cookieJar;

  // Custom API Path provided by user
  static const String _customApiPath = 'etos_mbe.etos_mbe.api';

  AuthRepository(this._dio, this._cookieJar);

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      print('🔵 [LOGIN] Starting login request...');
      print(
        '🔵 [LOGIN] URL: ${_dio.options.baseUrl}/api/method/$_customApiPath.login',
      );
      print('🔵 [LOGIN] Username: $username');

      final response = await _dio.post(
        '/api/method/$_customApiPath.login',
        data: {'usr': username, 'pwd': password},
      );

      print('🟢 [LOGIN] Response Status: ${response.statusCode}');
      print('🟢 [LOGIN] Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['message'] == 'Logged In') {
          print('✅ [LOGIN] Login successful!');
          return data;
        } else {
          print('❌ [LOGIN] Login failed: ${data['message']}');
          throw Exception(data['message'] ?? 'Login failed');
        }
      } else {
        print('❌ [LOGIN] Server error: ${response.statusCode}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('🔴 [LOGIN] DioException caught!');
      print('🔴 [LOGIN] Type: ${e.type}');
      print('🔴 [LOGIN] Message: ${e.message}');
      print('🔴 [LOGIN] Response: ${e.response?.data}');
      print('🔴 [LOGIN] Status Code: ${e.response?.statusCode}');

      if (e.response != null) {
        throw Exception(
          'Login failed: ${e.response?.data['message'] ?? e.message}',
        );
      }
      throw Exception('Connection error: ${e.message}');
    } catch (e) {
      print('🔴 [LOGIN] General exception: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      print('🔵 [LOGOUT] Starting logout process...');

      // 1. Call standard ERPNext logout
      try {
        await _dio.get('/api/method/logout');
        print('✅ [LOGOUT] ERPNext logout call successful');
      } catch (e) {
        print(
          '⚠️ [LOGOUT] ERPNext logout API call failed (might already be logged out): $e',
        );
      }
    } catch (e) {
      print('🔴 [LOGOUT] Error during logout process: $e');
    } finally {
      // 2. ALWAYS Clear Cookies (Crucial)
      try {
        await _cookieJar.deleteAll();
        print('✅ [LOGOUT] Cookies cleared successfully');
      } catch (e) {
        print("🔴 [LOGOUT] Error clearing cookies: $e");
      }
    }
  }
}
