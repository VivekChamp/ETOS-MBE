import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_scooter/core/constants/app_colors.dart';
import 'package:e_scooter/core/utils/html_utils.dart';
import '../data/task_repository.dart';
import 'widgets/assign_task_dialog.dart';

// NO CACHE - Fresh API call every time!
class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  Map<String, dynamic>? taskData;
  List<Map<String, dynamic>>? assignments;
  bool isLoadingTask = true;
  bool isLoadingAssignments = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    print('🔵 [TASK_DETAIL] Screen opened - Loading FRESH data (NO CACHE)');
    // Fresh API call every time screen opens!
    _loadTaskDetails();
    _loadAssignments();
  }

  // Fresh API call - NO CACHE!
  Future<void> _loadTaskDetails() async {
    print('🔵 [TASK_DETAIL] Fetching task details from API...');
    setState(() {
      isLoadingTask = true;
      errorMessage = null;
    });

    try {
      final repo = ref.read(taskRepositoryProvider);
      final data = await repo.getTaskDetails(widget.taskId);

      print('🟢 [TASK_DETAIL] Task details loaded successfully');
      if (mounted) {
        setState(() {
          taskData = data;
          isLoadingTask = false;
        });
      }
    } catch (e) {
      print('🔴 [TASK_DETAIL] Error loading task: $e');
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoadingTask = false;
        });
      }
    }
  }

  // Fresh API call for assignments - NO CACHE!
  Future<void> _loadAssignments() async {
    print('🔵 [TASK_DETAIL] Fetching assignments from API...');
    setState(() => isLoadingAssignments = true);

    try {
      final repo = ref.read(taskRepositoryProvider);
      final data = await repo.getTaskAssignments(widget.taskId);

      print('🟢 [TASK_DETAIL] Assignments loaded: ${data.length} users');
      if (mounted) {
        setState(() {
          assignments = data;
          isLoadingAssignments = false;
        });
      }
    } catch (e) {
      print('🔴 [TASK_DETAIL] Error loading assignments: $e');
      if (mounted) {
        setState(() {
          isLoadingAssignments = false;
        });
      }
    }
  }

  Future<void> _showAssignDialog(BuildContext context, String taskName) async {
    final result = await showDialog(
      context: context,
      builder: (context) =>
          AssignTaskDialog(taskId: widget.taskId, taskName: taskName),
    );

    // Reload FRESH assignments after assignment - NO CACHE!
    if (result == true) {
      print('🔄 [TASK_DETAIL] Reloading assignments after assignment...');
      _loadAssignments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Task Details"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_ind),
            tooltip: 'Assign Task',
            onPressed: () {
              if (taskData != null) {
                final subject = taskData!['subject']?.toString() ?? 'Task';
                _showAssignDialog(context, subject);
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Loading state
    if (isLoadingTask) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text("Error: $errorMessage"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _loadTaskDetails();
                _loadAssignments();
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    // Data loaded - show content
    if (taskData == null) {
      return const Center(child: Text("No data available"));
    }

    final subject = taskData!['subject']?.toString() ?? 'N/A';
    final status = taskData!['status']?.toString() ?? 'N/A';
    final priority = taskData!['priority']?.toString() ?? 'N/A';
    final owner = taskData!['owner']?.toString() ?? 'N/A';
    final assignedTo = taskData!['assigned_to']?.toString();
    final date = taskData!['exp_end_date']?.toString() ?? 'N/A';
    final description =
        taskData!['description']?.toString() ?? 'No description';
    final project = taskData!['project']?.toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x0D000000),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTag(status, _getStatusColor(status)),
                    const SizedBox(width: 8),
                    _buildTag(priority, _getPriorityColor(priority)),
                  ],
                ),
                const SizedBox(height: 16),
                if (project != null) ...[
                  const SizedBox(height: 8),
                  _buildRow(Icons.business_center, "Project", project),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _buildRow(Icons.person, "Owner", owner),
                if (assignedTo != null) ...[
                  const SizedBox(height: 8),
                  _buildRow(Icons.assignment_ind, "Assigned To", assignedTo),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildSection(context, "Dates", [
            _buildRow(Icons.calendar_today, "Due Date", date),
          ]),

          const SizedBox(height: 20),

          _buildSection(context, "Description", [
            Text(
              stripHtmlTags(description), // Clean HTML tags!
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // Assigned Users Section
          _buildAssignmentsSection(),
        ],
      ),
    );
  }

  Widget _buildAssignmentsSection() {
    if (isLoadingAssignments) {
      return _buildSection(context, "Assignment", [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ),
      ]);
    }

    if (assignments == null || assignments!.isEmpty) {
      return _buildSection(context, "Assignment", [
        Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "No users assigned yet. Use the assign button above to assign this task.",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ]);
    }

    return _buildSection(context, "Assigned To", [
      ...assignments!.map((assignment) {
        final user = assignment['allocated_to']?.toString() ?? 'Unknown';
        final assignmentPriority = assignment['priority']?.toString();
        final dueDate = assignment['date']?.toString();
        final assignmentStatus = assignment['status']?.toString() ?? 'Open';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (assignmentPriority != null)
                          Text(
                            'Priority: $assignmentPriority',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: assignmentStatus == 'Closed'
                          ? Colors.green.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      assignmentStatus,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: assignmentStatus == 'Closed'
                            ? Colors.green.shade700
                            : Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              if (dueDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.event, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Complete by: $dueDate',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    ]);
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0x0D000000),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
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
