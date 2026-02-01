import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/features/branch/data/monthly_target_model.dart';
import 'package:pharmacy/features/branch/logic/branch_target_state.dart';

class BranchTargetCubit extends Cubit<BranchTargetState> {
  BranchTargetCubit() : super(BranchTargetInitial());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Set monthly target for a specific branch and month
  Future<void> setMonthlyTarget({
    required String branchId,
    required String monthYear, // Format: "2025-11"
    required int monthlyTarget,
  }) async {
    emit(BranchTargetLoading());
    try {
      final target = MonthlyTargetModel(
        monthYear: monthYear,
        monthlyTarget: monthlyTarget,
      );

      await _firestore
          .collection('branches')
          .doc(branchId)
          .collection('monthly_target')
          .doc(monthYear)
          .set(target.toJson());

      emit(BranchTargetSuccess());
    } catch (e) {
      emit(BranchTargetError('Failed to set monthly target: $e'));
    }
  }

  /// Get monthly target for a specific branch and month
  Future<void> getMonthlyTarget({
    required String branchId,
    required String monthYear,
  }) async {
    emit(BranchTargetLoading());
    try {
      final doc = await _firestore
          .collection('branches')
          .doc(branchId)
          .collection('monthly_target')
          .doc(monthYear)
          .get();

      if (doc.exists && doc.data() != null) {
        final target = MonthlyTargetModel.fromJson(doc.data()!);
        emit(BranchTargetFetched(target.monthlyTarget));
      } else {
        emit(BranchTargetFetched(null));
      }
    } catch (e) {
      emit(BranchTargetError('Failed to get monthly target: $e'));
    }
  }
}

