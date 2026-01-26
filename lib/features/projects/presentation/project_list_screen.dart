import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:e_scooter/core/constants/app_colors.dart';
import '../data/project_repository.dart';
import '../domain/project_model.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';

// Stateful widget for filter management
class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  // Filter states
  String searchText = '';
  String selectedStatus = 'All';
  DateTime? fromDate;
  DateTime? toDate;

  List<Project> projects = [];
  bool isLoading = true;
  String? errorMessage;

  final List<String> statusOptions = [
    'All',
    'Open',
    'Working',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final repo = ref.read(projectRepositoryProvider);
      final result = await repo.getProjects(
        searchText: searchText.isEmpty ? null : searchText,
        status: selectedStatus == 'All' ? null : selectedStatus,
        fromDate: fromDate != null
            ? DateFormat('yyyy-MM-dd').format(fromDate!)
            : null,
        toDate: toDate != null
            ? DateFormat('yyyy-MM-dd').format(toDate!)
            : null,
      );

      if (mounted) {
        setState(() {
          projects = result;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? (fromDate ?? DateTime.now())
          : (toDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
      _loadProjects();
    }
  }

  void _clearFilters() {
    setState(() {
      searchText = '';
      selectedStatus = 'All';
      fromDate = null;
      toDate = null;
    });
    _loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters =
        searchText.isNotEmpty ||
        selectedStatus != 'All' ||
        fromDate != null ||
        toDate != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Projects"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear Filters',
              onPressed: _clearFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search projects...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                    suffixIcon: searchText.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => searchText = '');
                              _loadProjects();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => searchText = value);
                    // Debounce search
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (searchText == value) {
                        _loadProjects();
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Status & Date Filters Row
                Row(
                  children: [
                    // Status Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedStatus,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.primary,
                            ),
                            items: statusOptions.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(
                                  status,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => selectedStatus = value!);
                              _loadProjects();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Date Filter Button
                    IconButton(
                      icon: Icon(
                        Icons.date_range,
                        color: (fromDate != null || toDate != null)
                            ? AppColors.primary
                            : Colors.grey,
                      ),
                      onPressed: () => _showDateFilterDialog(context),
                      tooltip: 'Date Filter',
                    ),
                  ],
                ),

                // Active Date Filters Display
                if (fromDate != null || toDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        if (fromDate != null) ...[
                          Chip(
                            label: Text(
                              'From: ${DateFormat('MMM d, y').format(fromDate!)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() => fromDate = null);
                              _loadProjects();
                            },
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (toDate != null)
                          Chip(
                            label: Text(
                              'To: ${DateFormat('MMM d, y').format(toDate!)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() => toDate = null);
                              _loadProjects();
                            },
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Projects List
          Expanded(child: _buildProjectsList()),
        ],
      ),
    );
  }

  Widget _buildProjectsList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProjects,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              "No Projects Found",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            if (searchText.isNotEmpty ||
                selectedStatus != 'All' ||
                fromDate != null ||
                toDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear Filters'),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProjects,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: projects.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final project = projects[index];
          return _buildProjectCard(
            context,
            project,
          ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
        },
      ),
    );
  }

  void _showDateFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Date Filter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.calendar_today,
                color: AppColors.primary,
              ),
              title: const Text('From Date'),
              subtitle: Text(
                fromDate != null
                    ? DateFormat('MMM d, y').format(fromDate!)
                    : 'Not set',
              ),
              onTap: () {
                Navigator.pop(context);
                _selectDate(context, true);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.event, color: AppColors.primary),
              title: const Text('To Date'),
              subtitle: Text(
                toDate != null
                    ? DateFormat('MMM d, y').format(toDate!)
                    : 'Not set',
              ),
              onTap: () {
                Navigator.pop(context);
                _selectDate(context, false);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                fromDate = null;
                toDate = null;
              });
              Navigator.pop(context);
              _loadProjects();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project) {
    return GestureDetector(
      onTap: () => context.push('/projects/${project.name}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.projectName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                _buildStatusBadge(project.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  project.expectedEndDate ?? 'No Deadline',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Spacer(),
                _buildPriorityBadge(project.priority),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Progress",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  "${project.percentComplete.toInt()}%",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearPercentIndicator(
              lineHeight: 8.0,
              percent: (project.percentComplete / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade100,
              progressColor: _getProgressColor(project.percentComplete),
              barRadius: const Radius.circular(10),
              padding: EdgeInsets.zero,
              animation: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'open':
        color = Colors.blue;
        break;
      case 'working':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    IconData icon;
    Color color;
    switch (priority.toLowerCase()) {
      case 'high':
        icon = Icons.keyboard_double_arrow_up;
        color = Colors.red;
        break;
      case 'medium':
        icon = Icons.keyboard_arrow_up;
        color = Colors.orange;
        break;
      case 'low':
        icon = Icons.keyboard_arrow_down;
        color = Colors.green;
        break;
      default:
        icon = Icons.remove;
        color = Colors.grey;
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 2),
        Text(
          priority,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double percent) {
    if (percent >= 100) return Colors.green;
    if (percent >= 75) return Colors.teal;
    if (percent >= 50) return Colors.blue;
    if (percent >= 25) return Colors.orange;
    return Colors.red;
  }
}
