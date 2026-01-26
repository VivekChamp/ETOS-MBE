import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import 'package:e_scooter/core/constants/app_colors.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../data/profile_repository.dart';
import '../domain/employee_model.dart';

// Provider to get the current user info first (to get Employee ID)
final fullProfileProvider = FutureProvider.autoDispose<Employee>((ref) async {
  // 1. Get Logged In User Info to find Employee ID
  final dashboardRepo = ref.watch(dashboardRepositoryProvider);
  final userInfo = await dashboardRepo.getUserInfo();
  final employeeId = userInfo['employee_id'];

  if (employeeId == null || employeeId.isEmpty) {
    throw Exception("No Employee linked to this user");
  }

  // 2. Get Full Employee Details using Resource API
  final profileRepo = ref.watch(profileRepositoryProvider);
  return profileRepo.getEmployeeDetails(employeeId);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(fullProfileProvider);
    final dio = ref.watch(dioProvider);
    final baseUrl = dio.options.baseUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (employee) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Profile Header
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          (employee.image != null && employee.image!.isNotEmpty)
                          ? NetworkImage(_getImageUrl(employee.image!, baseUrl))
                          : null,
                      child: (employee.image == null || employee.image!.isEmpty)
                          ? Text(
                              employee.employeeName.isNotEmpty
                                  ? employee.employeeName[0]
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 40,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                employee.employeeName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                employee.designation ?? "Employee",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Sections
              _buildSectionTitle(context, "Personal Details"),
              _buildInfoCard([
                _buildInfoRow(
                  Icons.cake,
                  "Date of Birth",
                  employee.dateOfBirth ?? "N/A",
                ),
                _buildInfoRow(
                  Icons.person_outline,
                  "Gender",
                  employee.gender ?? "N/A",
                ),
              ]),

              const SizedBox(height: 24),

              _buildSectionTitle(context, "Work Information"),
              _buildInfoCard([
                _buildInfoRow(Icons.badge, "Employee ID", employee.name),
                _buildInfoRow(
                  Icons.business,
                  "Company",
                  employee.company ?? "N/A",
                ),
                _buildInfoRow(
                  Icons.apartment,
                  "Department",
                  employee.department ?? "N/A",
                ),
                _buildInfoRow(
                  Icons.calendar_today,
                  "Joining Date",
                  employee.dateOfJoining ?? "N/A",
                ),
              ]),

              const SizedBox(height: 24),

              _buildSectionTitle(context, "Contact Info"),
              _buildInfoCard([
                _buildInfoRow(
                  Icons.email_outlined,
                  "Email",
                  employee.companyEmail ?? "N/A",
                ),
                _buildInfoRow(
                  Icons.phone_android,
                  "Mobile",
                  employee.mobileNo ?? "N/A",
                ),
              ]),

              const SizedBox(height: 48),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text("Error: $e")),
      ),
    );
  }

  // Handle relative URLs from ERPNext (e.g. /files/image.jpg)
  String _getImageUrl(String path, String baseUrl) {
    if (path.startsWith('http')) return path;

    // Check if path implies relative to base
    if (baseUrl.endsWith('/') && path.startsWith('/')) {
      return '$baseUrl${path.substring(1)}';
    } else if (!baseUrl.endsWith('/') && !path.startsWith('/')) {
      return '$baseUrl/$path';
    }
    return '$baseUrl$path';
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 4),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text(
              "Logout",
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
