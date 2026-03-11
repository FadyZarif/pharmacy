import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/features/report/data/helpers/report_firestore_helper.dart';

import 'vault_state.dart';

class VaultCubit extends Cubit<VaultState> {
  VaultCubit() : super(VaultInitial());

  /// جلب رصيد البنك: إجمالي المحصل - إجمالي المسحوب
  Future<void> fetchVaultBalance() async {
    emit(VaultLoading());

    try {
      final totalCollected = await ReportFirestoreHelper.getTotalCollected();
      final totalDeposited = await ReportFirestoreHelper.getTotalDeposited();
      final totalWithdrawn = await ReportFirestoreHelper.getTotalWithdrawn();
      final collectedEntries = await ReportFirestoreHelper.getCollectedEntries();
      final deposits = await ReportFirestoreHelper.getVaultDeposits();
      final withdrawals = await ReportFirestoreHelper.getVaultExpenses();

      emit(VaultLoaded(
        totalCollected: totalCollected,
        totalDeposited: totalDeposited,
        totalWithdrawn: totalWithdrawn,
        balance: (totalCollected + totalDeposited) - totalWithdrawn,
        collectedEntries: collectedEntries,
        deposits: deposits,
        withdrawals: withdrawals,
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
