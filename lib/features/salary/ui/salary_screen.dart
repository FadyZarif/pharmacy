import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/salary/data/models/employee_monthly_salary.dart';
import 'package:pharmacy/features/salary/data/models/month_salary_model.dart';
import 'package:pharmacy/features/salary/logic/salary_cubit.dart';
import 'package:pharmacy/features/salary/logic/salary_state.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {

  late DateTime _selectedDate;
  EmployeeMonthlySalary? _currentSalary;
  late final SalaryCubit _salaryCubit;

  @override
  void initState() {
    super.initState();
    // تحديد الشهر الحالي تلقائياً
    final now = DateTime.now();
    _selectedDate = now;
    _salaryCubit = getIt<SalaryCubit>();
    // جلب البيانات مرة واحدة فقط
    _salaryCubit.fetchSalaryByMonthKey(_monthKey);
  }

  String get _monthKey => MonthSalaryModel.createMonthKey(_selectedDate.year, _selectedDate.month);

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _salaryCubit,
      child: Scaffold(
        backgroundColor: ColorsManger.primaryBackground,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.56),
              border: Border(
                bottom: BorderSide(
                  color: ColorsManger.primary.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: Text(
                'Salary',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.80),
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            const _SalaryBackground(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + kToolbarHeight + 12,
                16,
                0,
              ),
              child: BlocConsumer<SalaryCubit, SalaryState>(
                listener: (context, state) {
                  if (state is SingleSalaryLoaded) {
                    setState(() {
                      _currentSalary = state.salary;
                    });
                  }
                },
                builder: (context, state) {
                  if (state is SalaryLoading) {
                    return Column(
                      children: [
                        _buildMonthSelector(context),
                        const SizedBox(height: 12),
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(color: ColorsManger.primary),
                          ),
                        ),
                      ],
                    );
                  } else if (state is SalaryError) {
                    return Column(
                      children: [
                        _buildMonthSelector(context),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Center(
                            child: _PanelCard(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 56,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No Data',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    state.error,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black.withValues(alpha: 0.55),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else if (_currentSalary != null) {
                    return Column(
                      children: [
                        _buildMonthSelector(context),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                            child: SalaryDetailsCard(monthlySalary: _currentSalary!),
                          ),
                        ),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    return _PanelCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Month Button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: ColorsManger.primary),
            onPressed: () {
              setState(() {
                if (_selectedDate.month == 1) {
                  _selectedDate = DateTime(_selectedDate.year - 1, 12);
                } else {
                  _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
                }
                _currentSalary = null; // Clear current data
              });
              // جلب بيانات الشهر الجديد
              _salaryCubit.fetchSalaryByMonthKey(_monthKey);
            },
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: ColorsManger.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorsManger.primary.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: ColorsManger.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  DateFormat.yMMMM().format(_selectedDate),
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.78),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          // Next Month Button
          IconButton(
            icon: Icon(
              Icons.arrow_forward,
              color: _selectedDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))
                  ? ColorsManger.primary
                  : Colors.grey,
            ),
            onPressed: _selectedDate.isBefore(
              DateTime.now().subtract(const Duration(days: 1)),
            )? () {
              setState(() {
                if (_selectedDate.month == 12) {
                  _selectedDate = DateTime(_selectedDate.year + 1, 1);
                } else {
                  _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
                }
                _currentSalary = null; // Clear current data
              });
              // جلب بيانات الشهر الجديد
              _salaryCubit.fetchSalaryByMonthKey(_monthKey);
            }: null,
          )
        ],
      ),
    );
  }

}

class SalaryDetailsCard extends StatelessWidget {
  final EmployeeMonthlySalary monthlySalary;

  const SalaryDetailsCard({super.key, required this.monthlySalary});

  @override
  Widget build(BuildContext context) {
    // متغير محلي لسهولة الوصول
    final salary = monthlySalary.salaryData;
    final monthInfo = monthlySalary.monthInfo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'المعلومات الأساسية',
          child: Column(
            children: [
              _InfoRow(label: 'كود الصيدلية', value: salary.pharmacyCode),
              _InfoRow(label: 'اسم الصيدلية', value: salary.pharmacyName),
              _InfoRow(label: 'ACC', value: salary.acc),
              _InfoRow(label: 'Name', value: salary.nameEnglish),
              _InfoRow(label: 'الاسم', value: salary.nameArabic),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _SectionCard(
          title: 'نظام العمل بالساعات',
          child: Column(
            children: [
              _InfoRow(label: 'الساعه الشهريه = مبلغ', value: salary.hourlyRate),
              _InfoRow(label: 'نظام العمل بالساعات', value: salary.hoursWorked),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _SectionCard(
          title: 'المرتب والحوافز',
          child: Column(
            children: [
              _InfoRow(label: 'المرتب', value: salary.basicSalary),
              _InfoRow(label: 'الحافز', value: salary.incentive),
              _InfoRow(label: 'الاضافى', value: salary.additional),
              _InfoRow(label: 'حوافز مبيعات تبديل ربع سنوى', value: salary.quarterlySalesIncentive),
              _InfoRow(label: 'مكافئه عن العمل', value: salary.workBonus),
              _InfoRow(label: 'المكافئات الادارايه', value: salary.administrativeBonus),
              _InfoRow(label: 'بدل مواصلات', value: salary.transportAllowance),
              _InfoRow(label: 'صاحب عمل', value: salary.employerShare),
              _InfoRow(label: 'العيديات', value: salary.eideya),
              const SizedBox(height: 8),
              _TotalRow(
                label: 'إجمالي الحوافز',
                value: salary.totalBonuses,
                tint: Colors.blue,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _SectionCard(
          title: 'الخصومات',
          child: Column(
            children: [
              _InfoRow(label: 'الخصم بالساعات', value: salary.hourlyDeduction),
              _InfoRow(label: 'جزاءات', value: salary.penalties),
              _InfoRow(label: 'خصم من كود السحب الدوائى', value: salary.pharmacyCodeDeduction),
              _InfoRow(label: 'خصم مصاريف فتح فيزا', value: salary.visaDeduction),
              _InfoRow(label: 'خصم سلف', value: salary.advanceDeduction),
              _InfoRow(label: 'خصم عجز الشيفتات الربع سنوى', value: salary.quarterlyShiftDeficitDeduction),
              _InfoRow(label: 'خصم تامينات', value: salary.insuranceDeduction),
              const SizedBox(height: 8),
              _TotalRow(
                label: 'إجمالي الخصومات',
                value: salary.totalDeductions,
                tint: Colors.red,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _SectionCard(
          title: 'النتيجة النهائية',
          child: Column(
            children: [
              _TotalRow(
                label: 'ما يستحقة العامل',
                value: salary.netSalary,
                tint: Colors.green,
              ),
              _InfoRow(label: 'المتبقي من السلف على العامل', value: salary.remainingAdvance),
            ],
          ),
        ),

        // Notes
        if (salary.notes != null && salary.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: 'ملاحظات',
            child: _InfoRow(label: 'ملاحظات', value: salary.notes!, maxLines: 3),
          ),
        ],

        // Upload Date
        if (monthInfo.uploadedAt != null) ...[
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Uploaded: ${_formatDate(monthInfo.uploadedAt!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SalaryBackground extends StatelessWidget {
  const _SalaryBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColorsManger.primary.withValues(alpha: 0.08),
            ColorsManger.primaryBackground,
            ColorsManger.primaryBackground,
          ],
        ),
      ),
    );
  }
}

List<BoxShadow> _panelShadow() => [
      BoxShadow(
        color: ColorsManger.primary.withValues(alpha: 0.14),
        blurRadius: 22,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ];

class _PanelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _PanelCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.16)),
        boxShadow: _panelShadow(),
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.black.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final int maxLines;

  const _InfoRow({
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Text(
              value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.black.withValues(alpha: 0.80),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color tint;

  const _TotalRow({
    required this.label,
    required this.value,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: tint,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: tint,
            ),
          ),
        ],
      ),
    );
  }
}

