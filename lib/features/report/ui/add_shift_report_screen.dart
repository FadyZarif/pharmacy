import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/report/data/models/daily_report_model.dart';
import 'package:pharmacy/features/report/logic/shift_report_cubit.dart';
import 'package:pharmacy/features/report/logic/shift_report_state.dart';
import 'package:pharmacy/features/report/ui/widgets/shift_report_widgets.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';

import '../../employee/logic/employee_layout_cubit.dart';
import 'view_reports_screen.dart';

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

  // Map to store files locally before upload (expenseId -> PlatformFile)
  final Map<String, PlatformFile> _expenseFiles = {};

  @override
  void initState() {
    super.initState();
    // Add listener to update UI when drawer amount changes
    _drawerAmountController.addListener(() {
      setState(() {});
    });
  }

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
              foregroundColor: Colors.white,
              actions: [
                if (currentUser.role != Role.staff)
                IconButton(
                  icon: const Icon(Icons.assessment, color: Colors.white),
                  onPressed: () {
                    navigateTo(context, ViewReportsScreen());
                  },
                ),
              ],
            ),
            body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
                children: [
                  Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // معلومات ثابتة (غير قابلة للتعديل)
                          ShiftReportWidgets.buildInfoSection(
                            branchName: currentUser.currentBranch.name,
                            date: DateTime.now(),
                          ),

                          const SizedBox(height: 24),

                          // اختيار نوع الوردية
                          _buildShiftTypeSelector(cubit),

                          const SizedBox(height: 20),

                          // إدخال الدرج
                          ShiftReportWidgets.buildDrawerAmountField(
                            controller: _drawerAmountController,
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

                          const SizedBox(height: 20),

                          // إدخال فرق الكمبيوتر
                          ShiftReportWidgets.buildComputerDifferenceSection(
                            selectedType: _computerDifferenceType ?? ComputerDifferenceType.none,
                            controller: _computerDifferenceController,
                            onTypeChanged: (type) {
                              setState(() {
                                _computerDifferenceType = type;
                                if (type == ComputerDifferenceType.none) {
                                  _computerDifferenceController.clear();
                                }
                              });
                            },
                            validator: (value) {
                              if (_computerDifferenceType != null &&
                                  _computerDifferenceType != ComputerDifferenceType.none) {
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

                         /* const SizedBox(height: 20),

                          // المحفظة الإلكترونية
                          ShiftReportWidgets.buildElectronicWalletField(
                            controller: _electronicWalletController,
                          ),*/

                          const SizedBox(height: 20),

                          // الملاحظات
                          ShiftReportWidgets.buildNotesField(
                            controller: _notesController,
                          ),

                          const SizedBox(height: 24),

                          // قسم المرفقات
                          _buildAttachmentSection(cubit),

                          const SizedBox(height: 24),

                          // قسم المصاريف
                          ShiftReportWidgets.buildExpensesSection(
                            expenses: _expenses,
                            onAddExpense: _showAddExpenseDialog,
                            onDeleteExpense: (expense) {
                              setState(() {
                                _expenses.remove(expense);
                              });
                            },
                          ),

                          const SizedBox(height: 24),
                          // Financial Summary
                          // _buildFinancialSummary(),
                          ShiftReportWidgets.buildFinancialSummary(
                            _drawerAmountController.text,
                            _expenses,
                          ),

                          const SizedBox(height: 32),

                          // زر الحفظ
                          ShiftReportWidgets.buildSubmitButton(
                            label: 'Submit Report',
                            onPressed: () => _handleSubmit(cubit),
                            isLoading: isLoading,
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  if (isLoading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: const Center(
                        child: CircularProgressIndicator(),
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

  Widget _buildAttachmentSection(ShiftReportCubit cubit) {
    final hasAttachment = cubit.attachmentFile != null || cubit.attachmentUrl != null;
    final isLocalFile = cubit.attachmentFile != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachment (Image or PDF) *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        if (!hasAttachment)
          // Add Attachment Button
          InkWell(
            onTap: () => _pickAttachment(cubit),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ColorsManger.primary.withValues(alpha: 0.3),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.attach_file, color: ColorsManger.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Add Image or PDF',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: ColorsManger.primary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          // Show Attachment Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                // Icon based on file type
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorsManger.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFileIcon(cubit),
                    color: ColorsManger.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),

                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFileName(cubit),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLocalFile ? 'Ready to upload' : 'Uploaded',
                        style: TextStyle(
                          fontSize: 12,
                          color: isLocalFile ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    cubit.removeAttachment();
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _pickAttachment(ShiftReportCubit cubit) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        cubit.pickAttachment(file);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getFileIcon(ShiftReportCubit cubit) {
    if (cubit.attachmentFile != null) {
      final extension = cubit.attachmentFile!.path.split('.').last.toLowerCase();
      return extension == 'pdf' ? Icons.picture_as_pdf : Icons.image;
    } else if (cubit.attachmentUrl != null) {
      final extension = cubit.attachmentUrl!.split('.').last.toLowerCase();
      return extension.contains('pdf') ? Icons.picture_as_pdf : Icons.image;
    }
    return Icons.attach_file;
  }

  String _getFileName(ShiftReportCubit cubit) {
    if (cubit.attachmentFile != null) {
      return cubit.attachmentFile!.path.split('/').last;
    } else if (cubit.attachmentUrl != null) {
      return 'Attachment';
    }
    return 'Unknown';
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
                    label = 'Morning (8 AM - 2 PM)';
                    icon = Icons.wb_sunny_outlined;
                    break;
                  case ShiftType.afternoon:
                    label = 'Afternoon (2 PM - 7 PM)';
                    icon = Icons.wb_twilight;
                    break;
                  case ShiftType.evening:
                    label = 'Evening (7 PM - 12 AM)';
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









  void _showAddExpenseDialog() {
    ExpenseType? selectedType;
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // File attachment
    PlatformFile? selectedFile;
    String? selectedFileName;

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
                          case ExpenseType.ahmedAboghonima:
                            label = 'Ahmed Aboghonima';
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

                    // File Attachment (Optional)
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                          );

                          if (result != null) {
                            setState(() {
                              selectedFile = result.files.first;
                              selectedFileName = result.files.first.name;
                            });
                          }
                        } catch (e) {
                          defToast2(
                            context: context,
                            msg: 'Error picking file: $e',
                            dialogType: DialogType.error,
                          );
                        }
                      },
                      icon: Icon(
                        selectedFile != null ? Icons.check_circle : Icons.attach_file,
                        color: selectedFile != null ? Colors.green : null,
                      ),
                      label: Text(
                        selectedFile != null
                            ? 'File: $selectedFileName'
                            : 'Attach File (Optional)',
                      ),
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
                    final expenseId = DateTime.now().millisecondsSinceEpoch.toString();

                    final expense = ExpenseItem(
                      id: expenseId,
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
                      fileUrl: selectedFile != null ? 'pending_upload_$expenseId' : null, // Temporary marker
                    );

                    this.setState(() {
                      _expenses.add(expense);
                      // Store file locally if selected
                      if (selectedFile != null) {
                        _expenseFiles[expenseId] = selectedFile!;
                      }
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

  void _handleSubmit(ShiftReportCubit cubit) async {
    if (_formKey.currentState!.validate()) {
      // Validate attachment is required
      if (cubit.attachmentFile == null && cubit.attachmentUrl == null) {
        defToast2(
          context: context,
          msg: 'Please attach an image or PDF file',
          dialogType: DialogType.warning,
        );
        return;
      }

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

      // Upload expense files if any
      if (_expenseFiles.isNotEmpty) {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: ColorsManger.primary),
          ),
        );

        try {
          // Upload all files and update expenses with real URLs
          final updatedExpenses = <ExpenseItem>[];

          for (var expense in _expenses) {
            if (_expenseFiles.containsKey(expense.id)) {
              // Upload this expense's file
              final file = _expenseFiles[expense.id]!;
              final fileName = 'expenses/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
              final storageRef = FirebaseStorage.instance.ref().child(fileName);

              UploadTask uploadTask;
              if (file.bytes != null) {
                uploadTask = storageRef.putData(file.bytes!);
              } else if (file.path != null) {
                final ioFile = File(file.path!);
                uploadTask = storageRef.putFile(ioFile);
              } else {
                throw Exception('File has no bytes or path');
              }

              final snapshot = await uploadTask;
              final fileUrl = await snapshot.ref.getDownloadURL();

              // Create updated expense with real URL
              updatedExpenses.add(ExpenseItem(
                id: expense.id,
                type: expense.type,
                amount: expense.amount,
                deliveryArea: expense.deliveryArea,
                companyName: expense.companyName,
                warehouseName: expense.warehouseName,
                electronicMethod: expense.electronicMethod,
                administrativeStaff: expense.administrativeStaff,
                governmentType: expense.governmentType,
                other: expense.other,
                notes: expense.notes,
                fileUrl: fileUrl,
              ));
            } else {
              // No file for this expense
              updatedExpenses.add(expense);
            }
          }

          // Close loading dialog
          if (mounted) Navigator.pop(context);

          // Update cubit with expenses that have real URLs
          cubit.expenses.clear();
          for (var expense in updatedExpenses) {
            cubit.expenses.add(expense);
          }
        } catch (e) {
          // Close loading dialog
          if (mounted) Navigator.pop(context);

          defToast2(
            context: context,
            msg: 'Error uploading files: $e',
            dialogType: DialogType.error,
          );
          return;
        }
      } else {
        // No files to upload, just add expenses as is
        cubit.expenses.clear();
        for (var expense in _expenses) {
          cubit.expenses.add(expense);
        }
      }

      // Submit
      cubit.submitShiftReport();
    }
  }
}

