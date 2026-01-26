import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:e_scooter/core/constants/app_colors.dart';
import '../data/crm_repository.dart';
import '../domain/lead_model.dart';

// Filter Notifiers
class LeadsSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final leadsSearchProvider = NotifierProvider<LeadsSearchNotifier, String>(
  () => LeadsSearchNotifier(),
);

class LeadsStatusNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void set(String value) => state = value;
}

final leadsStatusProvider = NotifierProvider<LeadsStatusNotifier, String>(
  () => LeadsStatusNotifier(),
);

class LeadsDateFilterNotifier extends Notifier<Map<String, String?>> {
  @override
  Map<String, String?> build() => {'from': null, 'to': null};
  void set(Map<String, String?> value) => state = value;
}

final leadsDateFilterProvider =
    NotifierProvider<LeadsDateFilterNotifier, Map<String, String?>>(
      () => LeadsDateFilterNotifier(),
    );

// Leads Provider watching filters
final leadsProvider = FutureProvider.autoDispose<List<Lead>>((ref) async {
  final repo = ref.watch(crmRepositoryProvider);
  final search = ref.watch(leadsSearchProvider);
  final status = ref.watch(leadsStatusProvider);
  final dateFilter = ref.watch(leadsDateFilterProvider);

  return repo.getLeads(
    searchText: search,
    status: status,
    fromDate: dateFilter['from'],
    toDate: dateFilter['to'],
  );
});

class LeadsListScreen extends ConsumerWidget {
  const LeadsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(leadsProvider);
    final selectedStatus = ref.watch(leadsStatusProvider);
    final dateFilter = ref.watch(leadsDateFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Leads"),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (value) =>
                  ref.read(leadsSearchProvider.notifier).set(value),
              decoration: InputDecoration(
                hintText: "Search leads...",
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
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                ActionChip(
                  label: Text(
                    dateFilter['from'] != null
                        ? "${dateFilter['from']} - ${dateFilter['to'] ?? 'Now'}"
                        : "Date Range",
                  ),
                  avatar: const Icon(Icons.calendar_today, size: 16),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      ref.read(leadsDateFilterProvider.notifier).set({
                        'from': picked.start.toString().split(' ')[0],
                        'to': picked.end.toString().split(' ')[0],
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("All"),
                  selected: selectedStatus == 'All',
                  onSelected: (_) =>
                      ref.read(leadsStatusProvider.notifier).set('All'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Open"),
                  selected: selectedStatus == 'Open',
                  onSelected: (_) =>
                      ref.read(leadsStatusProvider.notifier).set('Open'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Lead"),
                  selected: selectedStatus == 'Lead',
                  onSelected: (_) =>
                      ref.read(leadsStatusProvider.notifier).set('Lead'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Replied"),
                  selected: selectedStatus == 'Replied',
                  onSelected: (_) =>
                      ref.read(leadsStatusProvider.notifier).set('Replied'),
                ),
              ],
            ),
          ),

          Expanded(
            child: leadsAsync.when(
              data: (leads) {
                if (leads.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.folder_open,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No leads found",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: leads.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final lead = leads[index];
                    return Card(
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
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            lead.leadName.isNotEmpty
                                ? lead.leadName[0].toUpperCase()
                                : 'L',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          lead.leadName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (lead.companyName != null)
                              Text(lead.companyName!),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: _getStatusColor(lead.status),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  lead.status,
                                  style: const TextStyle(fontSize: 12),
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
                          // Navigate to details
                          context.push('/crm/lead/${lead.name}');
                        },
                      ),
                    ).animate().fadeIn(delay: (index * 50).ms);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text("Error loading leads: $e"),
                    TextButton(
                      onPressed: () => ref.refresh(leadsProvider),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/crm/leads/create');
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'lead':
        return Colors.blue;
      case 'open':
        return Colors.green;
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
