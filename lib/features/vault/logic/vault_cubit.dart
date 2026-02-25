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
      final totalWithdrawn = await ReportFirestoreHelper.getTotalWithdrawn();
      final withdrawals = await ReportFirestoreHelper.getVaultExpenses();

      emit(VaultLoaded(
        totalCollected: totalCollected,
        totalWithdrawn: totalWithdrawn,
        balance: totalCollected - totalWithdrawn,
        withdrawals: withdrawals,
      ));
    } catch (e) {
      emit(VaultError(message: e.toString()));
    }
  }

  /// سحب / مصروف من البنك
  Future<void> addWithdrawal({
    required double amount,
    required String description,
  }) async {
    if (amount <= 0) {
      emit(VaultError(message: 'Amount must be greater than zero'));
      return;
    }

    emit(VaultWithdrawLoading());

    try {
      await ReportFirestoreHelper.addVaultExpense(
        amount: amount,
        description: description,
        createdBy: currentUser.uid,
        createdByName: currentUser.name,
      );

      await fetchVaultBalance();
    } catch (e) {
      emit(VaultError(message: e.toString()));
    }
  }
}
