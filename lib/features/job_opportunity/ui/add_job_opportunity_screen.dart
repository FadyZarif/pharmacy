import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/core/widgets/app_text_form_field.dart';
import 'package:pharmacy/features/job_opportunity/logic/job_opportunity_cubit.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

import '../../../core/helpers/app_regex.dart';

class AddJobOpportunityScreen extends StatefulWidget {
  const AddJobOpportunityScreen({super.key});

  @override
  State<AddJobOpportunityScreen> createState() => _AddJobOpportunityScreenState();
}

class _AddJobOpportunityScreenState extends State<AddJobOpportunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _whatsappPhoneController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _graduationYearController = TextEditingController();
  final _residenceController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _whatsappPhoneController.dispose();
    _qualificationController.dispose();
    _graduationYearController.dispose();
    _residenceController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {

      context.read<JobOpportunityCubit>().addJobOpportunity(
        fullName: _fullNameController.text.trim(),
        whatsappPhone: _whatsappPhoneController.text.trim(),
        qualification: _qualificationController.text.trim(),
        graduationYear: _graduationYearController.text.trim(),
        address: _residenceController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
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
                'Add Job Opportunity',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.80),
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
          ),
        ),
        body: BlocListener<JobOpportunityCubit, JobOpportunityState>(
          listenWhen: (_, current) {
            return current is JobOpportunityAdding ||
                current is JobOpportunityAdded ||
                current is JobOpportunityAddingError;
          },
          listener: (context, state) {
            if(state is JobOpportunityAdding){
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

            }
            else if (state is JobOpportunityAdded) {
              Navigator.pop(context); // Close the loading dialog
              AwesomeDialog(
                context: context,
                dialogType: DialogType.success,
                animType: AnimType.rightSlide,
                title: 'Success',
                desc: state.message,
                btnOkOnPress: () {
                  Navigator.pop(context);
                },
              ).show();
            } else if (state is JobOpportunityAddingError) {
              Navigator.pop(context); // Close the loading dialog
              AwesomeDialog(
                context: context,
                dialogType: DialogType.error,
                animType: AnimType.rightSlide,
                title: 'Error',
                desc: state.error,
                btnOkOnPress: () {},
              ).show();
            }
          },
          child: Stack(
            children: [
              const _JobOpportunityBackground(),
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + kToolbarHeight + 12,
                  16,
                  22,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PanelCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Candidate Information',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 14),

                            AppTextFormField(
                              controller: _fullNameController,
                              labelText: 'Full Name',
                              hintText: 'Enter full name',
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter full name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            AppTextFormField(
                              controller: _whatsappPhoneController,
                              labelText: 'WhatsApp Phone',
                              hintText: 'Enter WhatsApp phone number',
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              maxLength: 11,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter phone number';
                                }
                                if (!AppRegex.isPhoneNumberValid(value)) {
                                  return 'Please enter valid phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            AppTextFormField(
                              controller: _qualificationController,
                              labelText: 'Qualification',
                              hintText: 'Enter qualification',
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter qualification';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            AppTextFormField(
                              controller: _graduationYearController,
                              labelText: 'Graduation Year',
                              hintText: 'Enter graduation year',
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter graduation year';
                                }
                                final year = int.tryParse(value);
                                if (year == null ||
                                    year < 1950 ||
                                    year > DateTime.now().year) {
                                  return 'Please enter a valid year';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            AppTextFormField(
                              controller: _residenceController,
                              labelText: 'Address',
                              hintText: 'Address',
                              textInputAction: TextInputAction.done,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter Address location';
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
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorsManger.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.send),
                          label: const Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobOpportunityBackground extends StatelessWidget {
  const _JobOpportunityBackground();

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

