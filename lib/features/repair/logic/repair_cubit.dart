import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/features/repair/data/models/repair_model.dart';
import 'package:pharmacy/features/repair/logic/repair_state.dart';

import '../../branch/data/branch_model.dart';


class RepairCubit extends Cubit<RepairState> {
  RepairCubit() : super(RepairInitial());

  List<String> devices = [];

  fetchDevices() async {
    if(devices.isNotEmpty){
      emit(RepairFetchDevicesSuccess());
      return;
    }
    emit(RepairFetchDevicesLoading());
    try {
      // 1) هات كل الاجهزه
      final branchSnap = await FirebaseFirestore.instance
          .collection('branches')
          .doc(currentUser.currentBranch.id)
          .get();

      final branch = BranchModel.fromJson(branchSnap.data()!);
      devices = branch.devices;
      emit(RepairFetchDevicesSuccess());

    }catch(e){
      emit(RepairFetchDevicesError('Fetch Devices Error: $e'));
    }
  }

  addRepairReport({required RepairModel request,required DocumentReference docRef}) async {
    emit(AddRepairReportLoading());
    try {
      docRef.set(request.toJson());
      emit(AddRepairReportSuccess());
    } catch (e) {
      emit(AddRepairReportError(e.toString()));
    }
  }

  bool hasLoadedData = false; // Flag عشان نتحقق لو الداتا اتجابت

  /// Fetch repairs by branch and date
  fetchRepairsByBranchAndDate({required String branchId, required DateTime date,bool forceUpdate = false}) async {
    if(forceUpdate){
      hasLoadedData = false;
    }
    if (hasLoadedData) return;

    emit(FetchRepairsLoading());
    try {
      // Parse date to get start and end of day
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection('repair_reports')
          .where('branchId', isEqualTo: branchId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThanOrEqualTo:Timestamp.fromDate(endOfDay) )
          .orderBy('createdAt', descending: true)
          .get();

      final repairs = snapshot.docs
          .map((doc) => RepairModel.fromJson(doc.data()))
          .toList();

      emit(FetchRepairsSuccess(repairs));
      hasLoadedData = true; // اتأكد إنها اتجابت

    } catch (e) {
      emit(FetchRepairsError('Fetch Repairs Error: $e'));
    }
  }

  /// Fetch repairs from all branches for a specific month
  /// Only fetches from branches in currentUser.branches
  fetchRepairsByMonthForBranches({required DateTime month}) async {
    emit(FetchAllBranchesRepairsLoading());
    try {
      // Get branch IDs from currentUser.branches
      final branchIds = currentUser.branches.map((branch) => branch.id).toList();

      if (branchIds.isEmpty) {
        emit(FetchAllBranchesRepairsSuccess([]));
        return;
      }

      // Parse month to get start and end
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      print(startOfMonth);
      print(endOfMonth);

      final snapshot = await FirebaseFirestore.instance
          .collection('repair_reports')
          .where('branchId', whereIn: branchIds)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('createdAt', descending: true)
          .get();

      final repairs = snapshot.docs
          .map((doc) => RepairModel.fromJson(doc.data()))
          .toList();

      emit(FetchAllBranchesRepairsSuccess(repairs));

    } catch (e) {
      emit(FetchAllBranchesRepairsError('Fetch All Branches Repairs Error: $e'));
    }
  }

}
