import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/helpers/constants.dart';
import '../../../core/helpers/server_timestamp_helper.dart';
import '../../../core/themes/colors.dart';
import '../../../core/widgets/app_text_form_field.dart';
import '../data/models/request_model.dart';
import '../logic/request_cubit.dart';

class AddSickRequestScreen extends StatefulWidget {
  final RequestModel? requestModel;
  final bool? isReadOnly ;
  const AddSickRequestScreen({super.key, this.requestModel, this.isReadOnly});

  @override
  State<AddSickRequestScreen> createState() => _AddSickRequestScreenState();
}

class _AddSickRequestScreenState extends State<AddSickRequestScreen> {
  GlobalKey<FormState> formKey = GlobalKey();
  DateTime? startDate;
  DateTime? endDate;
  TextEditingController notesController = TextEditingController();

  PlatformFile? file;
  String? fileName ;

  Future<void> pickFile() async {
    // نفتح نافذة اختيار الملف pdf
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.isNotEmpty) {

      setState(() {
        file = result.files.first;
        fileName = file?.name;
      });
    } else {
      // المستخدم لغى الاختيار
      setState(() {
        file = null;
        fileName = null;
      });
    }
  }
  void deleteFile() {
    setState(() {
      fileName = null;
    });
  }

  String getFileNameFromUrl(String url) {
    // نحذف أي parameters بعد علامة الاستفهام
    String cleanUrl = url.split('?').first;

    // نفك الترميز من الرموز (%20 الخ)
    String decoded = Uri.decodeFull(cleanUrl);

    // نجيب آخر جزء من المسار (اسم الملف كامل)
    String fileName = decoded.split('/').last;

    // نحذف الجزء اللي قبل أول "_"
    if (fileName.contains('_')) {
      fileName = fileName.split('_').skip(1).join('_');
    }

    return fileName;
  }


  @override
  void initState() {
    if(widget.requestModel != null) {
      final sickLeaveDetails = SickLeaveDetails.fromJson(widget.requestModel!.details);
      startDate = sickLeaveDetails.startDate;
      endDate = sickLeaveDetails.endDate;
      notesController.text = widget.requestModel!.notes ?? '';
      fileName =  getFileNameFromUrl(sickLeaveDetails.prescription);
    }
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    notesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManger.primaryBackground,
      appBar: AppBar(
        title: const Text('Sick Leave Request'),
        backgroundColor: ColorsManger.primary,foregroundColor: Colors.white,centerTitle: true,
      ),
      body: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Title and Status
              Row(
                children: [
                  Text(
                    'Sick Leave Details',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  if (widget.requestModel != null)
                    Container(
                      width: 70,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.requestModel!.status == RequestStatus.approved
                            ? Colors.green
                            : widget.requestModel!.status == RequestStatus.rejected
                            ? Colors.red
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.requestModel!.status.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white,fontSize: 12,),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 25),
              /// Start and End Date Picker
              AppTextFormField(
                readOnly: true,
                labelText: 'select start and end date',
                suffixIcon: Icon(Icons.calendar_today),
                hintText: 'yyyy-mm-dd to yyyy-mm-dd',
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.black12,
                    width: 1.3,
                  ),
                ),
                controller: TextEditingController(
                  text: startDate != null
                      ? '${dateFormat.format(startDate!)} To ${dateFormat.format(endDate!)}'
                      : '',
                ),
                onTap: () {
                  if (widget.isReadOnly == true) {
                    return;
                  }
                  showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now().add(Duration(days: 1)),
                    lastDate: DateTime(2100),
                    initialEntryMode: DatePickerEntryMode.calendarOnly,
                  ).then((selectedDateRange) {
                    if (selectedDateRange != null) {
                      setState(() {
                        startDate = selectedDateRange.start;
                        endDate = selectedDateRange.end;
                      });
                    }
                  });
                },
                validator: (value) {
                  if (startDate == null || endDate == null) {
                    return 'Please select start and end dates.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25,),
              /// File Picker
              if(fileName == null)
                ElevatedButton.icon(
                  onPressed: pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text("اختيار ملف"),
                ),
              /// Display selected file name
              if(fileName != null)
              Row(
                // mainAxisSize: MainAxisSize.min,
                children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          "Selected: $fileName",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if(widget.isReadOnly != true)
                    IconButton(
                      onPressed: deleteFile,
                      icon: const Icon(Icons.delete,color: Colors.white,),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              /// Notes
              AppTextFormField(
                controller: notesController,
                maxLength: 200,
                labelText: 'Notes (optional)',
                fillColor: Colors.white,
                maxLines: 4,
                readOnly: widget.isReadOnly == true,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar:widget.isReadOnly == true? null : Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                height: 50,
                color: ColorsManger.primary,
                child: Center(
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white,
          ),
          if (widget.isReadOnly != true && widget.requestModel == null)
           Expanded(
            child: InkWell(
              onTap: () {
                if (formKey.currentState!.validate()) {
                  // Submit the request
                  final docRef = FirebaseFirestore.instance.collection('requests').doc();
                  RequestModel request = RequestModel(
                    id: docRef.id,
                    type: RequestType.sickLeave,
                    details: SickLeaveDetails(
                      startDate: startDate!,
                      endDate: endDate!,
                      prescription: 'fileName',
                    ).toJson(),
                    notes: notesController.text,
                    status: RequestStatus.pending,
                    employeeId: currentUser.uid,
                    employeeName: currentUser.name,
                    employeePhone: currentUser.phone,
                    employeeBranchId: currentUser.currentBranch.id,
                    employeeBranchName: currentUser.currentBranch.name,
                    employeePhoto: currentUser.photoUrl,
                  );
                  getIt<RequestCubit>().addRequest(request: request, docRef: docRef, file: file);
                }
              },
              child: Container(
                height: 50,
                color: ColorsManger.primary,
                child: Center(
                  child: Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          if (widget.isReadOnly != true && widget.requestModel != null)
            Expanded(
              child: InkWell(
                onTap: () {
                  if (formKey.currentState!.validate()) {
                   final updatedRequest = widget.requestModel!.copyWith(
                      details: SickLeaveDetails(
                        startDate: startDate!,
                        endDate: endDate!,
                        prescription: widget.requestModel!.details['prescription'],
                      ).toJson(),
                      notes: notesController.text,
                    );
                    getIt<RequestCubit>().updateRequest(request: updatedRequest, file: file);
                  }
                },
                child: Container(
                  height: 50,
                  color: ColorsManger.primary,
                  child: Center(
                    child: Text(
                      'Update',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),

        ],
      ),
    );
  }
}
