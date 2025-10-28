import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/helpers/constants.dart';
import '../../../core/helpers/server_timestamp_helper.dart';
import '../../../core/themes/colors.dart';
import '../../../core/widgets/app_text_form_field.dart';
import '../data/models/request_model.dart';
import '../logic/request_cubit.dart';

class AddAttendRequestScreen extends StatefulWidget {
  final RequestModel? requestModel;
  final bool? isReadOnly ;
  const AddAttendRequestScreen({super.key, this.requestModel, this.isReadOnly});

  @override
  State<AddAttendRequestScreen> createState() => _AddAttendRequestScreenState();
}

class _AddAttendRequestScreenState extends State<AddAttendRequestScreen> {
  GlobalKey<FormState> formKey = GlobalKey();
  DateTime? date;

  TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    if (widget.requestModel != null) {
      final attendDetails = AttendDetails.fromJson(widget.requestModel!.details);
      date = attendDetails.date;
      notesController.text = widget.requestModel!.notes ?? '';
    }
    super.initState();
  }
  @override
  dispose() {
    notesController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManger.primaryBackground,
      appBar: AppBar(
        title: const Text('Attend Request'),
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
                    'Attend Details',
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
              /// Date Field
              AppTextFormField(
                readOnly: true,
                labelText: 'Select Date',
                suffixIcon: Icon(Icons.calendar_today),
                hintText: 'yyyy-mm-dd',
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.black12,
                    width: 1.3,
                  ),
                ),
                controller: TextEditingController(
                  text: date != null
                      ? dateFormat.format(date!)
                      : '',
                ),
                onTap: () {
                  if (widget.isReadOnly == true) {
                    return;
                  }
                  showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(Duration(days: 30)),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  ).then((selectedDate) {
                    if (selectedDate != null) {
                      setState(() {
                        date = selectedDate;
                      });
                    }
                  });
                },
                validator: (value) {
                  if (date == null ) {
                    return 'Please select date.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              /// Notes Field
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
                    type: RequestType.attend,
                    details: AttendDetails(
                      date: date!,
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
                  // Update the request
                  final updatedRequest = widget.requestModel!.copyWith(
                    details: AttendDetails(
                      date: date!,
                    ).toJson(),
                    notes: notesController.text,
                  );
                  getIt<RequestCubit>().updateRequest(request: updatedRequest);
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
