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
import 'package:pharmacy/features/report/logic/edit_report_cubit.dart';
import 'package:pharmacy/features/report/logic/edit_report_state.dart';
import 'package:pharmacy/features/report/ui/widgets/shift_report_widgets.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';

class EditShiftReportScreen extends StatefulWidget {
  final ShiftReportModel report;
  final String date;

  const EditShiftReportScreen({
    super.key,
    required this.report,
    required this.date,
  });

  @override
  State<EditShiftReportScreen> createState() => _EditShiftReportScreenState();
}

class _EditShiftReportScreenState extends State<EditShiftReportScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _drawerAmountController;
  late TextEditingController _computerDifferenceController;
  late TextEditingController _electronicWalletController;
  late TextEditingController _notesController;

  late ComputerDifferenceType _computerDifferenceType;
  late List<ExpenseItem> _expenses;

  // Map to store files locally before upload (expenseId -> PlatformFile)
  final Map<String, PlatformFile> _expenseFiles = {};

  bool _isEditMode = false; // Preview mode by default

  @override
  void initState() {
    super.initState();
    _drawerAmountController = TextEditingController(text: widget.report.drawerAmount.toString());
    _computerDifferenceController = TextEditingController(text: widget.report.computerDifference.toString());
    _electronicWalletController = TextEditingController(text: widget.report.electronicWalletAmount.toString());
    _notesController = TextEditingController(text: widget.report.notes ?? '');
    _computerDifferenceType = widget.report.computerDifferenceType ?? ComputerDifferenceType.none;
    _expenses = List.from(widget.report.expenses);

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
      create: (context) => getIt<EditReportCubit>(),
      child: BlocConsumer<EditReportCubit, EditReportState>(
        listener: (context, state) {
          if (state is EditReportSuccess) {
            defToast2(
              context: context,
              msg: 'Report updated successfully',
              dialogType: DialogType.success,
            ).then((_) {
              if (!context.mounted) return;
              Navigator.pop(context);
            });
          } else if (state is EditReportError) {
            defToast2(
              context: context,
              msg: state.message,
              dialogType: DialogType.error,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is EditReportLoading;

          return Scaffold(
            backgroundColor: ColorsManger.primaryBackground,
            appBar: AppBar(
              foregroundColor: Colors.white,
              title: Text(
                _isEditMode ? 'Edit Shift Report' : 'View Shift Report',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              backgroundColor: ColorsManger.primary,
              actions: [
                if (!_isEditMode && ((currentUser.isManagement)||(currentUser.role == Role.subManager && _isDateTodayOrYesterday(widget.date))))
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _isEditMode = true;
                      });
                    },
                    tooltip: 'Edit Report',
                  ),
              ],
            ),
            body: Stack(
              children: [
                Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShiftReportWidgets.buildInfoSection(
                          branchName: widget.report.branchName,
                          date: widget.report.submittedAt!,
                          employeeName: widget.report.employeeName,
                          shiftType: _getShiftLabel(widget.report.shiftType),
                        ),
                        const SizedBox(height: 24),
                        ShiftReportWidgets.buildDrawerAmountField(
                          controller: _drawerAmountController,
                          readOnly: !_isEditMode,
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
                        ShiftReportWidgets.buildComputerDifferenceSection(
                          selectedType: _computerDifferenceType,
                          controller: _computerDifferenceController,
                          onTypeChanged: (type) {
                            setState(() {
                              _computerDifferenceType = type;
                            });
                          },
                          readOnly: !_isEditMode,
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
                        const SizedBox(height: 20),
                        ShiftReportWidgets.buildElectronicWalletField(
                          controller: _electronicWalletController,
                          readOnly: !_isEditMode,
                        ),
                        const SizedBox(height: 20),
                        ShiftReportWidgets.buildNotesField(
                          controller: _notesController,
                          readOnly: !_isEditMode,
                        ),
                        const SizedBox(height: 24),

                        // Attachment Section
                        if (widget.report.attachmentUrl != null)
                          _buildAttachmentSection(widget.report.attachmentUrl!),

                        if (widget.report.attachmentUrl != null)
                          const SizedBox(height: 24),

                        ShiftReportWidgets.buildExpensesSection(
                          expenses: _expenses,
                          onAddExpense: _isEditMode ? _addExpense : null,
                          onDeleteExpense: (expense) {
                            setState(() {
                              _expenses.remove(expense);
                            });
                          },
                          isEditMode: _isEditMode,
                        ),
                        const SizedBox(height: 24),

                        if (!_isEditMode)...[
                          ShiftReportWidgets.buildSummaryCard(icon: Icons.currency_exchange, label: 'Total Medicines Expenses', value:  widget.report.medicineExpenses, color: Colors.purple),
                          const SizedBox(height: 16),
                          ShiftReportWidgets.buildSummaryCard(icon: Icons.add_card, label: 'Total Electronic Expenses', value:  widget.report.electronicWalletExpenses, color: Colors.cyan),
                          const SizedBox(height: 24),
                          Divider(color: Colors.grey.shade300),
                          const SizedBox(height: 24),

                        ],

                        // Financial Summary
                        ShiftReportWidgets.buildFinancialSummary(
                          _drawerAmountController.text,
                          _expenses,
                        ),

                        const SizedBox(height: 32),
                        if (_isEditMode)
                          ShiftReportWidgets.buildSubmitButton(
                            label: 'Save Changes',
                            onPressed: () => _saveReport(context),
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
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getShiftLabel(ShiftType type) {
    switch (type) {
      case ShiftType.midnight:
        return 'Midnight';
      case ShiftType.morning:
        return 'Morning';
      case ShiftType.afternoon:
        return 'Afternoon';
      case ShiftType.evening:
        return 'Evening';
    }
  }

  void _addExpense() {
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
                      initialValue: selectedType,
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
                      fileUrl: selectedFile != null ? 'pending_upload_$expenseId' : null,
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

  void _saveReport(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    List<ExpenseItem> finalExpenses = _expenses;

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

        finalExpenses = updatedExpenses;

        // Close loading dialog
        if (mounted) Navigator.pop(context);
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
    }

    final updatedReport = widget.report.copyWith(
      drawerAmount: double.parse(_drawerAmountController.text),
      computerDifference: double.tryParse(_computerDifferenceController.text),
      computerDifferenceType: _computerDifferenceType,
      electronicWalletAmount: double.tryParse(_electronicWalletController.text),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      expenses: finalExpenses,
    );

    context.read<EditReportCubit>().updateReport(updatedReport, widget.date);
  }

  Widget _buildAttachmentSection(String attachmentUrl) {
    final isPdf = attachmentUrl.toLowerCase().contains('.pdf');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorsManger.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPdf ? Icons.picture_as_pdf : Icons.image,
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
                      isPdf ? 'PDF Document' : 'Image',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap to view',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // View button
              IconButton(
                icon: Icon(Icons.open_in_new, color: ColorsManger.primary),
                onPressed: () => _openAttachment(attachmentUrl),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openAttachment(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open attachment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening attachment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  bool _isDateTodayOrYesterday(String dateString) {
    // تحويل الـ string للتاريخ
    DateTime inputDate = DateTime.parse(dateString);

    // تاريخ النهارده وامبارح
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(Duration(days: 1));
    DateTime inputDateOnly = DateTime(inputDate.year, inputDate.month, inputDate.day);
    print(inputDateOnly.isAtSameMomentAs(today) ||
        inputDateOnly.isAtSameMomentAs(yesterday));

    return inputDateOnly.isAtSameMomentAs(today) ||
        inputDateOnly.isAtSameMomentAs(yesterday);
  }
}

