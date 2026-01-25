import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/core/widgets/app_text_form_field.dart';
import 'package:pharmacy/features/branch/logic/branch_target_cubit.dart';
import 'package:pharmacy/features/branch/logic/branch_target_state.dart';

class BranchMonthlyTargetScreen extends StatefulWidget {
  const BranchMonthlyTargetScreen({super.key});

  @override
  State<BranchMonthlyTargetScreen> createState() =>
      _BranchMonthlyTargetScreenState();
}

class _BranchMonthlyTargetScreenState extends State<BranchMonthlyTargetScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _targetController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadMonthlyTarget();
  }

  void _loadMonthlyTarget() {
    final monthYear = DateFormat('yyyy-MM').format(_selectedDate);
    context.read<BranchTargetCubit>().getMonthlyTarget(
          branchId: currentUser.currentBranch.id,
          monthYear: monthYear,
        );
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Select Month',
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadMonthlyTarget();
    }
  }

  void _saveMonthlyTarget() {
    if (_formKey.currentState!.validate()) {
      final monthYear = DateFormat('yyyy-MM').format(_selectedDate);
      final target = int.parse(_targetController.text);

      context.read<BranchTargetCubit>().setMonthlyTarget(
            branchId: currentUser.currentBranch.id,
            monthYear: monthYear,
            monthlyTarget: target,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManger.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Monthly Target [${currentUser.currentBranch.name}]',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: ColorsManger.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<BranchTargetCubit, BranchTargetState>(
        listener: (context, state) {
          if (state is BranchTargetSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Monthly target saved successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is BranchTargetError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is BranchTargetFetched) {
            if (state.monthlyTarget != null) {
              _targetController.text = state.monthlyTarget.toString();
            } else {
              _targetController.clear();
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Month Selector Card
                Card(
                  elevation: 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: _selectMonth,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ColorsManger.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.calendar_month,
                              color: ColorsManger.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selected Month',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMMM yyyy').format(_selectedDate),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Monthly Target Input
                BlocBuilder<BranchTargetCubit, BranchTargetState>(
                  builder: (context, state) {
                    if (state is BranchTargetLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextFormField(
                          controller: _targetController,
                          labelText: 'Monthly Target',
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.monetization_on),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter monthly target';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            if (int.parse(value) <= 0) {
                              return 'Target must be greater than 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Save Button
                        ElevatedButton(
                          onPressed: _saveMonthlyTarget,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorsManger.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save Monthly Target',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }
}

