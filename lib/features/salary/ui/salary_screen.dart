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
        _buildSectionTitle('Basic Information'),
        const SizedBox(height: 12),
        _buildReadOnlyField('Pharmacy Code', salary.pharmacyCode),
        const SizedBox(height: 12),
        _buildReadOnlyField('Pharmacy Name', salary.pharmacyName),
        const SizedBox(height: 12),
        _buildReadOnlyField('ACC', salary.acc),
        const SizedBox(height: 12),
        _buildReadOnlyField('English Name', salary.nameEnglish),
        const SizedBox(height: 12),
        _buildReadOnlyField('Arabic Name', salary.nameArabic),

        const SizedBox(height: 24),

        // Hourly Work System
        _buildSectionTitle('Hourly Work System'),
        const SizedBox(height: 12),
        _buildReadOnlyField('Hourly Rate', salary.hourlyRate),
        const SizedBox(height: 12),
        _buildReadOnlyField('Hours Worked', salary.hoursWorked),

        const SizedBox(height: 24),

        // Salary & Bonuses
        _buildSectionTitle('Salary & Bonuses'),
        const SizedBox(height: 12),
        _buildReadOnlyField('Basic Salary', salary.basicSalary),
        const SizedBox(height: 12),
        _buildReadOnlyField('Incentive', salary.incentive),
        const SizedBox(height: 12),
        _buildReadOnlyField('Additional', salary.additional),
        const SizedBox(height: 12),
        _buildReadOnlyField('Quarterly Sales Incentive', salary.quarterlySalesIncentive),
        const SizedBox(height: 12),
        _buildReadOnlyField('Work Bonus', salary.workBonus),
        const SizedBox(height: 12),
        _buildReadOnlyField('Administrative Bonus', salary.administrativeBonus),
        const SizedBox(height: 12),
        _buildReadOnlyField('Transport Allowance', salary.transportAllowance),
        const SizedBox(height: 12),
        _buildReadOnlyField('Employer Share', salary.employerShare),
        const SizedBox(height: 12),
        _buildReadOnlyField('Eid Bonus', salary.eideya),
        const SizedBox(height: 12),
        _buildReadOnlyField('Total Bonuses', salary.totalBonuses, fillColor: Colors.blue.shade50),

        const SizedBox(height: 24),

        // Deductions
        _buildSectionTitle('Deductions'),
        const SizedBox(height: 12),
        _buildReadOnlyField('Hourly Deduction', salary.hourlyDeduction),
        const SizedBox(height: 12),
        _buildReadOnlyField('Penalties', salary.penalties),
        const SizedBox(height: 12),
        _buildReadOnlyField('Pharmacy Code Deduction', salary.pharmacyCodeDeduction),
        const SizedBox(height: 12),
        _buildReadOnlyField('Visa Fee Deduction', salary.visaDeduction),
        const SizedBox(height: 12),
        _buildReadOnlyField('Advance Deduction', salary.advanceDeduction),
        const SizedBox(height: 12),
        _buildReadOnlyField('Quarterly Shift Deficit', salary.quarterlyShiftDeficitDeduction),
        const SizedBox(height: 12),
        _buildReadOnlyField('Insurance Deduction', salary.insuranceDeduction),
        const SizedBox(height: 12),
        _buildReadOnlyField('Total Deductions', salary.totalDeductions, fillColor: Colors.red.shade50),

        const SizedBox(height: 24),

        // Final Result
        _buildSectionTitle('Final Result'),
        const SizedBox(height: 12),
        _buildReadOnlyField('Net Salary', salary.netSalary, fillColor: Colors.green.shade50),
        const SizedBox(height: 12),
        _buildReadOnlyField('Remaining Advance', salary.remainingAdvance),

        // Notes
        if (salary.notes != null && salary.notes!.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionTitle('Notes'),
          const SizedBox(height: 12),
          _buildReadOnlyField('Notes', salary.notes!, maxLines: 3),
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

