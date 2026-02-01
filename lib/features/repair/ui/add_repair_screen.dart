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

class AddRepairScreen extends StatefulWidget {
  const AddRepairScreen({super.key});

  @override
  State<AddRepairScreen> createState() => _AddRepairScreenState();
}

class _AddRepairScreenState extends State<AddRepairScreen> {
  GlobalKey<FormState> formKey = GlobalKey();
  String? deviceName;
  TextEditingController notesController = TextEditingController();

  @override
  void dispose() {
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
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: ColorsManger.primary),
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
                'Repair Report',
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
            const _RepairBackground(),
            BlocBuilder<RepairCubit, RepairState>(
              buildWhen: (_, current) =>
                  current is RepairFetchDevicesLoading ||
                  current is RepairFetchDevicesSuccess ||
                  current is RepairFetchDevicesError,
              builder: (context, state) {
                if (state is RepairFetchDevicesLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: ColorsManger.primary),
                  );
                } else if (state is RepairFetchDevicesError) {
                  return Center(
                    child: Text(state.error, style: const TextStyle(color: Colors.red)),
                  );
                } else {
                  final topPad = MediaQuery.of(context).padding.top;
                  return SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          topPad + kToolbarHeight + 12,
                          16,
                          22,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _PanelCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Repair Report Details',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  AppDropdownButtonFormField<String>(
                                    labelText: 'Select Device',
                                    fillColor: Colors.white,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.grey.withValues(alpha: 0.22),
                                        width: 1.3,
                                      ),
                                    ),
                                    value: deviceName,
                                    items: getIt<RepairCubit>().devices.map((device) {
                                      return DropdownMenuItem<String>(
                                        value: device,
                                        child: Text(
                                          device,
                                          style: const TextStyle(color: Colors.black),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        deviceName = value;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null) return 'Select Device';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  AppTextFormField(
                                    controller: notesController,
                                    maxLength: 200,
                                    labelText: 'Notes',
                                    fillColor: Colors.white,
                                    maxLines: 4,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'enter details notes';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    final docRef = FirebaseFirestore.instance
                                        .collection('repair_reports')
                                        .doc();
                                    RepairModel request = RepairModel(
                                      id: docRef.id,
                                      deviceName: deviceName!,
                                      notes: notesController.text,
                                      createdAt: null,
                                      branchId: currentUser.currentBranch.id,
                                      branchName: currentUser.currentBranch.name,
                                      employeeId: currentUser.uid,
                                      employeeName: currentUser.name,
                                    );
                                    getIt<RepairCubit>().addRepairReport(
                                      request: request,
                                      docRef: docRef,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.save, size: 20),
                                label: const Text(
                                  'Save',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorsManger.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
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
          ],
        ),
      ),
),
    );
  }
}

class _RepairBackground extends StatelessWidget {
  const _RepairBackground();

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
