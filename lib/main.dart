import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_scooter/core/router/app_router.dart';
import 'package:e_scooter/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_scooter/core/storage/local_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:e_scooter/core/services/notification_service.dart';

import 'package:e_scooter/core/network/dio_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await NotificationService.initialize();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
    // Continue running the app even if Firebase fails
  }

  final prefs = await SharedPreferences.getInstance();
  final cookieJar = await createCookieJar();
  final dio = await createDioInstance(cookieJar);

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(LocalStorage(prefs)),
        dioProvider.overrideWithValue(dio),
        cookieJarProvider.overrideWithValue(cookieJar),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'E-Scooter ERP',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
