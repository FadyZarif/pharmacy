import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/core/widgets/app_text_form_field.dart';
import 'package:pharmacy/features/job_opportunity/logic/job_opportunity_cubit.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';
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
        appBar: AppBar(
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text('Add Job Opportunity',style: TextStyle(fontWeight: FontWeight.bold),),
          backgroundColor: ColorsManger.primary,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Candidate Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

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
                  const SizedBox(height: 16),

                  AppTextFormField(
                    controller: _whatsappPhoneController,
                    labelText: 'WhatsApp Phone',
                    hintText: 'Enter WhatsApp phone number',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      // You can add input formatters here if needed
                      FilteringTextInputFormatter.digitsOnly
                    ],
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
                  const SizedBox(height: 16),

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
                  const SizedBox(height: 16),

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
                      if (year == null || year < 1950 || year > DateTime.now().year) {
                        return 'Please enter a valid year';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

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
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed:  _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManger.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

