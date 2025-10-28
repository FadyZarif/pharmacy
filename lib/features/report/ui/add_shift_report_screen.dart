import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/core/widgets/app_text_form_field.dart';
import 'package:pharmacy/features/report/data/models/daily_report_model.dart';
import 'package:pharmacy/features/report/logic/shift_report_cubit.dart';
import 'package:pharmacy/features/report/logic/shift_report_state.dart';
import 'package:intl/intl.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

import '../../employee/logic/employee_layout_cubit.dart';

class AddShiftReportScreen extends StatefulWidget {
  const AddShiftReportScreen({super.key});

  @override
  State<AddShiftReportScreen> createState() => _AddShiftReportScreenState();
}

class _AddShiftReportScreenState extends State<AddShiftReportScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _drawerAmountController = TextEditingController();
  final TextEditingController _computerDifferenceController = TextEditingController();
  final TextEditingController _electronicWalletController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Selected values
  ShiftType? _selectedShiftType;
  ComputerDifferenceType? _computerDifferenceType;

  // Expenses list
  final List<ExpenseItem> _expenses = [];

  @override
  void dispose() {
    _drawerAmountController.dispose();
    _computerDifferenceController.dispose();
    _electronicWalletController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ShiftReportCubit>()..loadMyTodayShift(),
      child: BlocConsumer<ShiftReportCubit, ShiftReportState>(
        listener: (context, state) {
          if (state is ShiftReportSubmitted) {
            defToast2(
              context: context,
              msg: 'Report submitted successfully',
              dialogType: DialogType.success,
            ).then((_) {
              if (!context.mounted) return;
              getIt<EmployeeLayoutCubit>().changeBottomNav(2);
            });
          } else if (state is ShiftReportError) {
            defToast2(
              context: context,
              msg: state.message,
              dialogType: DialogType.error,
            );
          } else if (state is ShiftReportValidationError) {
            defToast2(
              context: context,
              msg: state.message,
              dialogType: DialogType.warning,
            );
          } else if (state is ShiftAlreadyExists) {
            // Shift already submitted - show read-only view or go back
            defToast2(
              context: context,
              msg: 'This shift has already been submitted and cannot be edited',
              dialogType: DialogType.info,
            ).then((_) {
              if (!context.mounted) return;
              Navigator.pop(context);
            });
          } else if (state is ShiftReportLoaded) {
            // Load existing data into controllers
            _drawerAmountController.text = state.report.drawerAmount.toString();
            _computerDifferenceController.text = state.report.computerDifference.toString();
            _electronicWalletController.text = state.report.electronicWalletAmount.toString();
            _notesController.text = state.report.notes ?? '';
            setState(() {
              _selectedShiftType = state.report.shiftType;
              _computerDifferenceType = state.report.computerDifferenceType;
              _expenses.clear();
              _expenses.addAll(state.report.expenses);
            });
          } else if (state is ExpenseAdded || state is ExpenseRemoved) {
            setState(() {
              // Refresh UI
            });
          }
        },
        builder: (context, state) {
          final cubit = context.read<ShiftReportCubit>();
          final isLoading = state is ShiftReportLoading;

          return Scaffold(
            backgroundColor: ColorsManger.primaryBackground,
            appBar: AppBar(
              title: const Text(
                'Shift Report',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              backgroundColor: ColorsManger.primary,
            ),
            body: Stack(
              children: [
                Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // معلومات ثابتة (غير قابلة للتعديل)
                        _buildInfoSection(),

                        const SizedBox(height: 24),

                        // اختيار نوع الوردية
                        _buildShiftTypeSelector(cubit),

                        const SizedBox(height: 20),

                        // إدخال الدرج
                        _buildDrawerAmountField(cubit),

                        const SizedBox(height: 20),

                        // إدخال فرق الكمبيوتر
                        _buildComputerDifferenceSection(cubit),

                        const SizedBox(height: 20),

                        // المحفظة الإلكترونية
                        _buildElectronicWalletField(cubit),

                        const SizedBox(height: 20),

                        // الملاحظات
                        _buildNotesField(cubit),

                        const SizedBox(height: 24),

                        // قسم المصاريف
                        _buildExpensesSection(cubit),

                        const SizedBox(height: 32),

                        // زر الحفظ
                        _buildSubmitButton(cubit, isLoading),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                if (isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection() {
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branch Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.store, color: ColorsManger.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Branch',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  currentUser.branchName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          // Date Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: ColorsManger.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  dateFormat.format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftTypeSelector(ShiftReportCubit cubit) {
    // Get available shifts (not submitted yet)
    final availableShifts = ShiftType.values
        .where((shift) => !cubit.submittedShifts.contains(shift))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Shift Type *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            if (cubit.submittedShifts.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  '${cubit.submittedShifts.length} shift(s) already submitted',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (availableShifts.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All shifts for today have been submitted',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedShiftType == null ? Colors.grey.shade300 : ColorsManger.primary,
                width: 1.5,
              ),
            ),
            child: DropdownButtonFormField<ShiftType>(
              isExpanded: true,
              value: _selectedShiftType,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
                hintText: 'Select shift type',
              ),
              items: availableShifts.map((type) {
                String label;
                IconData icon;
                switch (type) {
                  case ShiftType.midnight:
                    label = 'Midnight (12 AM - 8 AM)';
                    icon = Icons.bedtime;
                    break;
                  case ShiftType.morning:
                    label = 'Morning (8 AM - 4 PM)';
                    icon = Icons.wb_sunny_outlined;
                    break;
                  case ShiftType.afternoon:
                    label = 'Afternoon (4 PM - 12 AM)';
                    icon = Icons.wb_twilight;
                    break;
                  case ShiftType.evening:
                    label = 'Evening (8 PM - 4 AM)';
                    icon = Icons.dark_mode_outlined;
                    break;
                }

                return DropdownMenuItem<ShiftType>(
                  value: type,
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: ColorsManger.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedShiftType = value;
                });
              },
              validator: (value) {
                if (value == null && availableShifts.isNotEmpty) {
                  return 'Please select shift type';
                }
                return null;
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDrawerAmountField(ShiftReportCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Drawer Amount (Sales) *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        AppTextFormField(
          controller: _drawerAmountController,
          labelText: 'Enter total sales amount',
          prefixIcon: const Icon(Icons.attach_money),
          keyboardType: TextInputType.number,
          fillColor: Colors.white,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter drawer amount';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildComputerDifferenceSection(ShiftReportCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Computer Difference',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        // اختيار نوع الفرق (عجز/زيادة/لا يوجد)
        Row(
          children: [
            Expanded(
              child: _buildDifferenceTypeButton(
                'None',
                ComputerDifferenceType.none,
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDifferenceTypeButton(
                'Shortage',
                ComputerDifferenceType.shortage,
                Icons.remove_circle,
                Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDifferenceTypeButton(
                'Excess',
                ComputerDifferenceType.excess,
                Icons.add_circle,
                Colors.blue,
              ),
            ),
          ],
        ),

        // حقل إدخال المبلغ (يظهر إذا اختار عجز أو زيادة)
        if (_computerDifferenceType != null && _computerDifferenceType != ComputerDifferenceType.none) ...[
          const SizedBox(height: 12),
          AppTextFormField(
            controller: _computerDifferenceController,
            labelText: 'Enter ${_computerDifferenceType == ComputerDifferenceType.shortage ? "shortage" : "excess"} amount',
            prefixIcon: Icon(
              _computerDifferenceType == ComputerDifferenceType.shortage
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
            ),
            fillColor: Colors.white,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) {
              if (_computerDifferenceType != ComputerDifferenceType.none) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDifferenceTypeButton(
    String label,
    ComputerDifferenceType type,
    IconData icon,
    Color color,
  ) {
    final isSelected = _computerDifferenceType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _computerDifferenceType = type;
          if (type == ComputerDifferenceType.none) {
            _computerDifferenceController.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElectronicWalletField(ShiftReportCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Electronic Wallet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        AppTextFormField(
          controller: _electronicWalletController,
          labelText: 'Enter electronic wallet balance',
          prefixIcon: const Icon(Icons.account_balance_wallet),
          fillColor: Colors.white,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesField(ShiftReportCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        AppTextFormField(
          controller: _notesController,
          labelText: 'Add any additional notes',
          fillColor: Colors.white,
          maxLines: 3,
          maxLength: 200,
        ),
      ],
    );
  }

  Widget _buildExpensesSection(ShiftReportCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Expenses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showAddExpenseDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Expense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManger.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_expenses.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No expenses yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              ..._expenses.map((expense) => _buildExpenseCard(expense)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorsManger.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Expenses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'EGP ${_calculateTotalExpenses().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ColorsManger.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildExpenseCard(ExpenseItem expense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ColorsManger.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.receipt,
              color: ColorsManger.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (expense.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    expense.notes!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'EGP ${expense.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorsManger.primary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              setState(() {
                _expenses.remove(expense);
              });
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ShiftReportCubit cubit, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _handleSubmit(cubit),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsManger.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Submit Report',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  double _calculateTotalExpenses() {
    return _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  void _showAddExpenseDialog() {
    ExpenseType? selectedType;
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Additional fields based on expense type
    String? deliveryArea;
    String? companyName;
    String? warehouseName;
    ElectronicPaymentMethod? electronicMethod;
    AdministrativeStaff? administrativeStaff;
    GovernmentExpenseType? governmentType;
    String? otherDescription;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Expense'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Expense Type Dropdown
                    DropdownButtonFormField<ExpenseType>(
                      isExpanded: true, // <-- allow full width to avoid tiny overflow
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Expense Type *',
                        border: OutlineInputBorder(),
                      ),
                      items: ExpenseType.values.map((type) {
                        String label;
                        switch (type) {
                          case ExpenseType.medicines:
                            label = 'Medicines (Cash Alternative)';
                            break;
                          case ExpenseType.delivery:
                            label = 'Delivery';
                            break;
                          case ExpenseType.ahmedAboghnima:
                            label = 'Ahmed Aboghnima';
                            break;
                          case ExpenseType.companyCollection:
                            label = 'Company Collection';
                            break;
                          case ExpenseType.warehouseCollection:
                            label = 'Warehouse Collection';
                            break;
                          case ExpenseType.electronicPayment:
                            label = 'Electronic Payment';
                            break;
                          case ExpenseType.administrative:
                            label = 'Administrative Expenses';
                            break;
                          case ExpenseType.accounting:
                            label = 'Accounting Expenses';
                            break;
                          case ExpenseType.government:
                            label = 'Government Expenses';
                            break;
                          case ExpenseType.other:
                            label = 'Other';
                            break;
                        }
                        return DropdownMenuItem(
                          value: type,
                          child: Text(label, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) return 'Please select expense type';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Conditional fields based on type
                    if (selectedType == ExpenseType.delivery) ...[
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Delivery Area *',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => deliveryArea = value,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter delivery area';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (selectedType == ExpenseType.companyCollection) ...[
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Company Name *',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => companyName = value,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter company name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (selectedType == ExpenseType.warehouseCollection) ...[
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Warehouse Name *',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => warehouseName = value,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter warehouse name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (selectedType == ExpenseType.electronicPayment) ...[
                      DropdownButtonFormField<ElectronicPaymentMethod>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method *',
                          border: OutlineInputBorder(),
                        ),
                        items: ElectronicPaymentMethod.values.map((method) {
                          String label;
                          switch (method) {
                            case ElectronicPaymentMethod.instapay:
                              label = 'Instapay';
                              break;
                            case ElectronicPaymentMethod.wallet:
                              label = 'Wallet';
                              break;
                            case ElectronicPaymentMethod.visa:
                              label = 'Visa';
                              break;
                          }
                          return DropdownMenuItem(value: method, child: Text(label, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            electronicMethod = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Please select payment method';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (selectedType == ExpenseType.administrative) ...[
                      DropdownButtonFormField<AdministrativeStaff>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Staff Member *',
                          border: OutlineInputBorder(),
                        ),
                        items: AdministrativeStaff.values.map((staff) {
                          String label;
                          switch (staff) {
                            case AdministrativeStaff.fadyEssam:
                              label = 'Fady Essam';
                              break;
                            case AdministrativeStaff.ragyZakaria:
                              label = 'Ragy Zakaria';
                              break;
                            case AdministrativeStaff.bolaFahim:
                              label = 'Bola Fahim';
                              break;
                            case AdministrativeStaff.emadFawzy:
                              label = 'Emad Fawzy';
                              break;
                          }
                          return DropdownMenuItem(value: staff, child: Text(label, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            administrativeStaff = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Please select staff member';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (selectedType == ExpenseType.government) ...[
                      DropdownButtonFormField<GovernmentExpenseType>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Government Expense Type *',
                          border: OutlineInputBorder(),
                        ),
                        items: GovernmentExpenseType.values.map((type) {
                          String label;
                          switch (type) {
                            case GovernmentExpenseType.electricity:
                              label = 'Electricity';
                              break;
                            case GovernmentExpenseType.water:
                              label = 'Water';
                              break;
                            case GovernmentExpenseType.other:
                              label = 'Other';
                              break;
                          }
                          return DropdownMenuItem(value: type, child: Text(label, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            governmentType = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Please select type';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (selectedType == ExpenseType.other) ...[
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => otherDescription = value,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Amount Field
                    TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount (EGP) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Notes Field
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final expense = ExpenseItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      type: selectedType!,
                      amount: double.parse(amountController.text),
                      deliveryArea: deliveryArea,
                      companyName: companyName,
                      warehouseName: warehouseName,
                      electronicMethod: electronicMethod,
                      administrativeStaff: administrativeStaff,
                      governmentType: governmentType,
                      other: otherDescription,
                      notes: notesController.text.isEmpty ? null : notesController.text,
                    );

                    this.setState(() {
                      _expenses.add(expense);
                    });

                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManger.primary,
                ),
                child: const Text('Add',style: TextStyle(color: Colors.white),),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleSubmit(ShiftReportCubit cubit) {
    if (_formKey.currentState!.validate()) {
      // Update cubit with current values
      if (_selectedShiftType != null) {
        cubit.updateShiftType(_selectedShiftType!);
      }

      final drawerAmount = double.tryParse(_drawerAmountController.text) ?? 0.0;
      cubit.updateDrawerAmount(drawerAmount);

      final computerDiff = double.tryParse(_computerDifferenceController.text) ?? 0.0;
      cubit.updateComputerDifference(_computerDifferenceType, computerDiff);

      final walletAmount = double.tryParse(_electronicWalletController.text) ?? 0.0;
      cubit.updateElectronicWallet(walletAmount);

      cubit.updateNotes(_notesController.text.isEmpty ? null : _notesController.text);

      // Clear and add all expenses from local list
      cubit.expenses.clear();
      for (var expense in _expenses) {
        cubit.expenses.add(expense);
      }

      // Submit
      cubit.submitShiftReport();
    }
  }
}

