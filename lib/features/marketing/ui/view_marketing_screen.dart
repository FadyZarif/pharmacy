import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/marketing/data/models/marketing_coding_metric_model.dart';
import 'package:pharmacy/features/marketing/data/models/marketing_daily_entry_model.dart';
import 'package:pharmacy/features/marketing/logic/marketing_cubit.dart';
import 'package:pharmacy/features/marketing/logic/marketing_state.dart';

class ViewMarketingScreen extends StatefulWidget {
  const ViewMarketingScreen({super.key});

  @override
  State<ViewMarketingScreen> createState() => _ViewMarketingScreenState();
}

class _ViewMarketingScreenState extends State<ViewMarketingScreen> {
  late final MarketingCubit _cubit;
  DateTime _selectedDate = DateTime.now();
  String? _selectedBranchId;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<MarketingCubit>();
    _load();
  }

  void _load() {
    _cubit.fetchEntriesForDate(
      date: _selectedDate,
      branchId: _selectedBranchId,
    );
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final branches = currentUser.branches;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: ColorsManger.primaryBackground,
        appBar: AppBar(
          title: const Text('Marketing'),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: ColorsManger.primary,
          elevation: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                      });
                      _load();
                    },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat('d MMM yyyy').format(_selectedDate),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isToday
                        ? null
                        : () {
                            setState(() {
                              _selectedDate = _selectedDate.add(const Duration(days: 1));
                            });
                            _load();
                          },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            if (currentUser.isManagement && branches.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<String?>(
                  value: _selectedBranchId,
                  decoration: InputDecoration(
                    labelText: 'الفرع',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('كل الفروع'),
                    ),
                    ...branches.map(
                      (b) => DropdownMenuItem<String?>(
                        value: b.id,
                        child: Text(b.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedBranchId = value);
                    _load();
                  },
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<MarketingCubit, MarketingState>(
                builder: (context, state) {
                  if (state is MarketingListLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: ColorsManger.primary),
                    );
                  }
                  if (state is MarketingError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is! MarketingListLoaded) {
                    return const SizedBox.shrink();
                  }

                  if (state.entries.isEmpty) {
                    return const Center(
                      child: Text('لا توجد سجلات تسويق في هذا اليوم'),
                    );
                  }

                  final totals = _computeTotals(state.entries);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    children: [
                      _TotalsCard(totals: totals),
                      const SizedBox(height: 12),
                      ...state.entries.map((e) => _EntryCard(entry: e)),
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

  _MarketingTotals _computeTotals(List<MarketingDailyEntry> entries) {
    var coding = 0;
    var followers = 0;
    var reviews = 0;
    for (final e in entries) {
      coding += e.newCoding.count;
      followers += e.followers.count;
      reviews += e.reviews.count;
    }
    return _MarketingTotals(
      newCoding: coding,
      followers: followers,
      reviews: reviews,
      employees: entries.length,
    );
  }
}

class _MarketingTotals {
  final int newCoding;
  final int followers;
  final int reviews;
  final int employees;

  const _MarketingTotals({
    required this.newCoding,
    required this.followers,
    required this.reviews,
    required this.employees,
  });
}

class _TotalsCard extends StatelessWidget {
  final _MarketingTotals totals;

  const _TotalsCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsManger.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إجمالي اليوم (${totals.employees} موظف)',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _totalChip('Coding', totals.newCoding),
              const SizedBox(width: 8),
              _totalChip('Followers', totals.followers),
              const SizedBox(width: 8),
              _totalChip('Reviews', totals.reviews),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalChip(String label, int value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final MarketingDailyEntry entry;

  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.employeeName,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            Text(
              entry.branchName,
              style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 10),
            _codingRow(entry.newCoding),
            _metricRow('Followers', entry.followers.count, entry.followers.names),
            _metricRow('Reviews', entry.reviews.count, entry.reviews.names),
          ],
        ),
      ),
    );
  }

  Widget _codingRow(MarketingCodingMetric metric) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Coding: ${metric.count}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (metric.items.isNotEmpty)
            ...metric.items.map(
              (item) => Text(
                item.code.isEmpty
                    ? item.name
                    : '${item.name} — كود: ${item.code}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.65),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, int count, List<String> names) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: $count',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (names.isNotEmpty)
            Text(
              names.join(' • '),
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.65),
              ),
            ),
        ],
      ),
    );
  }
}
