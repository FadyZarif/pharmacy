import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/core/widgets/app_text_form_field.dart';
import 'package:pharmacy/features/report/data/models/daily_report_model.dart';

/// Reusable widgets for shift report screens
class ShiftReportWidgets {
  ShiftReportWidgets._(); // Private constructor to prevent instantiation

  /// Build the info section showing branch name, employee name, date and shift type
  static Widget buildInfoSection({
    required String branchName,
    required DateTime date,
    String? employeeName,
    String? shiftType,
  }) {
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Branch and Date Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Branch Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.store, color: ColorsManger.primary, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Branch',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      branchName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 70,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              // Date Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: ColorsManger.primary, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateFormat.format(date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Employee and Shift Type Row (if provided)
          if (employeeName != null || shiftType != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (employeeName != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: ColorsManger.primary, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Employee',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          employeeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                if (employeeName != null && shiftType != null)
                  Container(
                    width: 1,
                    height: 70,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                if (shiftType != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time, color: ColorsManger.primary, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Shift',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          shiftType,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build drawer amount field
  static Widget buildDrawerAmountField({
    required TextEditingController controller,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Drawer Amount (Sales) *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        AppTextFormField(
          controller: controller,
          labelText: 'Enter total sales amount',
          prefixIcon: const Icon(Icons.attach_money),
          keyboardType: TextInputType.number,
          fillColor: Colors.white,
          readOnly: readOnly,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: validator,
        ),
      ],
    );
  }

  /// Build computer difference section with type selection and amount field
  static Widget buildComputerDifferenceSection({
    required ComputerDifferenceType selectedType,
    required TextEditingController controller,
    required Function(ComputerDifferenceType) onTypeChanged,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Computer Difference',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        // Type selection buttons
        Row(
          children: [
            Expanded(
              child: _buildDifferenceTypeButton(
                label: 'None',
                type: ComputerDifferenceType.none,
                icon: Icons.check_circle,
                color: Colors.green,
                isSelected: selectedType == ComputerDifferenceType.none,
                onTap: readOnly ? null : () => onTypeChanged(ComputerDifferenceType.none),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDifferenceTypeButton(
                label: 'Shortage',
                type: ComputerDifferenceType.shortage,
                icon: Icons.remove_circle,
                color: Colors.red,
                isSelected: selectedType == ComputerDifferenceType.shortage,
                onTap: readOnly ? null : () => onTypeChanged(ComputerDifferenceType.shortage),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDifferenceTypeButton(
                label: 'Excess',
                type: ComputerDifferenceType.excess,
                icon: Icons.add_circle,
                color: Colors.blue,
                isSelected: selectedType == ComputerDifferenceType.excess,
                onTap: readOnly ? null : () => onTypeChanged(ComputerDifferenceType.excess),
              ),
            ),
          ],
        ),

        // Amount field (shown when type is not none)
        if (selectedType != ComputerDifferenceType.none) ...[
          const SizedBox(height: 12),
          AppTextFormField(
            controller: controller,
            labelText: 'Enter ${selectedType == ComputerDifferenceType.shortage ? "shortage" : "excess"} amount',
            prefixIcon: Icon(
              selectedType == ComputerDifferenceType.shortage
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
            ),
            fillColor: Colors.white,
            readOnly: readOnly,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: validator,
          ),
        ],
      ],
    );
  }

  /// Build difference type button
  static Widget _buildDifferenceTypeButton({
    required String label,
    required ComputerDifferenceType type,
    required IconData icon,
    required Color color,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build electronic wallet field
  static Widget buildElectronicWalletField({
    required TextEditingController controller,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Electronic Wallet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        AppTextFormField(
          controller: controller,
          labelText: 'Enter electronic wallet balance',
          prefixIcon: const Icon(Icons.account_balance_wallet),
          fillColor: Colors.white,
          readOnly: readOnly,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
        ),
      ],
    );
  }

  /// Build notes field
  static Widget buildNotesField({
    required TextEditingController controller,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        AppTextFormField(
          controller: controller,
          labelText: 'Add any additional notes',
          fillColor: Colors.white,
          readOnly: readOnly,
          maxLines: 3,
          maxLength: readOnly ? null : 200,
        ),
      ],
    );
  }

  /// Build expenses section
  static Widget buildExpensesSection({
    required List<ExpenseItem> expenses,
    VoidCallback? onAddExpense,
    required Function(ExpenseItem) onDeleteExpense,
    bool isEditMode = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Expenses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (onAddExpense != null)
              ElevatedButton.icon(
                onPressed: onAddExpense,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Expense'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManger.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (expenses.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No expenses yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              ...expenses.map((expense) => _buildExpenseCard(
                    expense: expense,
                    onDelete: isEditMode ? () => onDeleteExpense(expense) : null,
                  )),
              /*const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorsManger.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Expenses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'EGP -${_calculateTotalExpenses(expenses).toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ColorsManger.primary,
                      ),
                    ),
                  ],
                ),
              ),*/
            ],
          ),
      ],
    );
  }



  /// Build individual expense card
  static Widget _buildExpenseCard({
    required ExpenseItem expense,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ColorsManger.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.receipt,
              color: ColorsManger.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        expense.description,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (expense.fileUrl != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () async {
                          final url = Uri.parse(expense.fileUrl!);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: ColorsManger.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            expense.fileUrl!.toLowerCase().contains('pdf')
                                ? Icons.picture_as_pdf
                                : Icons.image,
                            color: ColorsManger.primary,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    expense.notes!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'EGP ${expense.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorsManger.primary,
                ),
              ),
            ],
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete, color: Colors.red),
              iconSize: 20,
            ),
          ],
        ],
      ),
    );
  }

  /// Calculate total expenses
  static double _calculateTotalExpenses(List<ExpenseItem> expenses) {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Build Financial Summary
  static   Widget buildFinancialSummary(String drawerAmount, List<ExpenseItem> expenses,) {
    final totalSales = double.tryParse(drawerAmount) ?? 0.0;
    final totalExpenses = expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
    final netProfit = totalSales - totalExpenses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Financial Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        // Total Sales Card
        buildSummaryCard(
          icon: Icons.attach_money,
          label: 'Total Sales',
          value: totalSales,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),

        // Total Expenses Card
        buildSummaryCard(
          icon: Icons.money_off,
          label: 'Total Expenses',
          value: totalExpenses,
          color: Colors.orange,
        ),
        const SizedBox(height: 12),

        // Net Profit Card
        buildSummaryCard(
          icon: netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
          label: 'Net Profit',
          value: netProfit,
          color: netProfit >= 0 ? Colors.green : Colors.red,
          isBold: true,
        ),
      ],
    );
  }

  /// Build individual summary card
  static Widget buildSummaryCard({
    required IconData icon,
    required String label,
    required double value,
    required Color color,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'EGP ${value.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isBold ? 20 : 18,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build submit button
  static Widget buildSubmitButton({
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsManger.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

