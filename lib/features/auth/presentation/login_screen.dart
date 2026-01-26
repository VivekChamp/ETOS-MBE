import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/storage/local_storage.dart';
import '../data/auth_repository.dart';

import '../../../core/network/dio_client.dart';

// Providers
final loginControllerProvider = AsyncNotifierProvider<LoginController, void>(
  () {
    return LoginController();
  },
);

class LoginController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state is null (void)
    return null;
  }

  Future<void> login(
    String serverUrl,
    String username,
    String password,
    bool isHttps,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final protocol = isHttps ? 'https://' : 'http://';
      final fullUrl = serverUrl.startsWith('http')
          ? serverUrl
          : '$protocol$serverUrl';

      final dio = ref.read(dioProvider);
      dio.options.baseUrl = fullUrl;

      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.login(username, password);
    });
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isHttps = false;
  final TextEditingController _urlController = TextEditingController(
    text: "165.232.188.221:8001",
  );
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    if (_formKey.currentState!.validate()) {
      // Call Controller
      await ref
          .read(loginControllerProvider.notifier)
          .login(
            _urlController.text.trim(),
            _usernameController.text.trim(),
            _passwordController.text.trim(),
            _isHttps,
          );

      // Handle State
      if (mounted) {
        final state = ref.read(loginControllerProvider);
        if (state.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.error.toString().replaceAll("Exception: ", ""),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (!state.isLoading) {
          // Success if no error and not loading
          context.go('/dashboard');
        }
      }
    }
  }

  void _toggleProtocol() {
    setState(() {
      _isHttps = !_isHttps;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final _isLoading = state.isLoading;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
              const Color(0xFF1E293B),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      // Branding Section
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Logo
                            Container(
                              height: 80,
                              width: 140,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assests/logo.jpeg',
                                fit: BoxFit.contain,
                              ),
                            ).animate().scale(
                              duration: 600.ms,
                              curve: Curves.easeOutBack,
                            ),
                            const SizedBox(height: 12),
                            // Title
                            Text(
                                  "ETOS ERP",
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 200.ms)
                                .slideY(begin: -0.2, end: 0),
                            const SizedBox(height: 6),
                            Text(
                              "Manage Your Business, Grow Your Future",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 300.ms),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms),

                      const SizedBox(height: 20),

                      // Login Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Welcome Text
                              Text(
                                "Welcome to",
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Sign in to continue",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 20),

                              // Server URL Section
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Server Address",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Protocol Chip
                                        GestureDetector(
                                          onTap: _toggleProtocol,
                                          child: Container(
                                            margin: const EdgeInsets.all(8),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: _isHttps
                                                  ? LinearGradient(
                                                      colors: [
                                                        AppColors.primary,
                                                        AppColors.primaryDark,
                                                      ],
                                                    )
                                                  : null,
                                              color: _isHttps
                                                  ? null
                                                  : Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _isHttps
                                                      ? Icons.lock
                                                      : Icons.lock_open,
                                                  size: 14,
                                                  color: _isHttps
                                                      ? Colors.white
                                                      : Colors.grey.shade600,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _isHttps ? "HTTPS" : "HTTP",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: _isHttps
                                                        ? Colors.white
                                                        : Colors.grey.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // URL Input
                                        Expanded(
                                          child: TextFormField(
                                            controller: _urlController,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade800,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: "example.erpnext.com",
                                              hintStyle: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey.shade400,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 16,
                                                  ),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Server address is required';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(delay: 400.ms),

                              const SizedBox(height: 18),

                              // Username
                              CustomTextField(
                                label: "Username / Email",
                                hint: "admin@example.com",
                                controller: _usernameController,
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your username';
                                  }
                                  return null;
                                },
                              ).animate().fadeIn(delay: 500.ms),

                              const SizedBox(height: 18),

                              // Password
                              CustomTextField(
                                label: "Password",
                                hint: "••••••••",
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ).animate().fadeIn(delay: 600.ms),

                              const SizedBox(height: 20),

                              // Login Button
                              Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primaryDark,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(
                                            0.4,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _onLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "Login",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                const Icon(
                                                  Icons.arrow_forward,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ],
                                            ),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 700.ms)
                                  .slideY(begin: 0.2, end: 0),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms).scale(delay: 400.ms),

                      const Spacer(),

                      Column(
                        children: [
                          Text(
                            "Powered by",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "VPS Business Solutions",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 800.ms),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
