import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:e_scooter/core/constants/app_colors.dart';
import '../data/task_repository.dart';
import '../domain/task_model.dart';
import 'package:fl_chart/fl_chart.dart';

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
      body: tasksAsync.when(
        data: (tasks) {
          // Calculate stats
          final totalTasks = tasks.length;
          final openTasks = tasks.where((t) => t.status == 'Open').length;
          final workingTasks = tasks.where((t) => t.status == 'Working').length;
          final completedTasks = tasks
              .where((t) => t.status == 'Completed')
              .length;
          final overdueTasks = tasks.where((t) => t.status == 'Overdue').length;

          // Priority counts
          final highPriority = tasks
              .where((t) => t.priority == 'High' || t.priority == 'Urgent')
              .length;
          final mediumPriority = tasks
              .where((t) => t.priority == 'Medium')
              .length;
          final lowPriority = tasks.where((t) => t.priority == 'Low').length;

          // Owner counts
          final Map<String, int> ownerCounts = {};
          for (var t in tasks) {
            ownerCounts[t.owner] = (ownerCounts[t.owner] ?? 0) + 1;
          }
          final sortedOwners = ownerCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return CustomScrollView(
            slivers: [
              // Dashboard Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Task Overview",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Total: $totalTasks",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Stats Row
                      Row(
                        children: [
                          _buildStatCard(
                            "Open",
                            openTasks.toString(),
                            Colors.orange,
                            Icons.pending_actions,
                          ),
                          _buildStatCard(
                            "Working",
                            workingTasks.toString(),
                            Colors.blue,
                            Icons.bolt,
                          ),
                          _buildStatCard(
                            "Done",
                            completedTasks.toString(),
                            Colors.green,
                            Icons.check_circle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Charts Row
                      Row(
                        children: [
                          // Status Pie Chart
                          Expanded(
                            flex: 1,
                            child: Container(
                              height: 180,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    "Status",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: totalTasks == 0
                                        ? const Center(
                                            child: Text(
                                              "No Data",
                                              style: TextStyle(fontSize: 10),
                                            ),
                                          )
                                        : PieChart(
                                            PieChartData(
                                              sectionsSpace: 2,
                                              centerSpaceRadius: 25,
                                              sections: [
                                                if (openTasks > 0)
                                                  PieChartSectionData(
                                                    value: openTasks.toDouble(),
                                                    color: Colors.orange,
                                                    title: '',
                                                    radius: 12,
                                                  ),
                                                if (workingTasks > 0)
                                                  PieChartSectionData(
                                                    value: workingTasks
                                                        .toDouble(),
                                                    color: Colors.blue,
                                                    title: '',
                                                    radius: 12,
                                                  ),
                                                if (completedTasks > 0)
                                                  PieChartSectionData(
                                                    value: completedTasks
                                                        .toDouble(),
                                                    color: Colors.green,
                                                    title: '',
                                                    radius: 12,
                                                  ),
                                                if (overdueTasks > 0)
                                                  PieChartSectionData(
                                                    value: overdueTasks
                                                        .toDouble(),
                                                    color: Colors.red,
                                                    title: '',
                                                    radius: 12,
                                                  ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Priority distribution
                          Expanded(
                            flex: 1,
                            child: Container(
                              height: 180,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Priority",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildPriorityBar(
                                    "High",
                                    highPriority,
                                    totalTasks,
                                    Colors.red,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildPriorityBar(
                                    "Medium",
                                    mediumPriority,
                                    totalTasks,
                                    Colors.orange,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildPriorityBar(
                                    "Low",
                                    lowPriority,
                                    totalTasks,
                                    Colors.green,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Users Section
                      const Text(
                        "Tasks by User",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 60,
                        child: sortedOwners.isEmpty
                            ? const Center(child: Text("No user data"))
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: sortedOwners.length,
                                itemBuilder: (context, index) {
                                  final entry = sortedOwners[index];
                                  final userName = entry.key.split('@')[0];
                                  return Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          userName,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${entry.value} Tasks",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // Filters (Horizontal)
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                        onSelected: (_) => ref
                            .read(taskStatusProvider.notifier)
                            .set('Working'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Completed"),
                        selected: selectedStatus == 'Completed',
                        onSelected: (_) => ref
                            .read(taskStatusProvider.notifier)
                            .set('Completed'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Overdue"),
                        selected: selectedStatus == 'Overdue',
                        onSelected: (_) => ref
                            .read(taskStatusProvider.notifier)
                            .set('Overdue'),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),

              // Task List
              tasks.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_turned_in_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No tasks found",
                              style: TextStyle(fontSize: 16), // Adjusted style
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final task = tasks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  task.status,
                                  style: TextStyle(
                                    color: _getStatusColor(task.status),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                onTap: () {
                                  context.push('/tasks/${task.name}');
                                },
                              ),
                            ).animate().fadeIn(delay: (index * 50).ms),
                          );
                        }, childCount: tasks.length),
                      ),
                    ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tasks/create'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBar(String label, int count, int total, Color color) {
    final double percentage = total > 0 ? count / total : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11)),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withOpacity(0.1),
            color: color,
            minHeight: 6,
          ),
        ),
      ],
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
