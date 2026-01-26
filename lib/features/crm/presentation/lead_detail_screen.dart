import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:e_scooter/core/constants/app_colors.dart';
import 'package:e_scooter/core/utils/html_utils.dart';
import '../data/crm_repository.dart';
import 'widgets/assign_lead_dialog.dart';

class LeadDetailScreen extends ConsumerStatefulWidget {
  final String leadId;

  const LeadDetailScreen({super.key, required this.leadId});

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen> {
  Map<String, dynamic>? leadData;
  List<Map<String, dynamic>>? assignments;
  bool isLoading = true;
  bool isLoadingAssignments = true;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final repo = ref.read(crmRepositoryProvider);
      final data = await repo.getLeadDetails(widget.leadId);

      if (mounted) {
        setState(() {
          leadData = data;
          isLoading = false;
        });
        _loadAssignments();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAssignments() async {
    setState(() => isLoadingAssignments = true);
    try {
      final repo = ref.read(crmRepositoryProvider);
      final data = await repo.getLeadAssignments(widget.leadId);
      if (mounted) {
        setState(() {
          assignments = data;
          isLoadingAssignments = false;
        });
      }
    } catch (e) {
      print('Error loading assignments: $e');
      if (mounted) setState(() => isLoadingAssignments = false);
    }
  }

  void _showAssignDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AssignLeadDialog(
        leadId: widget.leadId,
        leadName: leadData?['lead_name']?.toString() ?? 'Lead',
      ),
    );

    if (result == true) {
      _loadAssignments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Lead Details"),
        centerTitle: true,
        actions: [
          // Add Assign Button
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Assign Users',
            onPressed: leadData == null ? null : _showAssignDialog,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text("Error: $error"));
    }
    if (leadData == null) {
      return const Center(child: Text("No data found"));
    }

    final lead = leadData!;
    final name = lead['lead_name']?.toString() ?? 'N/A';
    final status = lead['status']?.toString() ?? 'N/A';
    final company = lead['company_name']?.toString(); // Nullable
    final leadOwner = lead['lead_owner']?.toString() ?? 'N/A';
    final source = lead['source']?.toString() ?? 'N/A';
    final mobile = lead['mobile_no']?.toString() ?? 'N/A';
    final email = lead['email_id']?.toString() ?? 'N/A';
    final leadType = lead['type']?.toString() ?? 'N/A';

    String notes = 'No notes available';
    if (lead['notes'] != null) {
      if (lead['notes'] is List) {
        notes = (lead['notes'] as List).map((e) => e.toString()).join('\n');
      } else {
        notes = lead['notes'].toString();
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card (Basic Info)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'L',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      Icons.phone,
                      'Call',
                      () => _launchUrl('tel:$mobile'),
                    ),
                    _buildActionButton(
                      Icons.email,
                      'Email',
                      () => _launchUrl('mailto:$email'),
                    ),
                    _buildActionButton(
                      Icons.message,
                      'SMS',
                      () => _launchUrl('sms:$mobile'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white24),
                const SizedBox(height: 16),
                // Extra Info in Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeaderInfoItem("Owner", leadOwner),
                    _buildHeaderInfoItem("Source", source),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Contact Info (Primary)
          _buildSection(context, "Contact Info", [
            _buildRow(Icons.phone_android, "Mobile Number (Primary)", mobile),
            _buildRow(Icons.email_outlined, "Email ID", email),
          ]),

          const SizedBox(height: 16),

          // Type Info
          _buildSection(context, "Type Details", [
            _buildRow(Icons.person, "Lead Type", leadType),
            if (company != null && company.toString().isNotEmpty)
              _buildRow(Icons.business, "Company Name", company),
          ]),

          const SizedBox(height: 16),

          // Notes
          _buildSection(context, "Notes", [
            Text(
              stripHtmlTags(notes),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // Assignments Section
          _buildAssignmentsSection(),
        ],
      ),
    );
  }

  Widget _buildAssignmentsSection() {
    if (isLoadingAssignments) {
      return _buildSection(context, "Assignments", [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ),
      ]);
    }

    if (assignments == null || assignments!.isEmpty) {
      return _buildSection(context, "Assignments", [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "No users assigned",
              style: TextStyle(color: Colors.grey),
            ),
            TextButton.icon(
              onPressed: _showAssignDialog,
              icon: const Icon(Icons.add),
              label: const Text("Assign"),
            ),
          ],
        ),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Assignments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                onPressed: _showAssignDialog,
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                tooltip: 'Add Assignment',
              ),
            ],
          ),
        ),
        ...assignments!.map((assignment) {
          final assignedTo =
              assignment['allocated_to']?.toString() ?? 'Unknown';
          final date =
              assignment['date']?.toString().split(' ')[0] ??
              'No Date'; // Removed type mismatch risk
          final priority = assignment['priority']?.toString() ?? 'Low';
          final status = assignment['status']?.toString() ?? 'Open';
          final description = assignment['description']?.toString() ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        assignedTo.isNotEmpty
                            ? assignedTo[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignedTo,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "$status • $priority",
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (date != 'No Date')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          date,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                if (description.isNotEmpty &&
                    description != "Assigned by ${assignedTo}") ...[
                  // Basic check
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Text(
                    stripHtmlTags(description),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
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
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSimpleRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderInfoItem(String label, String value) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.red;
      case 'closed':
        return Colors.green;
      case 'lead':
        return Colors.blue;
      case 'replied':
        return Colors.orange;
      case 'opportunity':
        return Colors.purple;
      case 'quotation':
        return Colors.teal;
      case 'lost quotation':
        return Colors.red;
      case 'interested':
        return Colors.lightGreen;
      case 'converted':
        return Colors.greenAccent;
      case 'do not contact':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
