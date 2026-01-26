import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:e_scooter/core/constants/app_colors.dart';
import '../data/task_repository.dart';
import '../domain/task_model.dart';
import 'package:intl/intl.dart';

// Notifiers
class TaskSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final taskSearchProvider = NotifierProvider<TaskSearchNotifier, String>(
  () => TaskSearchNotifier(),
);

class TaskStatusNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void set(String value) => state = value;
}

final taskStatusProvider = NotifierProvider<TaskStatusNotifier, String>(
  () => TaskStatusNotifier(),
);

class TaskPriorityNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void set(String value) => state = value;
}

final taskPriorityProvider = NotifierProvider<TaskPriorityNotifier, String>(
  () => TaskPriorityNotifier(),
);

// Provider
final tasksProvider = FutureProvider.autoDispose<List<Task>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  final search = ref.watch(taskSearchProvider);
  final status = ref.watch(taskStatusProvider);
  final priority = ref.watch(taskPriorityProvider);

  return repo.getTasks(searchText: search, status: status, priority: priority);
});

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final selectedStatus = ref.watch(taskStatusProvider);
    final selectedPriority = ref.watch(taskPriorityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Tasks"),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (value) =>
                  ref.read(taskSearchProvider.notifier).set(value),
              decoration: InputDecoration(
                hintText: "Search tasks...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: selectedPriority,
                  underline: const SizedBox(),
                  items: ['All', 'Low', 'Medium', 'High']
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e == 'All' ? 'Priorities' : e),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null)
                      ref.read(taskPriorityProvider.notifier).set(v);
                  },
                  hint: const Text("Priority"),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("All"),
                  selected: selectedStatus == 'All',
                  onSelected: (_) =>
                      ref.read(taskStatusProvider.notifier).set('All'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Open"),
                  selected: selectedStatus == 'Open',
                  onSelected: (_) =>
                      ref.read(taskStatusProvider.notifier).set('Open'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Working"),
                  selected: selectedStatus == 'Working',
                  onSelected: (_) =>
                      ref.read(taskStatusProvider.notifier).set('Working'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Completed"),
                  selected: selectedStatus == 'Completed',
                  onSelected: (_) =>
                      ref.read(taskStatusProvider.notifier).set('Completed'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Overdue"),
                  selected: selectedStatus == 'Overdue',
                  onSelected: (_) =>
                      ref.read(taskStatusProvider.notifier).set('Overdue'),
                ),
              ],
            ),
          ),

          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No tasks found",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        leading: Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getPriorityColor(task.priority),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        title: Text(
                          task.subject,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      task.status,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    task.status,
                                    style: TextStyle(
                                      color: _getStatusColor(task.status),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  task.expEndDate ?? 'No Date',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          context.push('/tasks/${task.name}');
                        },
                      ),
                    ).animate().fadeIn(delay: (index * 50).ms);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, stack) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tasks/create'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return Colors.blue;
      case 'Working':
        return Colors.orange;
      case 'Pending Review':
        return Colors.purple;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      case 'Urgent':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }
}
