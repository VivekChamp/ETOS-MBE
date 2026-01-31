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
      body: leadsAsync.when(
        data: (leads) {
          // Calculate Statistics
          final totalLeads = leads.length;

          // Grouped Stats
          final newLeadsCount = leads
              .where((l) => l.status.toLowerCase() == 'lead')
              .length;
          final activeLeadsCount = leads
              .where(
                (l) => [
                  'open',
                  'replied',
                  'interested',
                ].contains(l.status.toLowerCase()),
              )
              .length;
          final opportunityCount = leads
              .where(
                (l) => [
                  'opportunity',
                  'quotation',
                ].contains(l.status.toLowerCase()),
              )
              .length;
          final convertedCount = leads
              .where((l) => l.status.toLowerCase() == 'converted')
              .length;

          // Status Distribution for Pie Chart
          final Map<String, int> statusCounts = {};
          for (var l in leads) {
            statusCounts[l.status] = (statusCounts[l.status] ?? 0) + 1;
          }

          // Territory Distribution
          final Map<String, int> territoryCounts = {};
          for (var l in leads) {
            final t = l.territory ?? 'Unspecified';
            territoryCounts[t] = (territoryCounts[t] ?? 0) + 1;
          }
          final sortedTerritories = territoryCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Dashboard Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Leads Dashboard",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            "Real-time overview of your pipeline",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          "Total: $totalLeads",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Metrics Grid (2x2)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 100,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildMetricCard(
                      "New Leads",
                      newLeadsCount.toString(),
                      Colors.indigo,
                      Icons.person_add_rounded,
                    ),
                    _buildMetricCard(
                      "In Progress",
                      activeLeadsCount.toString(),
                      Colors.orange.shade700,
                      Icons.sync_rounded,
                    ),
                    _buildMetricCard(
                      "Opportunities",
                      opportunityCount.toString(),
                      Colors.purple,
                      Icons.stars_rounded,
                    ),
                    _buildMetricCard(
                      "Converted",
                      convertedCount.toString(),
                      Colors.green,
                      Icons.check_circle_rounded,
                    ),
                  ]),
                ),
              ),

              // 3. Top Regions Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: _buildGlassContainer(
                    title: "Lead Distribution by Region",
                    child: sortedTerritories.isEmpty
                        ? const SizedBox(
                            height: 60,
                            child: Center(
                              child: Text("No regional data available"),
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sortedTerritories.length > 6
                                ? 6
                                : sortedTerritories.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisExtent: 45,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 12,
                                ),
                            itemBuilder: (context, index) {
                              final e = sortedTerritories[index];
                              return _buildProgressItem(
                                e.key,
                                e.value,
                                totalLeads,
                                AppColors.primary,
                              );
                            },
                          ),
                  ),
                ),
              ),

              // 4. Filtering Section (Sticky)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  minHeight: 50,
                  maxHeight: 50,
                  child: Container(
                    color: AppColors.background,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          ActionChip(
                            label: Text(
                              dateFilter['from'] != null
                                  ? "${dateFilter['from']} - ${dateFilter['to'] ?? 'Now'}"
                                  : "Date Range",
                            ),
                            avatar: const Icon(Icons.calendar_month, size: 16),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey.shade300),
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
                          _buildFilterChip("All", selectedStatus == 'All', ref),
                          _buildFilterChip(
                            "Open",
                            selectedStatus == 'Open',
                            ref,
                          ),
                          _buildFilterChip(
                            "Lead",
                            selectedStatus == 'Lead',
                            ref,
                          ),
                          _buildFilterChip(
                            "Replied",
                            selectedStatus == 'Replied',
                            ref,
                          ),
                          _buildFilterChip(
                            "Interested",
                            selectedStatus == 'Interested',
                            ref,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 5. Leads List
              leads.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No leads match your criteria",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final lead = leads[index];
                          return _buildLeadListItem(context, lead, index);
                        }, childCount: leads.length),
                      ),
                    ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text("Error loading leads: $e"),
              ElevatedButton(
                onPressed: () => ref.refresh(leadsProvider),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
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

  Widget _buildMetricCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, int count, int total, Color color) {
    final double percentage = total > 0 ? count / total : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool selected, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (val) {
          if (val) ref.read(leadsStatusProvider.notifier).set(label);
        },
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white,
        elevation: selected ? 4 : 0,
        side: BorderSide(
          color: selected ? Colors.transparent : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildLeadListItem(BuildContext context, Lead lead, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            debugPrint('🔵 [LEAD_LIST] Clicking lead: ${lead.name}');
            context.push('/crm/lead/${lead.name}');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getStatusColor(lead.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      lead.leadName.isNotEmpty
                          ? lead.leadName[0].toUpperCase()
                          : 'L',
                      style: TextStyle(
                        color: _getStatusColor(lead.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.leadName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (lead.companyName != null)
                        Text(
                          lead.companyName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            lead.status,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          lead.status,
                          style: TextStyle(
                            color: _getStatusColor(lead.status),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0),
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
