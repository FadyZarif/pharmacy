import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/features/employee/logic/employee_layout_cubit.dart';
import 'package:pharmacy/features/repair/data/models/repair_model.dart';
import 'package:pharmacy/features/repair/logic/repair_cubit.dart';
import 'package:pharmacy/features/repair/logic/repair_state.dart';

import '../../../core/helpers/constants.dart';
import '../../../core/themes/colors.dart';
import '../../../core/widgets/app_dropdown_button_form_field.dart';
import '../../../core/widgets/app_text_form_field.dart';

class RepairReportScreen extends StatefulWidget {
  const RepairReportScreen({super.key});

  @override
  State<RepairReportScreen> createState() => _RepairReportScreenState();
}

class _RepairReportScreenState extends State<RepairReportScreen> {
  GlobalKey<FormState> formKey = GlobalKey();
  String? deviceName;
  TextEditingController notesController = TextEditingController();

  @override
  void dispose() {
    // TODO: implement dispose
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value:  getIt<RepairCubit>()..fetchDevices(),
      child: BlocListener<RepairCubit, RepairState>(
        listenWhen: (_,current)=>current is AddRepairReportLoading ||current is AddRepairReportSuccess ||current is AddRepairReportError,
  listener: (context, state) async {
    if (state is AddRepairReportLoading) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      if (state is AddRepairReportSuccess) {
        await defToast2(context: context, msg: 'report has been submitted successfully', dialogType: DialogType.success);

      } else if (state is AddRepairReportError) {
        await defToast2(context: context, msg: state.error, dialogType: DialogType.error);
      }
      if(!context.mounted) return;
      Navigator.pop(context);

      getIt<EmployeeLayoutCubit>().changeBottomNav(2);

    }
  },
  child: Scaffold(
        backgroundColor: ColorsManger.primaryBackground,
        appBar: AppBar(
          title: const Text('Repair Report'),
          backgroundColor: ColorsManger.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: BlocBuilder<RepairCubit, RepairState>(
          buildWhen: (_, current) =>
              current is RepairFetchDevicesLoading ||
              current is RepairFetchDevicesSuccess ||
              current is RepairFetchDevicesError,
          builder: (context, state) {
            if (state is RepairFetchDevicesLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is RepairFetchDevicesError) {
              return Center(
                child: Text(state.error, style: TextStyle(color: Colors.red)),
              );
            } else {
              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        /// Title
                        Text(
                          'Repair Report Details',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 25),

                        /// Select Device
                        AppDropdownButtonFormField<String>(
                          labelText: 'Select Device',
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Colors.black12,
                              width: 1.3,
                            ),
                          ),
                          value: deviceName,
                          items: getIt<RepairCubit>().devices.map((branch) {
                            return DropdownMenuItem<String>(
                              value: branch,
                              child: Text(
                                branch,
                                style: TextStyle(color: Colors.black),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            deviceName = value!;
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Select Device';
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
                          labelText: 'Notes',
                          fillColor: Colors.white,
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'enter details notes';
                            } else {
                              return null;
                            }
                          },
                        ),
                        const SizedBox(height: 60),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              // Submit the request
                              final docRef = FirebaseFirestore.instance
                                  .collection('repair_reports')
                                  .doc();
                              RepairModel request = RepairModel(
                                id: docRef.id,
                                deviceName: deviceName!,
                                notes: notesController.text,
                                createdAt: null,
                                branchId: currentUser.branchId,
                                branchName: currentUser.branchName,
                                employeeId: currentUser.uid,
                                employeeName: currentUser.name
                              );
                              getIt<RepairCubit>().addRepairReport(
                                request: request,
                                docRef: docRef,
                              );
                            }
                          },
                          icon: const Icon(Icons.save, size: 22),
                          label: const Text(
                            'Save',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A54F3),
                            // بنفسجي قريب من الصورة
                            foregroundColor: Colors.white,
                            // لون الأيقونة والنص
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadiusGeometry.circular(10),
                            ),
                            // Corners دائري بالكامل
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
),
    );
  }
}
