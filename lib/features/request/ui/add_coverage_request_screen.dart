import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/features/branch/data/branch_model.dart';
import 'package:pharmacy/features/request/logic/request_cubit.dart';
import 'package:pharmacy/features/request/logic/request_state.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/helpers/constants.dart';
import '../../../core/helpers/server_timestamp_helper.dart';
import '../../../core/themes/colors.dart';
import '../../../core/widgets/app_dropdown_button_form_field.dart';
import '../../../core/widgets/app_text_form_field.dart';
import '../../user/data/models/user_model.dart';
import '../data/models/request_model.dart';

class AddCoverageRequestScreen extends StatefulWidget {
  final RequestModel? requestModel;
  final bool? isReadOnly ;
  const AddCoverageRequestScreen({super.key, this.requestModel, this.isReadOnly});

  @override
  State<AddCoverageRequestScreen> createState() => _AddCoverageRequestScreenState();
}

class _AddCoverageRequestScreenState extends State<AddCoverageRequestScreen> {
  RequestCubit requestCubit = getIt<RequestCubit>();

  GlobalKey<FormState> formKey = GlobalKey();
  DateTime? date;
  TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    CoverageShiftDetails? coverageShiftDetails;
    if (widget.requestModel != null) {
      coverageShiftDetails = CoverageShiftDetails.fromJson(widget.requestModel!.details);
      date = coverageShiftDetails.date;
      notesController.text = widget.requestModel!.notes ?? '';
    }
    requestCubit.preloadAllBranchesWithEmployees(coverageShiftDetails?.peerBranchId,coverageShiftDetails?.peerEmployeeId);

    super.initState();
  }
  @override
  void dispose() {
    notesController.dispose();
    requestCubit.selectedEmployee = null;
    requestCubit.selectedBranch = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<RequestCubit>().selectedBranch;
    // final isPassword = context.select((SignInCubit c) => c.isPassword);


    return Scaffold(
      backgroundColor: ColorsManger.primaryBackground,
      appBar: AppBar(title: const Text('Shift Coverage Request'),backgroundColor: ColorsManger.primary,foregroundColor: Colors.white,centerTitle: true,),
      body: BlocBuilder<RequestCubit, RequestState>(
        buildWhen: (_,current)=> current is FetchBranchesWithEmployeesLoading || current is FetchBranchesWithEmployeesSuccess ||current is FetchBranchesWithEmployeesFailure,
      builder: (context, state) {
              if(state is FetchBranchesWithEmployeesLoading ){
               return Center(child: CircularProgressIndicator(),);
              } else if (state is FetchBranchesWithEmployeesFailure){
                return Center(child: Text(state.error,style: TextStyle(color: Colors.red),),);
              }else {
                return SingleChildScrollView(
                  child: Form(
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
                                'Shift Coverage Details',
                                style: Theme
                                    .of(
                                  context,
                                )
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Spacer(),
                              if (widget.requestModel != null)
                                Container(
                                  width: 70,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: widget.requestModel!.status ==
                                        RequestStatus.approved
                                        ? Colors.green
                                        : widget.requestModel!.status ==
                                        RequestStatus.rejected
                                        ? Colors.red
                                        : Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.requestModel!.status.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white, fontSize: 12,),
                                  ),
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
                              if (date == null) {
                                return 'Please select start and end dates.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                  
                          /// Select Branch
                          AppDropdownButtonFormField<BranchModel>(
                            labelText: 'Select Branch',
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Colors.black12,
                                width: 1.3,
                              ),
                            ),
                            value: requestCubit.selectedBranch,
                            items: requestCubit.branchesWithEmployees.keys.map((branch){
                              return DropdownMenuItem<BranchModel>(
                                value: branch,
                                child: Text(branch.name,style: TextStyle(color: Colors.black),),
                              );
                            }).toList(),
                            onChanged:widget.isReadOnly == true?null: (value) {
                              requestCubit.setBranch(value!);
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'select branch';
                              } else {
                                return null;
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          /// Select Employee
                          AppDropdownButtonFormField<UserModel>(
                            labelText: 'Select Employee',
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Colors.black12,
                                width: 1.3,
                              ),
                            ),
                            value: requestCubit.selectedEmployee,
                            items:requestCubit.selectedBranch != null? requestCubit.branchesWithEmployees[requestCubit.selectedBranch]!.map((branch){
                              return DropdownMenuItem<UserModel>(
                                value: branch,
                                child: Text(branch.name,style: TextStyle(color: Colors.black),),
                              );
                            }).toList():[],
                            onChanged:widget.isReadOnly == true? null: (value) {
                              requestCubit.selectedEmployee = value;
                              // requestCubit.setBranch(value!);
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'select employee';
                              } else {
                                return null;
                              }
                            },
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
                );
              }

  },

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
                      type: RequestType.coverageShift,
                      details: CoverageShiftDetails(
                        date: date!,
                        peerBranchId: requestCubit.selectedBranch!.id,
                        peerBranchName: requestCubit.selectedBranch!.name,
                        peerEmployeeId: requestCubit.selectedEmployee!.uid,
                        peerEmployeeName: requestCubit.selectedEmployee!.name
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
                      details: CoverageShiftDetails(
                          date: date!,
                          peerBranchId: requestCubit.selectedBranch!.id,
                          peerBranchName: requestCubit.selectedBranch!.name,
                          peerEmployeeId: requestCubit.selectedEmployee!.uid,
                          peerEmployeeName: requestCubit.selectedEmployee!.name
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
