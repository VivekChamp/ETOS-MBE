import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/crm/presentation/leads_list_screen.dart';
import '../../features/crm/presentation/lead_detail_screen.dart';
import '../../features/crm/presentation/lead_create_screen.dart';
import '../../features/tasks/presentation/task_list_screen.dart';
import '../../features/tasks/presentation/task_detail_screen.dart';
import '../../features/tasks/presentation/task_create_screen.dart';
import '../../features/projects/presentation/project_list_screen.dart';
import '../../features/projects/presentation/project_detail_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/crm/leads',
        builder: (context, state) => const LeadsListScreen(),
      ),
      GoRoute(
        path: '/crm/leads/create',
        builder: (context, state) => const LeadCreateScreen(),
      ),
      GoRoute(
        path: '/crm/lead/:leadId',
        builder: (context, state) =>
            LeadDetailScreen(leadId: state.pathParameters['leadId']!),
      ),
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const TaskListScreen(),
      ),
      GoRoute(
        path: '/tasks/create',
        builder: (context, state) => const TaskCreateScreen(),
      ),
      GoRoute(
        path: '/tasks/:taskId',
        builder: (context, state) =>
            TaskDetailScreen(taskId: state.pathParameters['taskId']!),
      ),
      GoRoute(
        path: '/projects',
        builder: (context, state) => const ProjectListScreen(),
      ),
      GoRoute(
        path: '/projects/:projectId',
        builder: (context, state) =>
            ProjectDetailScreen(projectId: state.pathParameters['projectId']!),
      ),
    ],
  );
});
