import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/request/data/models/request_model.dart';
import 'package:pharmacy/features/request/logic/request_cubit.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/helpers/server_timestamp_helper.dart';
import '../../../core/widgets/app_text_form_field.dart';

class AddAnnualRequestScreen extends StatefulWidget {
  final RequestModel? requestModel;
  final bool? isReadOnly ;
  const AddAnnualRequestScreen({super.key,this.requestModel, this.isReadOnly = false});

  @override
  State<AddAnnualRequestScreen> createState() => _AddAnnualRequestScreenState();
}

class _AddAnnualRequestScreenState extends State<AddAnnualRequestScreen> {
  GlobalKey<FormState> formKey = GlobalKey();
  DateTime? startDate;
  DateTime? endDate;
  TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    if (widget.requestModel != null) {
      final annualLeaveDetails = AnnualLeaveDetails.fromJson(widget.requestModel!.details);
      startDate = annualLeaveDetails.startDate;
      endDate = annualLeaveDetails.endDate;
      notesController.text = widget.requestModel!.notes ?? '';
    }
    super.initState();
  }
  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: ColorsManger.primaryBackground,
        appBar: AppBar(title: const Text('Annual Leave Request'),backgroundColor: ColorsManger.primary,foregroundColor: Colors.white,centerTitle: true,),
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
                      'Annual Leave Details',
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
                /// Start and End Date
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
                const SizedBox(height: 7),
                /// Number of Days
                if (startDate != null && endDate != null)
                  Align(
                    alignment: Alignment.centerRight.add(const Alignment(-0.02, 0)),
                    child: Text(
                      'Number of Days: ${startDate != null && endDate != null ? endDate!.difference(startDate!).inDays + 1 : 0} days',
                    ),
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
        bottomNavigationBar:widget.isReadOnly == true? null :
    Row(
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
                      type: RequestType.annualLeave,
                      details: AnnualLeaveDetails(
                        startDate: startDate!,
                        endDate: endDate!,
                      ).toJson(),
                      notes: notesController.text,
                      status: RequestStatus.pending,
                      employeeId: currentUser.uid,
                      employeeName: currentUser.name,
                      employeePhone: currentUser.phone,
                      employeeBranchId: currentUser.branchId,
                      employeeBranchName: currentUser.branchName,
                      employeePhoto: currentUser.photoUrl,
                    );
                    getIt<RequestCubit>().addRequest(request: request, docRef: docRef);


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
                      // Submit the request
                      final RequestModel updatedRequest = widget.requestModel!.copyWith(
                        details: AnnualLeaveDetails(
                          startDate: startDate!,
                          endDate: endDate!,
                        ).toJson(),
                        notes: notesController.text,
                      );
                      getIt<RequestCubit>().updateRequest(
                        request: updatedRequest,
                      );


                    }
                  },
                  child: Container(
                    height: 50,
                    color: ColorsManger.primary,
                    child: Center(
                      child: Text(
                        'Edit',
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
