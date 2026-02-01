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
          'Monthly Target · ${currentUser.currentBranch.name}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: ColorsManger.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ColorsManger.primary,
                ColorsManger.primary.withValues(alpha: 0.86),
                ColorsManger.primary.withValues(alpha: 0.74),
              ],
            ),
          ),
        ),
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
        child: Stack(
          children: [
            const _TargetBackground(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderCard(
                        title: 'Set your monthly sales target',
                        subtitle:
                            'Choose the month, then enter the target amount for this branch.',
                      ),
                      const SizedBox(height: 12),

                      // Month selector
                      _MonthCard(
                        monthLabel: DateFormat('MMMM yyyy').format(_selectedDate),
                        onTap: _selectMonth,
                      ),
                      const SizedBox(height: 12),

                      BlocBuilder<BranchTargetCubit, BranchTargetState>(
                        builder: (context, state) {
                          final isLoading = state is BranchTargetLoading;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _TargetCard(
                                child: AppTextFormField(
                                  controller: _targetController,
                                  labelText: 'Monthly Target (EGP)',
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
                              ),
                              const SizedBox(height: 14),

                              SizedBox(
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: isLoading ? null : _saveMonthlyTarget,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorsManger.primary,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        ColorsManger.primary.withValues(alpha: 0.55),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 2,
                                  ),
                                  icon: isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.save),
                                  label: Text(
                                    isLoading ? 'Saving…' : 'Save Monthly Target',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
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
          ],
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

class _TargetBackground extends StatelessWidget {
  const _TargetBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColorsManger.primary.withValues(alpha: 0.10),
            ColorsManger.primaryBackground,
            ColorsManger.primaryBackground,
          ],
        ),
      ),
      child: Stack(
        children: const [
          _GlowBlob(
            alignment: Alignment(-1.05, -0.85),
            radius: 180,
            color: Color(0x3300B4D8),
          ),
          _GlowBlob(
            alignment: Alignment(1.10, -0.25),
            radius: 220,
            color: Color(0x22008AC7),
          ),
          _GlowBlob(
            alignment: Alignment(0.15, 1.10),
            radius: 260,
            color: Color(0x1A00B4D8),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Alignment alignment;
  final double radius;
  final Color color;

  const _GlowBlob({
    required this.alignment,
    required this.radius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: radius,
        height: radius,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.85),
              blurRadius: radius,
              spreadRadius: radius * 0.25,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeaderCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ColorsManger.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.flag, color: ColorsManger.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  final String monthLabel;
  final VoidCallback onTap;

  const _MonthCard({required this.monthLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ColorsManger.primary.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: ColorsManger.primary.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorsManger.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_month, color: ColorsManger.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Month',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withValues(alpha: 0.50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      monthLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  final Widget child;

  const _TargetCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

