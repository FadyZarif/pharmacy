
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
          .doc(currentUser.branchId)
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

}
