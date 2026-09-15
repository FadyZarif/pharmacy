import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/report/data/models/daily_report_model.dart';
import 'package:pharmacy/features/report/logic/edit_report_cubit.dart';
import 'package:pharmacy/features/report/logic/edit_report_state.dart';
import 'package:pharmacy/features/report/logic/shift_report_cubit.dart';
import 'package:pharmacy/features/report/ui/widgets/shift_report_widgets.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

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
  late List<String> _attachmentUrls;
  final List<AttachmentFileData> _newAttachmentFiles = [];

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
    _attachmentUrls = List<String>.from(widget.report.attachmentUrls);

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
          final bottomPad = MediaQuery.of(context).padding.bottom;
          const kBottomNavHeight = 138.0; // nav + powered-by + padding

          return Scaffold(
            backgroundColor: ColorsManger.primaryBackground,
            extendBodyBehindAppBar: false,
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
                    _isEditMode ? 'Edit Shift Report' : 'View Shift Report',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.80),
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  actions: [
                    if (!_isEditMode &&
                        ((currentUser.isManagement) ||
                            (currentUser.role == Role.subManager &&
                                _isDateTodayOrYesterday(widget.date))))
                      IconButton(
                        icon: const Icon(Icons.edit, color: ColorsManger.primary),
                        onPressed: () {
                          setState(() {
                            _isEditMode = true;
                          });
                        },
                        tooltip: 'Edit Report',
                      ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),
            body: Stack(
              children: [
                const _EditShiftReportBackground(),
                Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 22 + kBottomNavHeight + bottomPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PanelCard(
                          child: ShiftReportWidgets.buildInfoSection(
                            branchName: widget.report.branchName,
                            date: widget.report.submittedAt!,
                            employeeName: widget.report.employeeName,
                            shiftType: _getShiftLabel(widget.report.shiftType),
                          ),
                        ),
                        if (widget.report.lastModifiedByName != null &&
                            widget.report.lastModifiedByName!.isNotEmpty &&
                            widget.report.updatedAt != null) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              'Last modified by ${widget.report.lastModifiedByName} at ${DateFormat('yyyy-MM-dd HH:mm').format(widget.report.updatedAt!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        _PanelCard(
                          child: ShiftReportWidgets.buildDrawerAmountField(
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
                        ),
                        const SizedBox(height: 20),
                        _PanelCard(
                          child: ShiftReportWidgets.buildComputerDifferenceSection(
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
                        ),
                        const SizedBox(height: 20),
                        _PanelCard(
                          child: ShiftReportWidgets.buildElectronicWalletField(
                            controller: _electronicWalletController,
                            readOnly: !_isEditMode,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _PanelCard(
                          child: ShiftReportWidgets.buildNotesField(
                            controller: _notesController,
                            readOnly: !_isEditMode,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Attachments Section (always editable in edit mode)
                        if (_isEditMode ||
                            _attachmentUrls.isNotEmpty ||
                            _newAttachmentFiles.isNotEmpty) ...[
                          _buildAttachmentsSection(),
                          const SizedBox(height: 24),
                        ],

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
                          ShiftReportWidgets.buildSummaryCard(icon: Icons.currency_exchange, label: 'تبديل نقدي', value:  widget.report.medicineExpenses, color: Colors.purple),
                          const SizedBox(height: 16),
                          ShiftReportWidgets.buildSummaryCard(icon: Icons.inventory_2, label: 'شراء بضاعه بفاتوره', value: widget.report.warehouseCollectionExpenses, color: Colors.deepOrange),
                          const SizedBox(height: 16),
                          ShiftReportWidgets.buildSummaryCard(icon: Icons.add_card, label: 'Total Electronic Expenses', value:  widget.report.electronicWalletExpenses, color: Colors.cyan),
                          const SizedBox(height: 24),
                          Divider(color: Colors.grey.shade300),
                          const SizedBox(height: 24),

                        ],

                        // Financial Summary
                        _PanelCard(
                          child: ShiftReportWidgets.buildFinancialSummary(
                            _drawerAmountController.text,
                            _expenses,
                          ),
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
                      items: ExpenseType.values
                          .where((type) => type != ExpenseType.companyCollection)
                          .map((type) {
                        String label;
                        switch (type) {
                          case ExpenseType.medicines:
                            label = 'تبديل نقدي';
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
                            label = 'شراء بضاعه بفاتوره';
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
                        items: AdministrativeStaff.values
                            .where((staff) => staff != AdministrativeStaff.emadFawzy)
                            .map((staff) {
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
                            withData: true, // Important for web
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

    if (_attachmentUrls.isEmpty && _newAttachmentFiles.isEmpty) {
      defToast2(
        context: context,
        msg: 'Please add at least one attachment',
        dialogType: DialogType.error,
      );
      return;
    }

    List<ExpenseItem> finalExpenses = _expenses;
    List<String> finalAttachmentUrls = List<String>.from(_attachmentUrls);

    final needsUpload =
        _expenseFiles.isNotEmpty || _newAttachmentFiles.isNotEmpty;

    // Upload expense files / new report attachments if any
    if (needsUpload) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: ColorsManger.primary),
        ),
      );

      try {
        // Upload all expense files and update expenses with real URLs
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
            } else {
              throw Exception('File bytes not available');
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

        // Upload new report attachments
        for (final file in _newAttachmentFiles) {
          finalAttachmentUrls.add(await _uploadReportAttachment(file));
        }

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
      attachmentUrls: finalAttachmentUrls,
    );

    context.read<EditReportCubit>().updateReport(updatedReport, widget.date);
  }

  Future<String> _uploadReportAttachment(AttachmentFileData fileData) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = fileData.name.split('.').last;
    final fileName =
        '${timestamp}_${widget.report.shiftType.name}.$extension';
    final storageRef = FirebaseStorage.instance.ref().child(
      'shift_reports/${widget.report.branchId}/${widget.date}/$fileName',
    );

    final uploadTask = await storageRef.putData(
      fileData.bytes,
      SettableMetadata(contentType: _getContentType(extension)),
    );
    return uploadTask.ref.getDownloadURL();
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  Widget _buildAttachmentsSection() {
    final totalAttachments =
        _newAttachmentFiles.length + _attachmentUrls.length;
    final itemCount = _isEditMode ? totalAttachments + 1 : totalAttachments;

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEditMode
                    ? 'Attachments (Images or PDFs)'
                    : 'Attachments',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              if (totalAttachments > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: ColorsManger.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: ColorsManger.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    '$totalAttachments file(s)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: ColorsManger.primary,
                    ),
                  ),
                ),
            ],
          ),
          if (_isEditMode) ...[
            const SizedBox(height: 6),
            Text(
              'Add, remove, or replace files then save',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (itemCount == 0)
            Text(
              'No attachments',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (_isEditMode && index == totalAttachments) {
                  return InkWell(
                    onTap: _showAttachmentPicker,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ColorsManger.primary.withValues(alpha: 0.24),
                          width: 2,
                        ),
                        boxShadow: _panelShadow(),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            color: ColorsManger.primary,
                            size: 30,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 12,
                              color: ColorsManger.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return _buildAttachmentTile(index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentTile(int index) {
    final isLocalFile = index < _newAttachmentFiles.length;
    final bool isPdf;
    final String fileName;
    final Uint8List? imageBytes;
    final String? imageUrl;

    if (isLocalFile) {
      final file = _newAttachmentFiles[index];
      final extension = file.name.split('.').last.toLowerCase();
      isPdf = extension == 'pdf';
      fileName = file.name;
      imageBytes = isPdf ? null : file.bytes;
      imageUrl = null;
    } else {
      final urlIndex = index - _newAttachmentFiles.length;
      final url = _attachmentUrls[urlIndex];
      final extension = url.split('.').last.toLowerCase();
      isPdf = extension.contains('pdf');
      fileName = 'File ${urlIndex + 1}';
      imageBytes = null;
      imageUrl = isPdf ? null : url;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.16)),
        boxShadow: _panelShadow(),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: () {
                if (!isLocalFile) {
                  final urlIndex = index - _newAttachmentFiles.length;
                  _openAttachment(_attachmentUrls[urlIndex]);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: isPdf
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.picture_as_pdf,
                            size: 40,
                            color: ColorsManger.primary,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              fileName,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      )
                    : (imageBytes != null
                        ? Image.memory(
                            imageBytes,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : (imageUrl != null
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress
                                                  .expectedTotalBytes !=
                                              null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image,
                                          size: 40, color: Colors.grey),
                                      SizedBox(height: 6),
                                      Text(
                                        'Tap to open',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              )
                            : const Center(
                                child: Icon(Icons.image,
                                    size: 40, color: ColorsManger.primary),
                              ))),
              ),
            ),
          ),
          if (_isEditMode) ...[
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: () => _removeAttachment(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: InkWell(
                onTap: () => _replaceAttachment(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: ColorsManger.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isLocalFile ? Colors.orange : Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isLocalFile ? 'New' : 'Saved',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _removeAttachment(int index) {
    setState(() {
      if (index < _newAttachmentFiles.length) {
        _newAttachmentFiles.removeAt(index);
      } else {
        final urlIndex = index - _newAttachmentFiles.length;
        if (urlIndex >= 0 && urlIndex < _attachmentUrls.length) {
          _attachmentUrls.removeAt(urlIndex);
        }
      }
    });
  }

  Future<void> _replaceAttachment(int index) async {
    final picked = await _pickAttachmentFile();
    if (picked == null) return;
    setState(() {
      if (index < _newAttachmentFiles.length) {
        _newAttachmentFiles[index] = picked;
      } else {
        final urlIndex = index - _newAttachmentFiles.length;
        if (urlIndex >= 0 && urlIndex < _attachmentUrls.length) {
          _attachmentUrls.removeAt(urlIndex);
          _newAttachmentFiles.add(picked);
        }
      }
    });
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Attachment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorsManger.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.camera_alt, color: ColorsManger.primary),
              ),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final file = await _pickImage(ImageSource.camera);
                if (file != null) {
                  setState(() => _newAttachmentFiles.add(file));
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: Colors.green),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final files = await _pickImagesFromGallery();
                if (files.isNotEmpty) {
                  setState(() => _newAttachmentFiles.addAll(files));
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.red),
              ),
              title: const Text('Choose PDF / File'),
              onTap: () async {
                Navigator.pop(context);
                final file = await _pickPdfOrImageFile();
                if (file != null) {
                  setState(() => _newAttachmentFiles.add(file));
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<AttachmentFileData?> _pickAttachmentFile() async {
    // Used by replace — open same chooser options via file picker for simplicity
    return _pickPdfOrImageFile();
  }

  Future<AttachmentFileData?> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source, imageQuality: 85);
      if (image == null) return null;
      final bytes = await image.readAsBytes();
      return AttachmentFileData(
        name: image.name,
        bytes: bytes,
        path: kIsWeb ? null : image.path,
      );
    } catch (e) {
      if (!mounted) return null;
      defToast2(
        context: context,
        msg: 'Error picking image: $e',
        dialogType: DialogType.error,
      );
      return null;
    }
  }

  Future<List<AttachmentFileData>> _pickImagesFromGallery() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage(imageQuality: 85);
      final files = <AttachmentFileData>[];
      for (final image in images) {
        final bytes = await image.readAsBytes();
        files.add(
          AttachmentFileData(
            name: image.name,
            bytes: bytes,
            path: kIsWeb ? null : image.path,
          ),
        );
      }
      return files;
    } catch (e) {
      if (!mounted) return [];
      defToast2(
        context: context,
        msg: 'Error picking images: $e',
        dialogType: DialogType.error,
      );
      return [];
    }
  }

  Future<AttachmentFileData?> _pickPdfOrImageFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      final file = result.files.first;
      if (file.bytes == null) {
        throw Exception('File bytes not available');
      }
      return AttachmentFileData(
        name: file.name,
        bytes: file.bytes!,
        path: file.path,
      );
    } catch (e) {
      if (!mounted) return null;
      defToast2(
        context: context,
        msg: 'Error picking file: $e',
        dialogType: DialogType.error,
      );
      return null;
    }
  }

  Future<void> _openAttachment(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        defToast2(
          context: context,
          msg: 'Cannot open file',
          dialogType: DialogType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      defToast2(
        context: context,
        msg: 'Error opening file: $e',
        dialogType: DialogType.error,
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

class _EditShiftReportBackground extends StatelessWidget {
  const _EditShiftReportBackground();  @override
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
}List<BoxShadow> _panelShadow() => [
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
    ];class _PanelCard extends StatelessWidget {
  final Widget child;
  const _PanelCard({required this.child});  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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