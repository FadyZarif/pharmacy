import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/features/report/data/helpers/report_firestore_helper.dart';

import 'vault_state.dart';

class VaultCubit extends Cubit<VaultState> {
  VaultCubit() : super(VaultInitial()) {
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    _filterTo = now;
    _filterFrom = now.subtract(const Duration(days: 30));
  }

  /// مدى التاريخ لعرض القوائم (افتراضي آخر 30 يوم؛ null = الكل)
  DateTime? _filterFrom;
  DateTime? _filterTo;

  /// الشهر المعروض لإجماليات البطاقتين (أول يوم من الشهر)
  late DateTime _selectedMonth;

  /// تعيين فلتر التاريخ ثم إعادة جلب القوائم
  void setDateFilter(DateTime? from, DateTime? to) {
    _filterFrom = from;
    _filterTo = to;
    fetchVaultBalance();
  }

  /// اختيار شهر معين: تُحدَّث البطاقتان وقائمة المعاملات لهذا الشهر
  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999);
    _filterFrom = _selectedMonth;
    _filterTo = monthEnd;
    fetchVaultBalance();
  }

  /// جلب رصيد البنك: إجمالي المحصل - إجمالي المسحوب. القوائم تُجلب حسب الفلتر.
  Future<void> fetchVaultBalance() async {
    emit(VaultLoading());

    try {
      final monthStart = _selectedMonth;
      final monthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59, 999);

      final totalCollected = await ReportFirestoreHelper.getTotalCollected();
      final totalDeposited = await ReportFirestoreHelper.getTotalDeposited();
      final totalWithdrawn = await ReportFirestoreHelper.getTotalWithdrawn();

      final monthlyCollected = await ReportFirestoreHelper.getTotalCollectedInRange(monthStart, monthEnd);
      final monthlyDeposited = await ReportFirestoreHelper.getTotalDepositedInRange(monthStart, monthEnd);
      final monthlyWithdrawn = await ReportFirestoreHelper.getTotalWithdrawnInRange(monthStart, monthEnd);

      final collectedEntries = await ReportFirestoreHelper.getCollectedEntries(
        from: _filterFrom,
        to: _filterTo,
      );
      final deposits = await ReportFirestoreHelper.getVaultDeposits(
        from: _filterFrom,
        to: _filterTo,
      );
      final withdrawals = await ReportFirestoreHelper.getVaultExpenses(
        from: _filterFrom,
        to: _filterTo,
      );

      emit(VaultLoaded(
        totalCollected: totalCollected,
        totalDeposited: totalDeposited,
        totalWithdrawn: totalWithdrawn,
        balance: (totalCollected + totalDeposited) - totalWithdrawn,
        monthlyTotalIn: monthlyCollected + monthlyDeposited,
        monthlyTotalWithdrawn: monthlyWithdrawn,
        collectedEntries: collectedEntries,
        deposits: deposits,
        withdrawals: withdrawals,
        filterFrom: _filterFrom,
        filterTo: _filterTo,
        selectedMonth: _selectedMonth,
      ));
    } catch (e) {
      emit(VaultError(message: e.toString()));
    }
  }

  /// Manual deposit into the bank
  /// depositItem: 'emad' | 'marhal' | 'other'. When 'other', description is the note.
  Future<void> addDeposit({
    required double amount,
    required String depositItem,
    String? description,
    String? comment,
    String? attachmentUrl,
  }) async {
    if (amount <= 0) {
      emit(VaultError(message: 'Amount must be greater than zero'));
      return;
    }

    emit(VaultWithdrawLoading());

    try {
      await ReportFirestoreHelper.addVaultDeposit(
        amount: amount,
        depositItem: depositItem,
        description: description,
        createdBy: currentUser.uid,
        createdByName: currentUser.name,
        comment: comment,
        attachmentUrl: attachmentUrl,
      );

      await fetchVaultBalance();
    } catch (e) {
      emit(VaultError(message: e.toString()));
    }
  }

  /// Update a deposit
  Future<void> updateDeposit({
    required String id,
    required double amount,
    required String depositItem,
    String? description,
    String? comment,
    String? attachmentUrl,
  }) async {
    if (amount <= 0) {
      emit(VaultError(message: 'Amount must be greater than zero'));
      return;
    }
    emit(VaultWithdrawLoading());
    try {
      await ReportFirestoreHelper.updateVaultDeposit(
        id: id,
        amount: amount,
        depositItem: depositItem,
        description: description,
        comment: comment,
        attachmentUrl: attachmentUrl,
      );
      await fetchVaultBalance();
    } catch (e) {
      emit(VaultError(message: e.toString()));
    }
  }

  /// Delete a deposit
  Future<void> deleteDeposit(String id) async {
    emit(VaultWithdrawLoading());
    try {
      await ReportFirestoreHelper.deleteVaultDeposit(id);
      await fetchVaultBalance();
    } catch (e) {
      emit(VaultError(message: e.toString()));
    }
  }

  /// سحب / مصروف من البنك
  /// withdrawalItem: 'deposit'|'warehouse'|'company'|'maintenance'|'other'. When 'other', description is the note.
  Future<void> addWithdrawal({
    required double amount,
    required String withdrawalItem,
    String? description,
    String? comment,
    String? attachmentUrl,
  }) async {
    if (amount <= 0) {
      emit(VaultError(message: 'Amount must be greater than zero'));
      return;
    }

    emit(VaultWithdrawLoading());

    try {
      await ReportFirestoreHelper.addVaultExpense(
        amount: amount,
        withdrawalItem: withdrawalItem,
        description: description,
        createdBy: currentUser.uid,
        createdByName: currentUser.name,
        comment: comment,
        attachmentUrl: attachmentUrl,
      );

      await fetchVaultBalance();
    } catch (e) {
      emit(VaultError(message: e.toString()));
    }
  }

  /// Update a withdrawal
  Future<void> updateWithdrawal({
    required String id,
    required double amount,
    required String withdrawalItem,
    String? description,
    String? comment,
    String? attachmentUrl,
  }) async {
    if (amount <= 0) {
      emit(VaultError(message: 'Amount must be greater than zero'));
      return;
    }
    emit(VaultWithdrawLoading());
    try {
      await ReportFirestoreHelper.updateVaultExpense(
        id: id,
        amount: amount,
        withdrawalItem: withdrawalItem,
        description: description,
        comment: comment,
        attachmentUrl: attachmentUrl,
      );
      await fetchVaultBalance();
    } catch (e) {
      emit(VaultError(message: e.toString()));
    }
  }

  /// Delete a withdrawal
  Future<void> deleteWithdrawal(String id) async {
    emit(VaultWithdrawLoading());
    try {
      await ReportFirestoreHelper.deleteVaultExpense(id);
      await fetchVaultBalance();
    } catch (e) {
      emit(VaultError(message: e.toString()));
    }
  }
}
