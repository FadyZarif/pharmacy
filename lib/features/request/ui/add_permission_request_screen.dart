import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/helpers/constants.dart';
import '../../../core/helpers/server_timestamp_helper.dart';
import '../../../core/themes/colors.dart';
import '../../../core/widgets/app_text_form_field.dart';
import '../data/models/request_model.dart';
import '../logic/request_cubit.dart';
class AddPermissionRequestScreen extends StatefulWidget {
  final RequestModel? requestModel;
  final bool? isReadOnly ;
  const AddPermissionRequestScreen({super.key, this.requestModel, this.isReadOnly});

  @override
  State<AddPermissionRequestScreen> createState() => _AddPermissionRequestScreenState();
}

class _AddPermissionRequestScreenState extends State<AddPermissionRequestScreen> {
  GlobalKey<FormState> formKey = GlobalKey();
  DateTime? date;

  TextEditingController earlyHoursController = TextEditingController();
  TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    if (widget.requestModel != null) {
      final permissionDetails = PermissionDetails.fromJson(widget.requestModel!.details);
      date = permissionDetails.date;
      earlyHoursController.text = permissionDetails.hours.toString();
      notesController.text = widget.requestModel!.notes ?? '';
    }
    super.initState();
  }
  @override
  dispose() {
    earlyHoursController.dispose();
    notesController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManger.primaryBackground,
      appBar: AppBar(
        title: const Text('Permission Request'),
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
                    'Permission Details',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              /// Date Picker
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
                    firstDate: DateTime.now(),
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
                    return 'Please select start and end dates.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 7),
              /// Early Hours
              AppTextFormField(
                controller: earlyHoursController,
                keyboardType: TextInputType.number,
                labelText: 'Permission Hours',
                fillColor: Colors.white,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter extra hours.';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid number of hours.';
                  }
                  return null;
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                readOnly: widget.isReadOnly == true,

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
                    type: RequestType.permission,
                    details: PermissionDetails(
                      date: date!,
                      hours: int.parse(earlyHoursController.text),
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
                      details: PermissionDetails(
                        date: date!,
                        hours: int.parse(earlyHoursController.text),
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
