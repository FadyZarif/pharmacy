import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/core/widgets/app_dropdown_button_form_field.dart';
import 'package:pharmacy/core/widgets/app_text_form_field.dart';
import 'package:pharmacy/core/widgets/profile_circle.dart';
import 'package:pharmacy/features/branch/data/branch_model.dart';
import 'package:pharmacy/features/request/data/models/request_model.dart';
import 'package:pharmacy/features/request/logic/request_cubit.dart';
import 'package:pharmacy/features/request/logic/request_state.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class AddRequestScreenUnified extends StatefulWidget {
  final RequestType requestType;
  final RequestModel? existingRequest;
  final bool isReadOnly;

  const AddRequestScreenUnified({
    super.key,
    required this.requestType,
    this.existingRequest,
    this.isReadOnly = false,
  });

  @override
  State<AddRequestScreenUnified> createState() => _AddRequestScreenUnifiedState();
}

class _AddRequestScreenUnifiedState extends State<AddRequestScreenUnified> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  // Permission controllers
  final _permissionHoursController = TextEditingController();
  final _permissionMinutesController = TextEditingController();

  // Annual & Sick Leave
  DateTime? _startDate;
  DateTime? _endDate;

  // Sick Leave - File
  PlatformFile? _prescriptionFile;

  // Extra Hours & Permission
  DateTime? _selectedDate;
  int? _hours; // Used for Extra Hours only

  // Permission specific
  PermissionType? _permissionType;

  // Attend
  DateTime? _attendDate;

  // Coverage Shift
  DateTime? _coverageDate;

  @override
  void initState() {
    super.initState();
    _initializeFromExistingRequest();

    // Preload branches for coverage shift
    if (widget.requestType == RequestType.coverageShift) {
      final cubit = getIt<RequestCubit>();
      CoverageShiftDetails? details;
      if (widget.existingRequest != null) {
        details = CoverageShiftDetails.fromJson(widget.existingRequest!.details);
      }
      cubit.preloadAllBranchesWithEmployees(
        details?.peerBranchId,
        details?.peerEmployeeId,
      );
    }
  }

  void _initializeFromExistingRequest() {
    if (widget.existingRequest == null) return;

    final request = widget.existingRequest!;
    _notesController.text = request.notes ?? '';

    switch (widget.requestType) {
      case RequestType.annualLeave:
        final details = AnnualLeaveDetails.fromJson(request.details);
        _startDate = details.startDate;
        _endDate = details.endDate;
        break;

      case RequestType.sickLeave:
        final details = SickLeaveDetails.fromJson(request.details);
        _startDate = details.startDate;
        _endDate = details.endDate;
        break;

      case RequestType.extraHours:
        final details = ExtraHoursDetails.fromJson(request.details);
        _selectedDate = details.date;
        _hours = details.hours;
        break;

      case RequestType.coverageShift:
        final details = CoverageShiftDetails.fromJson(request.details);
        _coverageDate = details.date;
        break;

      case RequestType.attend:
        final details = AttendDetails.fromJson(request.details);
        _attendDate = details.date;
        break;

      case RequestType.permission:
        final details = PermissionDetails.fromJson(request.details);
        _selectedDate = details.date;
        _permissionType = details.type;
        _permissionHoursController.text = details.hours.toString();
        _permissionMinutesController.text = details.minutes.toString();
        break;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _permissionHoursController.dispose();
    _permissionMinutesController.dispose();

    // Reset coverage shift selections
    if (widget.requestType == RequestType.coverageShift) {
      final cubit = getIt<RequestCubit>();
      cubit.selectedBranch = null;
      cubit.selectedEmployee = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<RequestCubit>(),
      child: BlocConsumer<RequestCubit, RequestState>(
        listenWhen: (_, current) =>
            current is AddRequestLoading ||
            current is AddRequestSuccess ||
            current is AddRequestFailure,
        listener: (context, state) async {
          if (state is AddRequestLoading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(
                  color: ColorsManger.primary,
                ),
              ),
            );
          } else if (state is AddRequestSuccess) {
            // Close loading dialog first
            Navigator.pop(context);

            // Show success message
            await defToast2(
              context: context,
              msg: widget.existingRequest == null
                  ? 'Request submitted successfully'
                  : 'Request updated successfully',
              dialogType: DialogType.success,
            );

            // Close AddRequestScreenUnified and go back to previous screen
            if (context.mounted) {
              Navigator.pop(context, true);
            }
          } else if (state is AddRequestFailure) {
            // Close loading dialog first
            Navigator.pop(context);

            // Show error message
            await defToast2(
              context: context,
              msg: state.error,
              dialogType: DialogType.error,
            );
          }
        },
        builder: (context, state) {
          final topPad = MediaQuery.of(context).padding.top;
          return Scaffold(
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
                    widget.requestType.enName,
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
                const _AddRequestBackground(),
                SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      topPad + kToolbarHeight + 12,
                      16,
                      22,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PanelCard(child: _buildHeader()),
                          const SizedBox(height: 14),

                          _PanelCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionTitle('Request Details'),
                                const SizedBox(height: 12),
                                _buildFormFields(),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          _PanelCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionTitle('Additional Notes (Optional)'),
                                const SizedBox(height: 12),
                                _buildNotesField(),
                              ],
                            ),
                          ),

                          if (!widget.isReadOnly) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorsManger.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.send),
                                label: Text(
                                  widget.existingRequest == null
                                      ? 'Submit Request'
                                      : 'Update Request',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          '${widget.requestType.enName} Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const Spacer(),
        if (widget.existingRequest != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.existingRequest!.status == RequestStatus.approved
                  ? Colors.green
                  : widget.existingRequest!.status == RequestStatus.rejected
                      ? Colors.red
                      : Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.existingRequest!.status.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFormFields() {
    switch (widget.requestType) {
      case RequestType.annualLeave:
      case RequestType.sickLeave:
        return Column(
          children: [
            _buildDateRangePicker(),

            if (widget.requestType == RequestType.sickLeave) ...[
              const SizedBox(height: 20),
              _buildPrescriptionUpload(),
            ],
          ],
        );

      case RequestType.extraHours:
        return Column(
          children: [
            _buildSingleDatePicker(),
            const SizedBox(height: 20),
            _buildHoursInput(),
          ],
        );

      case RequestType.permission:
        return Column(
          children: [
            _buildSingleDatePicker(),
            const SizedBox(height: 20),
            _buildPermissionTypeSelector(),
            const SizedBox(height: 20),
            _buildPermissionTimeInputs(),
          ],
        );

      case RequestType.attend:
        return _buildAttendDatePicker();

      case RequestType.coverageShift:
        return BlocBuilder<RequestCubit, RequestState>(
          buildWhen: (_, current) =>
              current is FetchBranchesWithEmployeesLoading ||
              current is FetchBranchesWithEmployeesSuccess ||
              current is FetchBranchesWithEmployeesFailure,
          builder: (context, state) {
            if (state is FetchBranchesWithEmployeesLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (state is FetchBranchesWithEmployeesFailure) {
              return Center(
                child: Text(
                  state.error,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            return _buildCoverageShiftFields();
          },
        );
    }
  }

  Widget _buildDateRangePicker() {
    final displayText = _startDate != null && _endDate != null
        ? '${DateFormat('yyyy-MM-dd').format(_startDate!)} to ${DateFormat('yyyy-MM-dd').format(_endDate!)}'
        : '';

    return Column(
      children: [
        AppTextFormField(
          controller: TextEditingController(text: displayText),
          readOnly: true,
          labelText: 'Select Start and End Date',
          suffixIcon: const Icon(Icons.calendar_today),
          hintText: 'yyyy-mm-dd to yyyy-mm-dd',
          fillColor: Colors.white,
          validator: (value) {
            if (_startDate == null || _endDate == null) {
              return 'Please select date range';
            }
            return null;
          },
          onTap: widget.isReadOnly
              ? null
              : () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialEntryMode: DatePickerEntryMode.calendarOnly,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: ColorsManger.primary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    setState(() {
                      _startDate = picked.start;
                      _endDate = picked.end;
                    });
                  }
                },
        ),
        ///Number of Days
        if (_startDate != null && _endDate != null)
          Align(
            alignment: Alignment.centerRight.add(const Alignment(-0.02, 0)),
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Number of Days: ${_startDate != null && _endDate != null ? _endDate!.difference(_startDate!).inDays + 1 : 0} days',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSingleDatePicker() {
    final displayText = _selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
        : '';

    return AppTextFormField(
      controller: TextEditingController(text: displayText),
      readOnly: true,
      labelText: 'Select Date',
      suffixIcon: const Icon(Icons.calendar_today),
      hintText: 'yyyy-mm-dd',
      fillColor: Colors.white,
      validator: (value) {
        if (_selectedDate == null) {
          return 'Please select a date';
        }
        return null;
      },
      onTap: widget.isReadOnly
          ? null
          : () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialEntryMode: DatePickerEntryMode.calendarOnly,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: ColorsManger.primary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
    );
  }

  Widget _buildAttendDatePicker() {
    final displayText = _attendDate != null
        ? DateFormat('yyyy-MM-dd').format(_attendDate!)
        : '';

    return AppTextFormField(
      controller: TextEditingController(text: displayText),
      readOnly: true,
      labelText: 'Attendance Date',
      suffixIcon: const Icon(Icons.calendar_today),
      hintText: 'yyyy-mm-dd',
      fillColor: Colors.white,
      validator: (value) {
        if (_attendDate == null) {
          return 'Please select attendance date';
        }
        return null;
      },
      onTap: widget.isReadOnly
          ? null
          : () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _attendDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now(),
                initialEntryMode: DatePickerEntryMode.calendarOnly,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: ColorsManger.primary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                setState(() {
                  _attendDate = picked;
                });
              }
            },
    );
  }

  Widget _buildHoursInput() {
    return AppTextFormField(
      controller: TextEditingController(text: _hours?.toString() ?? ''),
      labelText: widget.requestType == RequestType.extraHours
          ? 'Extra Hours'
          : 'Early Leave Hours',
      keyboardType: TextInputType.number,
      fillColor: Colors.white,
      prefixIcon: const Icon(Icons.access_time),
      readOnly: widget.isReadOnly,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter hours';
        }
        final parsed = int.tryParse(value);
        if (parsed == null || parsed <= 0 || parsed > 12) {
          return 'Please enter valid hours (1-12)';
        }
        return null;
      },
      onChanged: (value) {
        setState(() {
          _hours = int.tryParse(value);
        });
      },
    );
  }

  Widget _buildPermissionTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permission Type',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: widget.isReadOnly ? null : () {
                    setState(() {
                      _permissionType = PermissionType.lateArrival;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _permissionType == PermissionType.lateArrival
                            ? ColorsManger.primary
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: _permissionType == PermissionType.lateArrival
                          ? ColorsManger.primary.withValues(alpha: 0.1)
                          : Colors.white,
                    ),
                    child: Row(
                      children: [
                        Radio<PermissionType>(
                          value: PermissionType.lateArrival,
                          groupValue: _permissionType,
                          activeColor: ColorsManger.primary,
                          onChanged: widget.isReadOnly ? null : (value) {
                            setState(() {
                              _permissionType = value;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Late Arrival\n(متأخر في الحضور)',
                            style: TextStyle(
                              color: _permissionType == PermissionType.lateArrival
                                  ? ColorsManger.primary
                                  : Colors.black87,
                              fontWeight: _permissionType == PermissionType.lateArrival
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: widget.isReadOnly ? null : () {
                    setState(() {
                      _permissionType = PermissionType.earlyLeave;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _permissionType == PermissionType.earlyLeave
                            ? ColorsManger.primary
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: _permissionType == PermissionType.earlyLeave
                          ? ColorsManger.primary.withValues(alpha: 0.1)
                          : Colors.white,
                    ),
                    child: Row(
                      children: [
                        Radio<PermissionType>(
                          value: PermissionType.earlyLeave,
                          groupValue: _permissionType,
                          activeColor: ColorsManger.primary,
                          onChanged: widget.isReadOnly ? null : (value) {
                            setState(() {
                              _permissionType = value;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Early Leave\n(انصراف مبكر)',
                            style: TextStyle(
                              color: _permissionType == PermissionType.earlyLeave
                                  ? ColorsManger.primary
                                  : Colors.black87,
                              fontWeight: _permissionType == PermissionType.earlyLeave
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTimeInputs() {
    return Row(
      children: [
        Expanded(
          child: AppTextFormField(
            controller: _permissionHoursController,
            labelText: 'Hours (ساعات)',
            keyboardType: TextInputType.number,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.access_time),
            readOnly: widget.isReadOnly,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              final parsed = int.tryParse(value);
              if (parsed == null || parsed < 0 || parsed > 12) {
                return 'Invalid (0-12)';
              }
              // Check if both hours and minutes are zero
              final minutes = int.tryParse(_permissionMinutesController.text) ?? 0;
              if (parsed == 0 && minutes == 0) {
                return 'Time required';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppTextFormField(
            controller: _permissionMinutesController,
            labelText: 'Minutes (دقائق)',
            keyboardType: TextInputType.number,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.timer),
            readOnly: widget.isReadOnly,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              final parsed = int.tryParse(value);
              if (parsed == null || parsed < 0 || parsed > 59) {
                return 'Invalid (0-59)';
              }
              // Check if both hours and minutes are zero
              final hours = int.tryParse(_permissionHoursController.text) ?? 0;
              if (parsed == 0 && hours == 0) {
                return 'Time required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionUpload() {
    final hasFile = _prescriptionFile != null ||
        (widget.existingRequest?.details['prescription'] != null &&
         widget.existingRequest!.details['prescription'].toString().isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medical Prescription',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasFile ? Colors.green : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                hasFile ? Icons.check_circle : Icons.upload_file,
                size: 50,
                color: hasFile ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 10),
              Text(
                hasFile
                    ? (_prescriptionFile?.name ?? 'Prescription uploaded')
                    : 'Upload Medical Prescription',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: hasFile ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!widget.isReadOnly) ...[
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Show bottom sheet with options
                    await showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (bottomSheetContext) => Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Select Prescription',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Camera option
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
                              subtitle: const Text('Use camera to take a photo'),
                              onTap: () async {
                                Navigator.pop(bottomSheetContext);
                                try {
                                  final ImagePicker picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.camera,
                                    imageQuality: 85,
                                  );

                                  if (image != null) {
                                    final bytes = await image.readAsBytes();
                                    setState(() {
                                      _prescriptionFile = PlatformFile(
                                        name: image.name,
                                        size: bytes.length,
                                        bytes: bytes,
                                        path: image.path,
                                      );
                                    });
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    defToast2(
                                      context: context,
                                      msg: 'Error taking photo: $e',
                                      dialogType: DialogType.error,
                                    );
                                  }
                                }
                              },
                            ),

                            const Divider(),

                            // Gallery option
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
                              subtitle: const Text('Select an image from gallery'),
                              onTap: () async {
                                Navigator.pop(bottomSheetContext);
                                try {
                                  final ImagePicker picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 85,
                                  );

                                  if (image != null) {
                                    final bytes = await image.readAsBytes();
                                    setState(() {
                                      _prescriptionFile = PlatformFile(
                                        name: image.name,
                                        size: bytes.length,
                                        bytes: bytes,
                                        path: image.path,
                                      );
                                    });
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    defToast2(
                                      context: context,
                                      msg: 'Error picking image: $e',
                                      dialogType: DialogType.error,
                                    );
                                  }
                                }
                              },
                            ),

                            const Divider(),

                            // PDF option
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                              ),
                              title: const Text('Choose PDF'),
                              subtitle: const Text('Select a PDF file'),
                              onTap: () async {
                                Navigator.pop(bottomSheetContext);
                                try {
                                  final result = await FilePicker.platform.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['pdf'],
                                    withData: true, // Important for web
                                  );

                                  if (result != null && result.files.isNotEmpty) {
                                    setState(() {
                                      _prescriptionFile = result.files.first;
                                    });
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    defToast2(
                                      context: context,
                                      msg: 'Error picking PDF: $e',
                                      dialogType: DialogType.error,
                                    );
                                  }
                                }
                              },
                            ),

                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.attach_file),
                  label: Text(hasFile ? 'Change File' : 'Select File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManger.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
              // preview file
              if (widget.isReadOnly)
                ...[
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      _previewPrescription();
                    },
                    icon: const Icon(Icons.remove_red_eye),
                    label: const Text('Preview File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManger.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),

                ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoverageShiftFields() {
    final cubit = getIt<RequestCubit>();

    // Coverage date picker
    final coverageDateText = _coverageDate != null
        ? DateFormat('yyyy-MM-dd').format(_coverageDate!)
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Selection
        AppTextFormField(
          controller: TextEditingController(text: coverageDateText),
          readOnly: true,
          labelText: 'Coverage Date',
          suffixIcon: const Icon(Icons.calendar_today),
          hintText: 'yyyy-mm-dd',
          fillColor: Colors.white,
          validator: (value) {
            if (_coverageDate == null) {
              return 'Please select coverage date';
            }
            return null;
          },
          onTap: widget.isReadOnly
              ? null
              : () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _coverageDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialEntryMode: DatePickerEntryMode.calendarOnly,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: ColorsManger.primary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    setState(() {
                      _coverageDate = picked;
                    });
                  }
                },
        ),
        const SizedBox(height: 20),

        // Branch Selection
        Text(
          'Select Branch',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        AppDropdownButtonFormField<BranchModel>(
          value: cubit.selectedBranch,
          fillColor: Colors.white,
          items: cubit.branchesWithEmployees.keys.map((branch) {
            final employeeCount = cubit.branchesWithEmployees[branch]!.length;
            return DropdownMenuItem(
              value: branch,
              child: Text('${branch.name} ($employeeCount employees)',style: TextStyle(color: Colors.black),),
            );
          }).toList(),
          onChanged: widget.isReadOnly
              ? null
              : (branch) {
                  if (branch != null) {
                    cubit.setBranch(branch);
                  }
                },
          labelText: 'Branch',
          prefixIcon: const Icon(Icons.store),
          validator: (value) {
            if (value == null) {
              return 'Please select a branch';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Employee Selection
        if (cubit.selectedBranch != null) ...[
          Text(
            'Select Employee',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          AppDropdownButtonFormField<UserModel>(
            value: cubit.selectedEmployee,
            fillColor: Colors.white,
            items: cubit.branchesWithEmployees[cubit.selectedBranch]!
                .map((employee) {
              return DropdownMenuItem(
                value: employee,
                child: Row(
                  children: [
                    ProfileCircle(
                      photoUrl: employee.photoUrl,
                      size: 15,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(employee.name,style: TextStyle(color: Colors.black),)),
                  ],
                ),
              );
            }).toList(),
            onChanged: widget.isReadOnly
                ? null
                : (employee) {
                    setState(() {
                      cubit.selectedEmployee = employee;
                    });
                  },
            labelText: 'Employee',
            prefixIcon: const Icon(Icons.person),
            validator: (value) {
              if (value == null) {
                return 'Please select an employee';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildNotesField() {
    return AppTextFormField(
      controller: _notesController,
      labelText: 'Notes',
      hintText: 'Add any additional notes here...',
      fillColor: Colors.white,
      maxLines: 4,
      readOnly: widget.isReadOnly,
    );
  }

  Future<void> _previewPrescription() async {
    // Handles preview for prescription either from a local picked file or from existing request URL
    try {
      // Otherwise, try to read URL from existing request details
      final url = widget.existingRequest?.details['prescription']?.toString() ?? '';
      if (url.isEmpty) {
        await defToast2(
          context: context,
          msg: 'No prescription available to preview',
          dialogType: DialogType.warning,
        );
        return;
      }

      final uri = Uri.tryParse(url);
      if (uri == null) {
        throw 'Invalid prescription URL';
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Cannot open prescription URL';
      }
    } catch (e) {
      await defToast2(
        context: context,
        msg: 'Failed to preview prescription: $e',
        dialogType: DialogType.error,
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final cubit = getIt<RequestCubit>();

    // Build details based on request type
    Map<String, dynamic> details;

    try {
      switch (widget.requestType) {
        case RequestType.annualLeave:
          if (_startDate == null || _endDate == null) {
            throw 'Please select date range';
          }
          details = AnnualLeaveDetails(
            startDate: _startDate!,
            endDate: _endDate!,
          ).toJson();
          break;

        case RequestType.sickLeave:
          if (_startDate == null || _endDate == null) {
            throw 'Please select date range';
          }
          if (_prescriptionFile == null && widget.existingRequest == null) {
            throw 'Please upload medical prescription';
          }
          details = SickLeaveDetails(
            startDate: _startDate!,
            endDate: _endDate!,
            prescription: widget.existingRequest?.details['prescription'] ?? '',
          ).toJson();
          break;

        case RequestType.extraHours:
          if (_selectedDate == null || _hours == null) {
            throw 'Please fill all fields';
          }
          details = ExtraHoursDetails(
            date: _selectedDate!,
            hours: _hours!,
          ).toJson();
          break;

        case RequestType.coverageShift:
          if (_coverageDate == null) {
            throw 'Please select date';
          }
          if (cubit.selectedBranch == null || cubit.selectedEmployee == null) {
            throw 'Please select branch and employee';
          }

          // Validate using cubit method
          final hasLeave = await cubit.checkEmployeeHasLeaveOnDate(
            cubit.selectedEmployee!.uid,
            _coverageDate!,
          );
          if (hasLeave) {
            throw 'Selected employee has an approved leave on this date';
          }

          details = CoverageShiftDetails(
            peerEmployeeId: cubit.selectedEmployee!.uid,
            peerEmployeeName: cubit.selectedEmployee!.name,
            peerBranchId: cubit.selectedBranch!.id,
            peerBranchName: cubit.selectedBranch!.name,
            date: _coverageDate!,
          ).toJson();
          break;

        case RequestType.attend:
          if (_attendDate == null) {
            throw 'Please select attendance date';
          }
          details = AttendDetails(date: _attendDate!).toJson();
          break;

        case RequestType.permission:
          if (_selectedDate == null || _permissionType == null) {
            throw 'Please fill all required fields';
          }
          final hours = int.tryParse(_permissionHoursController.text) ?? 0;
          final minutes = int.tryParse(_permissionMinutesController.text) ?? 0;
          if (hours == 0 && minutes == 0) {
            throw 'Please enter hours and/or minutes';
          }
          details = PermissionDetails(
            date: _selectedDate!,
            type: _permissionType!,
            hours: hours,
            minutes: minutes,
          ).toJson();
          break;
      }

      // Use cubit's submitRequest method
      await cubit.submitRequest(
        requestType: widget.requestType,
        details: details,
        notes: _notesController.text,
        file: _prescriptionFile,
        existingRequest: widget.existingRequest,
      );
    } catch (e) {
      await defToast2(
        context: context,
        msg: e.toString(),
        dialogType: DialogType.error,
      );
    }
  }
}

class _AddRequestBackground extends StatelessWidget {
  const _AddRequestBackground();

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

  const _PanelCard({required this.child});

  @override
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: Colors.black87,
      ),
    );
  }
}
