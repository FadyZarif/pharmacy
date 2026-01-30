import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/salary/data/models/month_salary_model.dart';
import 'package:pharmacy/features/salary/logic/salary_cubit.dart';
import 'package:pharmacy/features/salary/logic/salary_state.dart';

class AddSalaryScreen extends StatefulWidget {
  const AddSalaryScreen({super.key});

  @override
  State<AddSalaryScreen> createState() => _AddSalaryScreenState();
}

class _AddSalaryScreenState extends State<AddSalaryScreen> {
  PlatformFile? _selectedFile;
  DateTime _selectedMonth = DateTime.now();
  final TextEditingController _notesController = TextEditingController();
  bool _isUploading = false;
  late final SalaryCubit _salaryCubit;
  MonthSalaryModel? _existingMonthInfo;

  @override
  void initState() {
    super.initState();
    _salaryCubit = getIt<SalaryCubit>();
    _checkExistingData();
  }

  void _checkExistingData() {
    final monthKey = MonthSalaryModel.createMonthKey(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    _salaryCubit.fetchMonthInfo(monthKey);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true, // Important for web
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorsManger.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = picked;
        _existingMonthInfo = null;
      });
      _checkExistingData();
    }
  }

  void _uploadSalaryData() {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an Excel file first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedFile!.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File data not available. Please try selecting the file again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _salaryCubit.uploadSalaryFromExcel(
      fileBytes: _selectedFile!.bytes!,
      year: _selectedMonth.year,
      month: _selectedMonth.month,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _salaryCubit,
      child: Scaffold(
        backgroundColor: ColorsManger.primaryBackground,
        appBar: AppBar(
          backgroundColor: ColorsManger.primary,
          foregroundColor: Colors.white,
          title: const Text(
            'Upload Salary Data',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocConsumer<SalaryCubit, SalaryState>(
          listener: (context, state) {
            if (state is MonthInfoLoaded) {
              setState(() {
                _existingMonthInfo = state.monthInfo;
              });
            } else if (state is SalaryUploading) {
              setState(() {
                _isUploading = true;
              });
            } else if (state is SalaryUploadSuccess) {
              setState(() {
                _isUploading = false;
                _selectedFile = null;
                _notesController.clear();
              });
              _checkExistingData(); // إعادة جلب البيانات بعد النجاح
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Successfully uploaded data for ${state.employeeCount} employees',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is SalaryError) {
              setState(() {
                _isUploading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // بطاقة المعلومات
                  Card(
                    elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 50,
                            color: ColorsManger.primary,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Upload Instructions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• File must be in Excel format (.xlsx or .xls)\n'
                                '• Must contain all required columns\n'
                                '• Data will be added for the selected month\n'
                                '• Existing data will be updated if found',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // عرض البيانات المرفوعة مسبقاً إن وجدت
                  if (_existingMonthInfo != null)
                    Card(
                      elevation: 2,
                      color: Colors.amber.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.amber.shade700, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  color: Colors.amber.shade900,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Previously Uploaded Data',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Uploaded At',
                              _existingMonthInfo!.uploadedAt != null
                                  ? DateFormat('dd MMM yyyy, hh:mm a')
                                      .format(_existingMonthInfo!.uploadedAt!)
                                  : 'N/A',
                              Icons.access_time,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Employee Count',
                              '${_existingMonthInfo!.employeeCount ?? 0} employees',
                              Icons.people,
                            ),
                            if (_existingMonthInfo!.notes != null &&
                                _existingMonthInfo!.notes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                'Notes',
                                _existingMonthInfo!.notes!,
                                Icons.note,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.amber.shade900,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Uploading a new file will update the existing data',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.amber.shade900,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // اختيار الشهر
                  _buildMonthSelector(),
                  const SizedBox(height: 16),

                  // اختيار الملف
                  Card(
                    elevation: 1,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: _isUploading ? null : _pickExcelFile,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              _selectedFile == null
                                  ? Icons.upload_file
                                  : Icons.check_circle,
                              size: 60,
                              color: _selectedFile == null
                                  ? ColorsManger.primary
                                  : Colors.green,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedFile == null
                                  ? 'Click to Select Excel File'
                                  : 'Selected File:',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_selectedFile != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _selectedFile!.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(_selectedFile!.size / 1024).toStringAsFixed(2)} KB',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ملاحظات
                  Card(
                    elevation: 1,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notes (Optional)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _notesController,
                            enabled: !_isUploading,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Add any additional notes...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: ColorsManger.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // زر الرفع
                  if (_isUploading)
                    const Card(
                      elevation: 1,
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text(
                              'Uploading Data...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _uploadSalaryData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorsManger.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Upload Salary Data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            icon: const Icon(Icons.arrow_back, color: ColorsManger.primary,),
            onPressed: _isUploading
                ? null
                : () {
                    setState(() {
                      if (_selectedMonth.month == 1) {
                        _selectedMonth =
                            DateTime(_selectedMonth.year - 1, 12);
                      } else {
                        _selectedMonth = DateTime(
                            _selectedMonth.year, _selectedMonth.month - 1);
                      }
                      _existingMonthInfo = null;
                    });
                    _checkExistingData();
                  },
          ),

          // Month Display
          GestureDetector(
            onTap: _isUploading ? null : _selectMonth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: ColorsManger.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ColorsManger.primary),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: ColorsManger.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat.yMMMM().format(_selectedMonth),
                    style: const TextStyle(
                        color: ColorsManger.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Next Month Button
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: ColorsManger.primary),
            onPressed: (_isUploading ||
                    _selectedMonth.year >= DateTime.now().year &&
                        _selectedMonth.month >= DateTime.now().month)
                ? null
                : () {
                    setState(() {
                      if (_selectedMonth.month == 12) {
                        _selectedMonth =
                            DateTime(_selectedMonth.year + 1, 1);
                      } else {
                        _selectedMonth = DateTime(
                            _selectedMonth.year, _selectedMonth.month + 1);
                      }
                      _existingMonthInfo = null;
                    });
                    _checkExistingData();
                  },
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.amber.shade800,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}