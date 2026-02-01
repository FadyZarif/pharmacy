// /// Example usage of ShiftReportWidgets
// /// This file demonstrates how to use the reusable shift report widgets
// ///
// /// Created as part of the refactoring to make widgets reusable across
// /// add_shift_report_screen.dart and edit_shift_report_screen.dart
//
// import 'package:flutter/material.dart';
// import 'package:pharmacy/features/report/data/models/daily_report_model.dart';
// import 'package:pharmacy/features/report/ui/widgets/shift_report_widgets.dart';
//
// class ShiftReportWidgetsExampleUsage extends StatefulWidget {
//   const ShiftReportWidgetsExampleUsage({super.key});
//
//   @override
//   State<ShiftReportWidgetsExampleUsage> createState() => _ShiftReportWidgetsExampleUsageState();
// }
//
// class _ShiftReportWidgetsExampleUsageState extends State<ShiftReportWidgetsExampleUsage> {
//   // Controllers
//   final _drawerController = TextEditingController();
//   final _computerDiffController = TextEditingController();
//   final _walletController = TextEditingController();
//   final _notesController = TextEditingController();
//
//   // State
//   ComputerDifferenceType _diffType = ComputerDifferenceType.none;
//   List<ExpenseItem> _expenses = [];
//   bool _isEditMode = true;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // 1. Info Section - Display branch, date, employee, shift info
//             ShiftReportWidgets.buildInfoSection(
//               branchName: 'Main Branch',
//               date: DateTime.now(),
//               employeeName: 'John Doe', // Optional
//               shiftType: 'Morning', // Optional
//             ),
//
//             const SizedBox(height: 24),
//
//             // 2. Drawer Amount Field
//             ShiftReportWidgets.buildDrawerAmountField(
//               controller: _drawerController,
//               readOnly: !_isEditMode,
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter drawer amount';
//                 }
//                 if (double.tryParse(value) == null) {
//                   return 'Please enter a valid number';
//                 }
//                 return null;
//               },
//             ),
//
//             const SizedBox(height: 20),
//
//             // 3. Computer Difference Section
//             ShiftReportWidgets.buildComputerDifferenceSection(
//               selectedType: _diffType,
//               controller: _computerDiffController,
//               readOnly: !_isEditMode,
//               onTypeChanged: (type) {
//                 setState(() {
//                   _diffType = type;
//                   if (type == ComputerDifferenceType.none) {
//                     _computerDiffController.clear();
//                   }
//                 });
//               },
//               validator: (value) {
//                 if (_diffType != ComputerDifferenceType.none) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter the amount';
//                   }
//                   if (double.tryParse(value) == null) {
//                     return 'Please enter a valid number';
//                   }
//                 }
//                 return null;
//               },
//             ),
//
//             const SizedBox(height: 20),
//
//             // 4. Electronic Wallet Field
//             ShiftReportWidgets.buildElectronicWalletField(
//               controller: _walletController,
//               readOnly: !_isEditMode,
//             ),
//
//             const SizedBox(height: 20),
//
//             // 5. Notes Field
//             ShiftReportWidgets.buildNotesField(
//               controller: _notesController,
//               readOnly: !_isEditMode,
//             ),
//
//             const SizedBox(height: 24),
//
//             // 6. Expenses Section
//             ShiftReportWidgets.buildExpensesSection(
//               expenses: _expenses,
//               onAddExpense: _isEditMode ? _showAddExpenseDialog : null,
//               onDeleteExpense: (expense) {
//                 setState(() {
//                   _expenses.remove(expense);
//                 });
//               },
//               isEditMode: _isEditMode,
//             ),
//
//             const SizedBox(height: 32),
//
//             // 7. Submit Button
//             if (_isEditMode)
//               ShiftReportWidgets.buildSubmitButton(
//                 label: 'Submit Report',
//                 onPressed: _handleSubmit,
//                 isLoading: false,
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showAddExpenseDialog() {
//     // Your add expense dialog implementation
//   }
//
//   void _handleSubmit() {
//     // Your submit logic
//   }
//
//   @override
//   void dispose() {
//     _drawerController.dispose();
//     _computerDiffController.dispose();
//     _walletController.dispose();
//     _notesController.dispose();
//     super.dispose();
//   }
// }
//
// /*
//  * WIDGET DESCRIPTIONS:
//  *
//  * 1. buildInfoSection:
//  *    - Shows static information (branch, date, employee, shift)
//  *    - Required: branchName, date
//  *    - Optional: employeeName, shiftType
//  *
//  * 2. buildDrawerAmountField:
//  *    - Input field for sales amount
//  *    - Supports readOnly mode
//  *    - Custom validator can be provided
//  *
//  * 3. buildComputerDifferenceSection:
//  *    - Three-button selector (None, Shortage, Excess)
//  *    - Shows amount input when not "None"
//  *    - Supports readOnly mode
//  *    - Custom validator can be provided
//  *
//  * 4. buildElectronicWalletField:
//  *    - Input field for electronic wallet balance
//  *    - Supports readOnly mode
//  *    - No validation required (optional field)
//  *
//  * 5. buildNotesField:
//  *    - Multi-line text input for notes
//  *    - Supports readOnly mode
//  *    - Max length 200 characters (in edit mode)
//  *
//  * 6. buildExpensesSection:
//  *    - Lists all expenses with total
//  *    - Add button (if onAddExpense provided)
//  *    - Delete button per expense (if isEditMode = true)
//  *    - Shows "No expenses yet" when empty
//  *
//  * 7. buildSubmitButton:
//  *    - Full-width button
//  *    - Custom label
//  *    - Shows loading indicator when isLoading = true
//  *
//  * BENEFITS OF THIS APPROACH:
//  *
//  * 1. DRY Principle: Don't Repeat Yourself
//  *    - Changes in one place affect all screens
//  *
//  * 2. Consistency:
//  *    - Same look and behavior everywhere
//  *
//  * 3. Maintainability:
//  *    - Easy to update and fix bugs
//  *
//  * 4. Reusability:
//  *    - Can be used in any new screen
//  *
//  * 5. Flexibility:
//  *    - readOnly mode for viewing
//  *    - Edit mode for modifications
//  *    - Custom validators
//  *    - Optional callbacks
//  */
//
