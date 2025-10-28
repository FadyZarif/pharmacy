import 'package:flutter/material.dart';
import 'package:pharmacy/core/themes/colors.dart';

class SalaryScreen extends StatelessWidget {
  const SalaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManger.primaryBackground,
      appBar: AppBar(
        title: const Text('Salary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: ColorsManger.primary,
      ),
      body: const Center(
        child: Text('Salary details will be shown here'),
      ),
    );
  }
}

