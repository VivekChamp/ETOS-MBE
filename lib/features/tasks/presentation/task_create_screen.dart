import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:e_scooter/core/constants/app_colors.dart';
import '../data/task_repository.dart';
import 'task_list_screen.dart'; // For tasksProvider refresh

final projectsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final repo = ref.watch(taskRepositoryProvider);
    return repo.getProjects();
  },
);

final usersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.getUsersForAssignment();
});

class TaskCreateScreen extends ConsumerStatefulWidget {
  const TaskCreateScreen({super.key});

  @override
  ConsumerState<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends ConsumerState<TaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'Medium';
  String? _selectedProject;
  DateTime? _dueDate;
  List<String> _selectedUsers = []; // State for selected users
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select Due Date')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(taskRepositoryProvider);

      final data = {
        'subject': _subjectController.text,
        'description': _descriptionController.text,
        'priority': _priority,
        'exp_end_date': _dueDate.toString().split(' ')[0],
        'status': 'Open',
        'assign_to': _selectedUsers, // Pass selected users
        if (_selectedProject != null) 'project': _selectedProject,
      };

      await repo.createTask(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task Created Successfully')),
        );
        ref.refresh(tasksProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Create Task"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Task Info"),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _subjectController,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Enter Task Subject",
                        border: InputBorder.none,
                        icon: Icon(Icons.title, color: AppColors.primary),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: "Add Description...",
                        border: InputBorder.none,
                        icon: Icon(
                          Icons.description_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildLabel("Details"),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Priority
                    DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: const InputDecoration(
                        labelText: "Priority",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        prefixIcon: Icon(Icons.flag, color: Colors.orange),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: ['Low', 'Medium', 'High', 'Urgent']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _priority = v!),
                    ),
                    const SizedBox(height: 16),

                    // Project
                    projectsAsync.when(
                      data: (projects) => DropdownButtonFormField<String>(
                        value: _selectedProject,
                        decoration: const InputDecoration(
                          labelText: "Project",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          prefixIcon: Icon(
                            Icons.business_center,
                            color: Colors.purple,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: projects
                            .map(
                              (p) => DropdownMenuItem(
                                value: p['name'].toString(),
                                child: Text(
                                  p['project_name']?.toString() ??
                                      p['name'].toString(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedProject = v),
                        hint: const Text("Select Project"),
                        disabledHint: projects.isEmpty
                            ? const Text("No Projects Available")
                            : null,
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, s) => Text(
                        "Error: $e",
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Due Date
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _dueDate == null
                                    ? 'Select Due Date'
                                    : _dueDate.toString().split(' ')[0],
                                style: TextStyle(
                                  color: _dueDate == null
                                      ? Colors.grey.shade600
                                      : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (_dueDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () =>
                                    setState(() => _dueDate = null),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const SizedBox(height: 24),
              _buildLabel("Assign To (Optional)"),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected Users Chips
                    if (_selectedUsers.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedUsers.map((email) {
                          return Chip(
                            avatar: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Text(
                                email[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            label: Text(
                              email,
                              style: const TextStyle(fontSize: 12),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedUsers.remove(email);
                              });
                            },
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                          );
                        }).toList(),
                      ),

                    if (_selectedUsers.isNotEmpty) const SizedBox(height: 16),

                    // Add User Button
                    Consumer(
                      builder: (context, ref, child) {
                        final usersAsync = ref.watch(usersProvider);

                        return usersAsync.when(
                          data: (users) => InkWell(
                            onTap: () => _showUserSelection(context, users),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.primary),
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.primary.withOpacity(0.05),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.person_add,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedUsers.isEmpty
                                        ? "Select Users"
                                        : "Add More Users",
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (e, s) => Text('Error loading users: $e'),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Create Task",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: _dueDate ?? DateTime.now(),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _showUserSelection(
    BuildContext context,
    List<Map<String, dynamic>> users,
  ) async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) =>
          UserSelectionDialog(users: users, initialSelected: _selectedUsers),
    );

    if (selected != null) {
      setState(() => _selectedUsers = selected);
    }
  }
}

class UserSelectionDialog extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final List<String> initialSelected;

  const UserSelectionDialog({
    super.key,
    required this.users,
    required this.initialSelected,
  });

  @override
  State<UserSelectionDialog> createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends State<UserSelectionDialog> {
  late List<String> _selectedIds;
  late List<Map<String, dynamic>> _filteredUsers;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.initialSelected);
    _filteredUsers = widget.users;
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = widget.users;
      } else {
        _filteredUsers = widget.users.where((user) {
          final name = (user['full_name'] ?? '').toString().toLowerCase();
          final email = (user['email'] ?? user['name'] ?? '')
              .toString()
              .toLowerCase();
          final search = query.toLowerCase();
          return name.contains(search) || email.contains(search);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Select Users",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search users...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: _filterUsers,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filteredUsers.isEmpty
                  ? const Center(child: Text("No users found"))
                  : ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final email = user['email'] ?? user['name'] ?? '';
                        final name = user['full_name'] ?? 'Unknown';
                        final isSelected = _selectedIds.contains(email);

                        return ListTile(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedIds.remove(email);
                              } else {
                                _selectedIds.add(email);
                              }
                            });
                          },
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : Text(
                                    name[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                          ),
                          title: Text(name),
                          subtitle: Text(email),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                )
                              : const Icon(
                                  Icons.circle_outlined,
                                  color: Colors.grey,
                                ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedIds),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text("Select (${_selectedIds.length})"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
