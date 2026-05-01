import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/quarterly_incentives/data/models/quarterly_incentive_period_model.dart';
import 'package:pharmacy/features/quarterly_incentives/logic/quarterly_incentives_cubit.dart';
import 'package:pharmacy/features/quarterly_incentives/logic/quarterly_incentives_state.dart';
import 'package:intl/intl.dart';

class AddQuarterlyIncentivesScreen extends StatefulWidget {
  const AddQuarterlyIncentivesScreen({super.key});

  @override
  State<AddQuarterlyIncentivesScreen> createState() =>
      _AddQuarterlyIncentivesScreenState();
}

class _AddQuarterlyIncentivesScreenState extends State<AddQuarterlyIncentivesScreen> {
  late final QuarterlyIncentivesCubit _cubit;
  PlatformFile? _selectedFile;
  List<String> _sheetNames = [];
  String? _selectedSheet;
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  int _quarter = ((DateTime.now().month - 1) ~/ 3) + 1;
  IncentivePeriodType _periodType = IncentivePeriodType.quarterly;
  final TextEditingController _notesController = TextEditingController();
  bool _isUploading = false;
  QuarterlyIncentivePeriodModel? _existingPeriod;

  @override
  void initState() {
    super.initState();
    _cubit = QuarterlyIncentivesCubit();
    _refreshPeriodInfo();
  }

  void _refreshPeriodInfo() {
    final key = _periodType == IncentivePeriodType.monthly
        ? QuarterlyIncentivePeriodModel.createMonthlyPeriodKey(_year, _month)
        : QuarterlyIncentivePeriodModel.createQuarterlyPeriodKey(_year, _quarter);
    _cubit.fetchPeriodInfo(key);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _pickExcelFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final f = result.files.first;
        if (f.bytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File data not available. Try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        final names = QuarterlyIncentivesCubit.sheetNamesFromBytes(f.bytes!);
        if (!mounted) return;
        setState(() {
          _selectedFile = f;
          _sheetNames = names;
          _selectedSheet = names.isNotEmpty ? names.first : null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _upload() {
    if (_selectedFile?.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select an Excel file first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_selectedSheet == null || _selectedSheet!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a sheet from the workbook'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    _cubit.uploadQuarterlyIncentivesFromExcel(
      fileBytes: _selectedFile!.bytes!,
      year: _year,
      quarter: _quarter,
      month: _month,
      periodType: _periodType,
      sheetName: _selectedSheet!,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return BlocProvider.value(
      value: _cubit,
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
                ),
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              centerTitle: true,
              title: const Text(
                'رفع الحوافز',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ),
        ),
        body: BlocConsumer<QuarterlyIncentivesCubit, QuarterlyIncentivesState>(
          listener: (context, state) {
            if (state is QuarterlyIncentivePeriodInfoLoaded) {
              setState(() => _existingPeriod = state.period);
            } else if (state is QuarterlyIncentivesUploading) {
              setState(() => _isUploading = true);
            } else if (state is QuarterlyIncentivesUploadSuccess) {
              setState(() {
                _isUploading = false;
                _selectedFile = null;
                _sheetNames = [];
                _selectedSheet = null;
                _notesController.clear();
              });
              _refreshPeriodInfo();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم الرفع لـ ${state.employeeCount} موظف',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is QuarterlyIncentivesError) {
              setState(() => _isUploading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                topPad + kToolbarHeight + 12,
                16,
                bottomPad + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _infoCard(),
                  const SizedBox(height: 12),
                  if (_existingPeriod != null) _existingCard(),
                  const SizedBox(height: 12),
                  _periodCard(),
                  const SizedBox(height: 12),
                  _fileCard(),
                  if (_sheetNames.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _sheetDropdown(),
                  ],
                  const SizedBox(height: 12),
                  _notesCard(),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _upload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsManger.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.cloud_upload),
                      label: Text(
                        _isUploading ? 'جاري الرفع...' : 'رفع الشيت المختار',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _infoCard() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: ColorsManger.primary, size: 22),
              const SizedBox(width: 8),
              const Text(
                'تعليمات',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• اختر سنة وربع التخزين (مثال: 2026 الربع الأول → 2026-Q1)\n'
            '• اختر نوع الفترة: شهري أو ربع سنوي\n'
            '• اختر ملف Excel ثم شيت واحد من القائمة\n'
            '• الصف الثالث في الشيت = عناوين الأعمدة، أول بيانات من الصف الرابع\n'
            '• يُفضّل لصق القيم بدل المعادلات في Excel قبل الرفع حتى تظهر الأرقام كاملة',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Colors.black.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _existingCard() {
    final p = _existingPeriod!;
    return _panel(
      tint: Colors.amber.shade50,
      border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.45)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'يوجد رفع سابق لهذه الفترة',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.amber.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'الشيت: ${p.uploadedSheetName}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (p.uploadedAt != null)
            Text(
              'التاريخ: ${DateFormat('dd/MM/yyyy HH:mm').format(p.uploadedAt!)}',
              style: TextStyle(color: Colors.grey.shade800),
            ),
          if (p.employeeCount != null)
            Text('عدد الموظفين: ${p.employeeCount}'),
          const SizedBox(height: 6),
          Text(
            'رفع ملف جديد يستبدل كل بيانات هذه الفترة.',
            style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
          ),
        ],
      ),
    );
  }

  Widget _periodCard() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الفترة',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<IncentivePeriodType>(
            initialValue: _periodType,
            decoration: const InputDecoration(
              labelText: 'نوع الفترة',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: IncentivePeriodType.monthly,
                child: Text('شهري'),
              ),
              DropdownMenuItem(
                value: IncentivePeriodType.quarterly,
                child: Text('ربع سنوي'),
              ),
            ],
            onChanged: _isUploading
                ? null
                : (v) {
                    if (v == null) return;
                    setState(() => _periodType = v);
                    _refreshPeriodInfo();
                  },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _year,
                  decoration: const InputDecoration(
                    labelText: 'السنة',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(
                    8,
                    (i) => DateTime.now().year - 3 + i,
                  ).map((y) {
                    return DropdownMenuItem(value: y, child: Text('$y'));
                  }).toList(),
                  onChanged: _isUploading
                      ? null
                      : (v) {
                          if (v == null) return;
                          setState(() => _year = v);
                          _refreshPeriodInfo();
                        },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _periodType == IncentivePeriodType.monthly
                    ? DropdownButtonFormField<int>(
                        initialValue: _month,
                        decoration: const InputDecoration(
                          labelText: 'الشهر',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(12, (i) => i + 1).map((m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Text(m.toString().padLeft(2, '0')),
                          );
                        }).toList(),
                        onChanged: _isUploading
                            ? null
                            : (v) {
                                if (v == null) return;
                                setState(() => _month = v);
                                _refreshPeriodInfo();
                              },
                      )
                    : DropdownButtonFormField<int>(
                        initialValue: _quarter,
                        decoration: const InputDecoration(
                          labelText: 'الربع',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('الربع 1')),
                          DropdownMenuItem(value: 2, child: Text('الربع 2')),
                          DropdownMenuItem(value: 3, child: Text('الربع 3')),
                          DropdownMenuItem(value: 4, child: Text('الربع 4')),
                        ],
                        onChanged: _isUploading
                            ? null
                            : (v) {
                                if (v == null) return;
                                setState(() => _quarter = v);
                                _refreshPeriodInfo();
                              },
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'مفتاح التخزين: ${_periodType == IncentivePeriodType.monthly ? QuarterlyIncentivePeriodModel.createMonthlyPeriodKey(_year, _month) : QuarterlyIncentivePeriodModel.createQuarterlyPeriodKey(_year, _quarter)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fileCard() {
    return _panel(
      child: InkWell(
        onTap: _isUploading ? null : _pickExcelFile,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                _selectedFile == null ? Icons.upload_file : Icons.check_circle,
                size: 48,
                color: _selectedFile == null
                    ? ColorsManger.primary
                    : Colors.green,
              ),
              const SizedBox(height: 8),
              Text(
                _selectedFile == null
                    ? 'اختر ملف Excel'
                    : _selectedFile!.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetDropdown() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الشيت داخل الملف',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey(_sheetNames.join('|')),
            initialValue: _selectedSheet != null &&
                    _sheetNames.contains(_selectedSheet)
                ? _selectedSheet
                : (_sheetNames.isNotEmpty ? _sheetNames.first : null),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: _sheetNames
                .map(
                  (n) => DropdownMenuItem<String>(
                    value: n,
                    child: Text(n, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: _isUploading
                ? null
                : (v) => setState(() => _selectedSheet = v),
          ),
        ],
      ),
    );
  }

  Widget _notesCard() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملاحظات (اختياري)',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            enabled: !_isUploading,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({
    required Widget child,
    Color? tint,
    BoxBorder? border,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint ?? Colors.white,
        borderRadius: BorderRadius.circular(18),
        border:
            border ?? Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: ColorsManger.primary.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
