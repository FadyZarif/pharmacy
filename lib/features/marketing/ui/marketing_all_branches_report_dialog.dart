import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/marketing/data/models/marketing_coding_metric_model.dart';
import 'package:pharmacy/features/marketing/data/models/marketing_daily_entry_model.dart';
import 'package:pharmacy/features/marketing/logic/marketing_cubit.dart';

enum MarketingReportScope { daily, monthly, range }

Future<void> showMarketingAllBranchesReportDialog(
  BuildContext context, {
  required MarketingReportScope scope,
  required DateTime referenceDate,
  DateTime? rangeFrom,
  DateTime? rangeTo,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _MarketingAllBranchesReportDialog(
      scope: scope,
      referenceDate: referenceDate,
      rangeFrom: rangeFrom,
      rangeTo: rangeTo,
    ),
  );
}

class _BranchReportSummary {
  final String branchId;
  final String branchName;
  final List<MarketingDailyEntry> entries;

  const _BranchReportSummary({
    required this.branchId,
    required this.branchName,
    required this.entries,
  });

  int get employeeCount => entries.map((e) => e.employeeId).toSet().length;

  int get totalCoding =>
      entries.fold(0, (sum, e) => sum + e.newCoding.count);

  int get totalFollowers =>
      entries.fold(0, (sum, e) => sum + e.followers.count);

  int get totalReviews =>
      entries.fold(0, (sum, e) => sum + e.reviews.count);
}

class _MarketingAllBranchesReportDialog extends StatefulWidget {
  final MarketingReportScope scope;
  final DateTime referenceDate;
  final DateTime? rangeFrom;
  final DateTime? rangeTo;

  const _MarketingAllBranchesReportDialog({
    required this.scope,
    required this.referenceDate,
    this.rangeFrom,
    this.rangeTo,
  });

  @override
  State<_MarketingAllBranchesReportDialog> createState() =>
      _MarketingAllBranchesReportDialogState();
}

class _MarketingAllBranchesReportDialogState
    extends State<_MarketingAllBranchesReportDialog> {
  late final Future<List<MarketingDailyEntry>> _future;
  _BranchReportSummary? _selectedBranch;

  @override
  void initState() {
    super.initState();
    final cubit = getIt<MarketingCubit>();
    final branchIds = currentUser.branches.map((b) => b.id).toList();

    _future = switch (widget.scope) {
      MarketingReportScope.daily => cubit.fetchEntriesForDateRaw(
          date: widget.referenceDate,
          branchIds: branchIds,
        ),
      MarketingReportScope.monthly => cubit.fetchEntriesForMonthRaw(
          month: widget.referenceDate,
          branchIds: branchIds,
        ),
      MarketingReportScope.range => cubit.fetchEntriesForRangeRaw(
          from: widget.rangeFrom!,
          to: widget.rangeTo!,
          branchIds: branchIds,
        ),
    };
  }

  String get _dateTitle {
    return switch (widget.scope) {
      MarketingReportScope.daily =>
        DateFormat('MMM dd, yyyy').format(widget.referenceDate),
      MarketingReportScope.monthly =>
        DateFormat('MMMM yyyy').format(widget.referenceDate),
      MarketingReportScope.range =>
        '${DateFormat('MMM dd, yyyy').format(widget.rangeFrom!)} → ${DateFormat('MMM dd, yyyy').format(widget.rangeTo!)}',
    };
  }

  String get _emptyMessage {
    return switch (widget.scope) {
      MarketingReportScope.daily => 'لا توجد سجلات تسويق في هذا اليوم',
      MarketingReportScope.monthly => 'لا توجد سجلات تسويق في هذا الشهر',
      MarketingReportScope.range => 'لا توجد سجلات تسويق في هذه الفترة',
    };
  }

  bool get _showEntryDate => widget.scope != MarketingReportScope.daily;

  List<_BranchReportSummary> _buildBranchSummaries(
    List<MarketingDailyEntry> entries,
  ) {
    final grouped = <String, _BranchReportSummary>{};
    for (final entry in entries) {
      final key = entry.branchId.isNotEmpty ? entry.branchId : entry.branchName;
      final existing = grouped[key];
      if (existing == null) {
        grouped[key] = _BranchReportSummary(
          branchId: entry.branchId,
          branchName: entry.branchName.isEmpty ? 'فرع غير محدد' : entry.branchName,
          entries: [entry],
        );
      } else {
        grouped[key] = _BranchReportSummary(
          branchId: existing.branchId,
          branchName: existing.branchName,
          entries: [...existing.entries, entry],
        );
      }
    }

    final branches = grouped.values.toList()
      ..sort((a, b) => a.branchName.compareTo(b.branchName));
    return branches;
  }

  Map<String, List<MarketingDailyEntry>> _groupByEmployee(
    List<MarketingDailyEntry> entries,
  ) {
    final grouped = <String, List<MarketingDailyEntry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.employeeId, () => []).add(entry);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 640, maxWidth: 520),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ReportHeader(
              title: _selectedBranch == null
                  ? 'Marketing Report'
                  : _selectedBranch!.branchName,
              subtitle: _dateTitle,
              showBack: _selectedBranch != null,
              onBack: () => setState(() => _selectedBranch = null),
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<MarketingDailyEntry>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: ColorsManger.primary),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final entries = snapshot.data ?? [];
                  if (entries.isEmpty) {
                    return Center(child: Text(_emptyMessage));
                  }

                  if (_selectedBranch != null) {
                    return _BranchDetailView(
                      branch: _selectedBranch!,
                      employees: _groupByEmployee(_selectedBranch!.entries),
                      showEntryDate: _showEntryDate,
                    );
                  }

                  final branches = _buildBranchSummaries(entries);
                  var totalCoding = 0;
                  var totalFollowers = 0;
                  var totalReviews = 0;
                  for (final e in entries) {
                    totalCoding += e.newCoding.count;
                    totalFollowers += e.followers.count;
                    totalReviews += e.reviews.count;
                  }

                  return ListView(
                    children: [
                      _TotalsBanner(
                        branches: branches.length,
                        employees: entries.map((e) => e.employeeId).toSet().length,
                        coding: totalCoding,
                        followers: totalFollowers,
                        reviews: totalReviews,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اضغط على الفرع لعرض تفاصيل الموظفين',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.50),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...branches.map(
                        (branch) => _BranchListTile(
                          branch: branch,
                          onTap: () => setState(() => _selectedBranch = branch),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBack;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const _ReportHeader({
    required this.title,
    required this.subtitle,
    required this.showBack,
    required this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack)
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'رجوع للفروع',
          )
        else
          const Icon(
            Icons.campaign_outlined,
            color: ColorsManger.primary,
            size: 30,
          ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

class _TotalsBanner extends StatelessWidget {
  final int branches;
  final int employees;
  final int coding;
  final int followers;
  final int reviews;

  const _TotalsBanner({
    required this.branches,
    required this.employees,
    required this.coding,
    required this.followers,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorsManger.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorsManger.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$branches فرع • $employees موظف',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Coding: $coding • Followers: $followers • Reviews: $reviews',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withValues(alpha: 0.70),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchListTile extends StatelessWidget {
  final _BranchReportSummary branch;
  final VoidCallback onTap;

  const _BranchListTile({
    required this.branch,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorsManger.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: ColorsManger.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.branchName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${branch.employeeCount} موظف • Coding: ${branch.totalCoding} • Followers: ${branch.totalFollowers} • Reviews: ${branch.totalReviews}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.60),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.black.withValues(alpha: 0.40),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BranchDetailView extends StatelessWidget {
  final _BranchReportSummary branch;
  final Map<String, List<MarketingDailyEntry>> employees;
  final bool showEntryDate;

  const _BranchDetailView({
    required this.branch,
    required this.employees,
    required this.showEntryDate,
  });

  @override
  Widget build(BuildContext context) {
    final employeeEntries = employees.entries.toList()
      ..sort((a, b) {
        final nameA = a.value.first.employeeName;
        final nameB = b.value.first.employeeName;
        return nameA.compareTo(nameB);
      });

    return ListView(
      children: [
        _TotalsBanner(
          branches: 1,
          employees: branch.employeeCount,
          coding: branch.totalCoding,
          followers: branch.totalFollowers,
          reviews: branch.totalReviews,
        ),
        const SizedBox(height: 14),
        ...employeeEntries.map((group) {
          final entries = group.value;
          final employeeName = entries.first.employeeName;
          return _EmployeeDetailCard(
            employeeName: employeeName,
            entries: entries,
            showEntryDate: showEntryDate,
          );
        }),
      ],
    );
  }
}

class _EmployeeDetailCard extends StatelessWidget {
  final String employeeName;
  final List<MarketingDailyEntry> entries;
  final bool showEntryDate;

  const _EmployeeDetailCard({
    required this.employeeName,
    required this.entries,
    required this.showEntryDate,
  });

  @override
  Widget build(BuildContext context) {
    final coding = entries.fold(0, (s, e) => s + e.newCoding.count);
    final followers = entries.fold(0, (s, e) => s + e.followers.count);
    final reviews = entries.fold(0, (s, e) => s + e.reviews.count);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          employeeName,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        subtitle: Text(
          showEntryDate
              ? '${entries.length} يوم • Coding: $coding • Followers: $followers • Reviews: $reviews'
              : 'Coding: $coding • Followers: $followers • Reviews: $reviews',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
        children: entries
            .map(
              (entry) => _EmployeeEntryDetails(
                entry: entry,
                showEntryDate: showEntryDate,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _EmployeeEntryDetails extends StatelessWidget {
  final MarketingDailyEntry entry;
  final bool showEntryDate;

  const _EmployeeEntryDetails({
    required this.entry,
    required this.showEntryDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorsManger.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorsManger.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showEntryDate) ...[
            Text(
              entry.dateKey,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.50),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
          ],
          _codingSection(entry.newCoding),
          _line('Followers', entry.followers.count, entry.followers.names),
          _line('Reviews', entry.reviews.count, entry.reviews.names),
        ],
      ),
    );
  }

  Widget _codingSection(MarketingCodingMetric metric) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Coding: ${metric.count}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          ...metric.items.map(
            (item) => Text(
              '• ${item.name} — ${item.code.isEmpty ? 'بدون كود' : item.code}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.70),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, int count, List<String> names) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: $count', style: const TextStyle(fontWeight: FontWeight.w600)),
          if (names.isNotEmpty)
            Text(
              names.map((n) => '• $n').join('\n'),
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.70),
              ),
            ),
        ],
      ),
    );
  }
}
