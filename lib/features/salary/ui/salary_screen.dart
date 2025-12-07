import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/core/widgets/app_text_form_field.dart';
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
        appBar: AppBar(
          backgroundColor: ColorsManger.primary,
          foregroundColor: Colors.white,
          title: const Text('Salary',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
          centerTitle: true,
        ),
        body: BlocConsumer<SalaryCubit, SalaryState>(
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
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
              );
            } else if (state is SalaryError) {
              return Column(
                children: [
                  _buildMonthSelector(context),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Data',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              state.error,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else if (_currentSalary != null) {
              return Column(
                children: [
                  _buildMonthSelector(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
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
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColorsManger.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Month Button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  DateFormat.yMMMM().format(_selectedDate),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Next Month Button
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
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
        // Basic Information
        _buildSectionTitle('المعلومات الأساسية'),
        const SizedBox(height: 12),
        _buildReadOnlyField('كود الصيدلية', salary.pharmacyCode),
        const SizedBox(height: 12),
        _buildReadOnlyField('اسم الصيدلية', salary.pharmacyName),
        const SizedBox(height: 12),
        _buildReadOnlyField('ACC', salary.acc),
        const SizedBox(height: 12),
        _buildReadOnlyField('Name', salary.nameEnglish),
        const SizedBox(height: 12),
        _buildReadOnlyField('الاسم', salary.nameArabic),

        const SizedBox(height: 24),

        // Hourly Work System
        _buildSectionTitle('نظام العمل بالساعات'),
        const SizedBox(height: 12),
        _buildReadOnlyField('الساعه الشهريه = مبلغ', salary.hourlyRate),
        const SizedBox(height: 12),
        _buildReadOnlyField('نظام العمل بالساعات', salary.hoursWorked),

        const SizedBox(height: 24),

        // Salary & Bonuses
        _buildSectionTitle('المرتب والحوافز'),
        const SizedBox(height: 12),
        _buildReadOnlyField('المرتب', salary.basicSalary),
        const SizedBox(height: 12),
        _buildReadOnlyField('الحافز', salary.incentive),
        const SizedBox(height: 12),
        _buildReadOnlyField('الاضافى', salary.additional),
        const SizedBox(height: 12),
        _buildReadOnlyField('حوافز مبيعات تبديل ربع سنوى', salary.quarterlySalesIncentive),
        const SizedBox(height: 12),
        _buildReadOnlyField('مكافئه عن العمل', salary.workBonus),
        const SizedBox(height: 12),
        _buildReadOnlyField('المكافئات الادارايه', salary.administrativeBonus),
        const SizedBox(height: 12),
        _buildReadOnlyField('بدل مواصلات', salary.transportAllowance),
        const SizedBox(height: 12),
        _buildReadOnlyField('صاحب عمل', salary.employerShare),
        const SizedBox(height: 12),
        _buildReadOnlyField('العيديات', salary.eideya),
        const SizedBox(height: 12),
        _buildReadOnlyField('إجمالي الحوافز', salary.totalBonuses, fillColor: Colors.blue.shade50),

        const SizedBox(height: 24),

        // Deductions
        _buildSectionTitle('الخصومات'),
        const SizedBox(height: 12),
        _buildReadOnlyField('الخصم بالساعات', salary.hourlyDeduction),
        const SizedBox(height: 12),
        _buildReadOnlyField('جزاءات', salary.penalties),
        const SizedBox(height: 12),
        _buildReadOnlyField('خصم من كود السحب الدوائى', salary.pharmacyCodeDeduction),
        const SizedBox(height: 12),
        _buildReadOnlyField('خصم مصاريف فتح فيزا', salary.visaDeduction),
        const SizedBox(height: 12),
        _buildReadOnlyField('خصم سلف', salary.advanceDeduction),
        const SizedBox(height: 12),
        _buildReadOnlyField('خصم عجز الشيفتات الربع سنوى', salary.quarterlyShiftDeficitDeduction),
        const SizedBox(height: 12),
        _buildReadOnlyField('خصم تامينات', salary.insuranceDeduction),
        const SizedBox(height: 12),
        _buildReadOnlyField('إجمالي الخصومات', salary.totalDeductions, fillColor: Colors.red.shade50),

        const SizedBox(height: 24),

        // Final Result
        _buildSectionTitle('النتيجة النهائية'),
        const SizedBox(height: 12),
        _buildReadOnlyField('ما يستحقة العامل', salary.netSalary, fillColor: Colors.green.shade50),
        const SizedBox(height: 12),
        _buildReadOnlyField('المتبقي من السلف على العامل', salary.remainingAdvance),

        // Notes
        if (salary.notes != null && salary.notes!.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionTitle('ملاحظات'),
          const SizedBox(height: 12),
          _buildReadOnlyField('ملاحظات', salary.notes!, maxLines: 3),
        ],

        // Upload Date
        if (monthInfo.uploadedAt != null) ...[
          const SizedBox(height: 24),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, {Color? fillColor, int? maxLines}) {
    return AppTextFormField(
      controller: TextEditingController(text: value),
      labelText: label,
      readOnly: true,
      fillColor: Colors.white,
      maxLines: maxLines ?? 1,
      isArabic: false,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

