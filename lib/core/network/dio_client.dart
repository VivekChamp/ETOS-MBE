import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  throw UnimplementedError("Dio must be initialized in main");
});

final cookieJarProvider = Provider<CookieJar>((ref) {
  throw UnimplementedError("CookieJar must be initialized in main");
});

Future<CookieJar> createCookieJar() async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final path = '${appDocDir.path}/.cookies/';
  return PersistCookieJar(storage: FileStorage(path));
}

Future<Dio> createDioInstance(CookieJar cookieJar) async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(CookieManager(cookieJar));

  // Add Interceptors
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          print("Session Expired: ${e.response?.statusCode}");
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
}
