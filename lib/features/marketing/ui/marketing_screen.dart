import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/core/widgets/app_text_form_field.dart';
import 'package:pharmacy/features/marketing/data/models/marketing_coding_metric_model.dart';
import 'package:pharmacy/features/marketing/data/models/marketing_daily_entry_model.dart';
import 'package:pharmacy/features/marketing/data/models/marketing_metric_model.dart';
import 'package:pharmacy/features/marketing/logic/marketing_cubit.dart';
import 'package:pharmacy/features/marketing/logic/marketing_state.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _CodingRow {
  final TextEditingController nameController;
  final TextEditingController codeController;

  _CodingRow({String name = '', String code = ''})
      : nameController = TextEditingController(text: name),
        codeController = TextEditingController(text: code);

  void dispose() {
    nameController.dispose();
    codeController.dispose();
  }
}

class _MarketingScreenState extends State<MarketingScreen> {
  late final MarketingCubit _cubit;
  final _formKey = GlobalKey<FormState>();

  final _newCodingRows = <_CodingRow>[];
  final _followersControllers = <TextEditingController>[];
  final _reviewsControllers = <TextEditingController>[];

  MarketingDailyEntry? _existing;
  bool _isReadOnly = false;
  bool _initialized = false;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  MarketingMonthSummary? _monthSummary;
  MarketingDailyEntry? _viewingPastEntry;

  bool get _isViewingToday => _viewingPastEntry == null;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<MarketingCubit>()..loadStaffDashboard(month: _selectedMonth);
  }

  @override
  void dispose() {
    for (final row in _newCodingRows) {
      row.dispose();
    }
    _disposeControllers(_followersControllers);
    _disposeControllers(_reviewsControllers);
    super.dispose();
  }

  void _disposeControllers(List<TextEditingController> controllers) {
    for (final c in controllers) {
      c.dispose();
    }
  }

  void _loadFromEntry(MarketingDailyEntry? entry, {required bool isReadOnly}) {
    _existing = entry;
    _isReadOnly = isReadOnly;
    _setCodingRows(entry?.newCoding.items ?? []);
    _setControllers(_followersControllers, entry?.followers.names ?? []);
    _setControllers(_reviewsControllers, entry?.reviews.names ?? []);
    _initialized = true;
  }

  void _setCodingRows(List<MarketingCodingItem> items) {
    for (final row in _newCodingRows) {
      row.dispose();
    }
    _newCodingRows.clear();
    if (items.isEmpty) {
      _newCodingRows.add(_CodingRow());
      return;
    }
    for (final item in items) {
      _newCodingRows.add(_CodingRow(name: item.name, code: item.code));
    }
  }

  void _setControllers(List<TextEditingController> controllers, List<String> names) {
    _disposeControllers(controllers);
    controllers.clear();
    if (names.isEmpty) {
      controllers.add(TextEditingController());
      return;
    }
    for (final name in names) {
      controllers.add(TextEditingController(text: name));
    }
  }

  MarketingCodingMetric _codingFromRows() {
    final items = <MarketingCodingItem>[];
    for (final row in _newCodingRows) {
      final name = row.nameController.text.trim();
      final code = row.codeController.text.trim();
      if (name.isNotEmpty || code.isNotEmpty) {
        items.add(MarketingCodingItem(name: name, code: code));
      }
    }
    return MarketingCodingMetric(count: items.length, items: items);
  }

  void _addCodingRow() {
    if (_isReadOnly) return;
    setState(() => _newCodingRows.add(_CodingRow()));
  }

  void _removeCodingRow(int index) {
    if (_isReadOnly) return;
    setState(() {
      _newCodingRows[index].dispose();
      _newCodingRows.removeAt(index);
      if (_newCodingRows.isEmpty) {
        _newCodingRows.add(_CodingRow());
      }
    });
  }

  MarketingMetric _metricFromControllers(List<TextEditingController> controllers) {
    final names = controllers
        .map((c) => c.text.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    return MarketingMetric(count: names.length, names: names);
  }

  void _addNameField(List<TextEditingController> controllers) {
    if (_isReadOnly) return;
    setState(() {
      controllers.add(TextEditingController());
    });
  }

  void _removeNameField(List<TextEditingController> controllers, int index) {
    if (_isReadOnly) return;
    setState(() {
      controllers[index].dispose();
      controllers.removeAt(index);
      if (controllers.isEmpty) {
        controllers.add(TextEditingController());
      }
    });
  }

  void _goToToday() {
    final todayKey = MarketingDailyEntry.dateKeyFrom(DateTime.now());
    MarketingDailyEntry? todayEntry = _existing;
    for (final e in _monthSummary?.entries ?? const <MarketingDailyEntry>[]) {
      if (e.dateKey == todayKey) {
        todayEntry = e;
        break;
      }
    }
    setState(() {
      _viewingPastEntry = null;
      _existing = todayEntry;
      _isReadOnly = todayEntry != null && !todayEntry.canEdit;
      _loadFromEntry(todayEntry, isReadOnly: _isReadOnly);
    });
  }

  void _viewPastEntry(MarketingDailyEntry entry) {
    setState(() {
      _viewingPastEntry = entry;
      _loadFromEntry(entry, isReadOnly: true);
    });
  }

  void _changeMonth(int delta) {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    if (next.isAfter(currentMonth)) return;
    setState(() {
      _selectedMonth = next;
      _viewingPastEntry = null;
    });
    _cubit.loadStaffDashboard(month: _selectedMonth);
  }

  Future<void> _submit() async {
    if (_isReadOnly) return;
    if (!_formKey.currentState!.validate()) return;

    await _cubit.saveTodayEntry(
      newCoding: _codingFromRows(),
      followers: _metricFromControllers(_followersControllers),
      reviews: _metricFromControllers(_reviewsControllers),
      existing: _existing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayKey = MarketingDailyEntry.dateKeyFrom(now);
    final viewingLabel = _isViewingToday
        ? DateFormat('EEEE, d MMM yyyy').format(now)
        : (_viewingPastEntry?.dateKey ?? todayKey);

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<MarketingCubit, MarketingState>(
        listener: (context, state) async {
          if (state is MarketingStaffDashboardLoaded) {
            _monthSummary = state.monthSummary;
            _selectedMonth = state.monthSummary.month;
            if (_isViewingToday) {
              _existing = state.todayEntry;
              _isReadOnly = state.todayReadOnly;
              if (!_initialized) {
                _loadFromEntry(state.todayEntry, isReadOnly: state.todayReadOnly);
              } else {
                _setCodingRows(state.todayEntry?.newCoding.items ?? []);
                _setControllers(
                  _followersControllers,
                  state.todayEntry?.followers.names ?? [],
                );
                _setControllers(
                  _reviewsControllers,
                  state.todayEntry?.reviews.names ?? [],
                );
              }
            }
            _initialized = true;
            setState(() {});
          }
          if (state is MarketingSaveSuccess) {
            if (!context.mounted) return;
            await defToast2(
              context: context,
              msg: 'تم حفظ سجل التسويق بنجاح',
              dialogType: DialogType.success,
            );
          }
          if (state is MarketingError) {
            if (!context.mounted) return;
            await defToast2(
              context: context,
              msg: state.message,
              dialogType: DialogType.error,
            );
          }
        },
        builder: (context, state) {
          final isSaving = state is MarketingSaveLoading;
          final isLoading = state is MarketingLoading && !_initialized;
          final bottomPad = MediaQuery.of(context).padding.bottom;
          // Hosted inside `EmployeeLayout` (`extendBody: true`, glass nav 66 + padding 14).
          const glassNavHeight = 66.0;
          const glassNavOuterPadding = 14.0;
          final navOverlap = bottomPad + glassNavHeight + glassNavOuterPadding;
          final showSaveBar = _isViewingToday && !_isReadOnly;
          const saveBarHeight = 68.0;
          final listBottomPad = showSaveBar
              ? 16.0
              : navOverlap + 24;

          return Scaffold(
            backgroundColor: ColorsManger.primaryBackground,
            appBar: AppBar(
              title: const Text('Marketing'),
              centerTitle: true,
              backgroundColor: Colors.white,
              foregroundColor: ColorsManger.primary,
              elevation: 0,
            ),
            body: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: ColorsManger.primary),
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, listBottomPad),
                            children: [
                        if (_monthSummary != null) ...[
                          _MonthStatsCard(
                            month: _selectedMonth,
                            summary: _monthSummary!,
                            onPrevious: () => _changeMonth(-1),
                            onNext: () => _changeMonth(1),
                            canGoNext: _selectedMonth.year < now.year ||
                                (_selectedMonth.year == now.year &&
                                    _selectedMonth.month < now.month),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _isViewingToday ? 'سجل اليوم' : 'سجل يوم سابق',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (!_isViewingToday)
                              TextButton(
                                onPressed: _goToToday,
                                child: const Text('العودة لليوم'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _HeaderCard(
                          dateLabel: viewingLabel,
                          branchName: currentUser.currentBranch.name,
                          employeeName: currentUser.name,
                          isReadOnly: _isReadOnly,
                          hasExisting: _isViewingToday
                              ? _existing != null
                              : _viewingPastEntry != null,
                        ),
                        const SizedBox(height: 16),
                        _CodingMetricSection(
                          rows: _newCodingRows,
                          isReadOnly: _isReadOnly,
                          onAdd: _addCodingRow,
                          onRemove: _removeCodingRow,
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: 14),
                        _MetricSection(
                          title: 'Followers',
                          subtitle: 'متابعين جدد لصفحة الفيسبوك',
                          icon: Icons.thumb_up_alt_outlined,
                          color: Colors.indigo,
                          controllers: _followersControllers,
                          isReadOnly: _isReadOnly,
                          onAdd: () => _addNameField(_followersControllers),
                          onRemove: (i) =>
                              _removeNameField(_followersControllers, i),
                          onCountChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: 14),
                        _MetricSection(
                          title: 'Reviews',
                          subtitle: 'مراجعات جديدة على الصفحة',
                          icon: Icons.star_rate_rounded,
                          color: Colors.orange,
                          controllers: _reviewsControllers,
                          isReadOnly: _isReadOnly,
                          onAdd: () => _addNameField(_reviewsControllers),
                          onRemove: (i) =>
                              _removeNameField(_reviewsControllers, i),
                          onCountChanged: () => setState(() {}),
                        ),
                        if (_monthSummary != null &&
                            _monthSummary!.entries.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'سجلات الشهر',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._monthSummary!.entries.map((entry) {
                            final isToday = entry.dateKey == todayKey;
                            final isSelected =
                                _viewingPastEntry?.dateKey == entry.dateKey;
                            return _HistoryDayTile(
                              entry: entry,
                              isToday: isToday,
                              isSelected: isSelected,
                              onTap: isToday
                                  ? _goToToday
                                  : () => _viewPastEntry(entry),
                            );
                          }),
                        ],
                            ],
                          ),
                        ),
                        if (showSaveBar)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.fromLTRB(
                              16,
                              10,
                              16,
                              navOverlap + 8,
                            ),
                            decoration: BoxDecoration(
                              color: ColorsManger.primaryBackground,
                              border: Border(
                                top: BorderSide(
                                  color: ColorsManger.primary.withValues(alpha: 0.12),
                                ),
                              ),
                            ),
                            child: SizedBox(
                              height: saveBarHeight - 20,
                              child: ElevatedButton.icon(
                                onPressed: isSaving ? null : _submit,
                                icon: isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(
                                  _existing == null ? 'حفظ سجل اليوم' : 'تحديث السجل',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorsManger.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _MonthStatsCard extends StatelessWidget {
  final DateTime month;
  final MarketingMonthSummary summary;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoNext;

  const _MonthStatsCard({
    required this.month,
    required this.summary,
    required this.onPrevious,
    required this.onNext,
    required this.canGoNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorsManger.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              IconButton(
                onPressed: canGoNext ? onNext : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.daysRecorded} يوم مسجّل',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statChip('Coding', summary.totalCoding, Colors.blue),
              const SizedBox(width: 8),
              _statChip('Followers', summary.totalFollowers, Colors.indigo),
              const SizedBox(width: 8),
              _statChip('Reviews', summary.totalReviews, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _HistoryDayTile extends StatelessWidget {
  final MarketingDailyEntry entry;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  const _HistoryDayTile({
    required this.entry,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? ColorsManger.primary.withValues(alpha: 0.08) : null,
      child: ListTile(
        onTap: onTap,
        title: Text(
          entry.dateKey,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Coding ${entry.newCoding.count} • Followers ${entry.followers.count} • Reviews ${entry.reviews.count}',
        ),
        trailing: isToday
            ? const Chip(label: Text('اليوم', style: TextStyle(fontSize: 11)))
            : const Icon(Icons.visibility_outlined, size: 20),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String dateLabel;
  final String branchName;
  final String employeeName;
  final bool isReadOnly;
  final bool hasExisting;

  const _HeaderCard({
    required this.dateLabel,
    required this.branchName,
    required this.employeeName,
    required this.isReadOnly,
    required this.hasExisting,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign, color: ColorsManger.primary),
              const SizedBox(width: 8),
              const Text(
                'سجل تسويق اليوم',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('الفرع: $branchName'),
          Text('الموظف: $employeeName'),
          if (hasExisting && isReadOnly) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'انتهت مهلة التعديل (24 ساعة). السجل للعرض فقط.',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700),
              ),
            ),
          ] else if (hasExisting) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'يمكنك تعديل السجل خلال 24 ساعة من أول حفظ.',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CodingMetricSection extends StatelessWidget {
  final List<_CodingRow> rows;
  final bool isReadOnly;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final VoidCallback onChanged;

  const _CodingMetricSection({
    required this.rows,
    required this.isReadOnly,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  int get _filledCount => rows
      .where(
        (r) =>
            r.nameController.text.trim().isNotEmpty &&
            r.codeController.text.trim().isNotEmpty,
      )
      .length;

  @override
  Widget build(BuildContext context) {
    const color = Colors.blue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_2, color: color),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Coding',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'عملاء جدد — الاسم والكود إلزاميان',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'العدد: $_filledCount',
                  style: const TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(rows.length, (index) {
            final row = rows[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: AppTextFormField(
                      controller: row.nameController,
                      hintText: 'اسم العميل ${index + 1}',
                      readOnly: isReadOnly,
                      onChanged: isReadOnly ? null : (_) => onChanged(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: AppTextFormField(
                      controller: row.codeController,
                      hintText: 'الكود',
                      readOnly: isReadOnly,
                      onChanged: isReadOnly ? null : (_) => onChanged(),
                    ),
                  ),
                  if (!isReadOnly && rows.length > 1) ...[
                    IconButton(
                      onPressed: () => onRemove(index),
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    ),
                  ],
                ],
              ),
            );
          }),
          if (!isReadOnly)
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('أضف عميل'),
            ),
        ],
      ),
    );
  }
}

class _MetricSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<TextEditingController> controllers;
  final bool isReadOnly;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final VoidCallback? onCountChanged;

  const _MetricSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.controllers,
    required this.isReadOnly,
    required this.onAdd,
    required this.onRemove,
    this.onCountChanged,
  });

  int get _filledCount =>
      controllers.where((c) => c.text.trim().isNotEmpty).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'العدد: $_filledCount',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(controllers.length, (index) {
            final controller = controllers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextFormField(
                      controller: controller,
                      hintText: 'اسم الشخص ${index + 1}',
                      validator: (value) => null,
                      onChanged: isReadOnly ? null : (_) => onCountChanged?.call(),
                      readOnly: isReadOnly,
                    ),
                  ),
                  if (!isReadOnly && controllers.length > 1) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => onRemove(index),
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    ),
                  ],
                ],
              ),
            );
          }),
          if (!isReadOnly)
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('أضف اسم'),
            ),
        ],
      ),
    );
  }
}
