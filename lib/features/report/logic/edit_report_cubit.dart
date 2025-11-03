import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/features/report/data/models/daily_report_model.dart';
import 'package:pharmacy/features/report/logic/edit_report_state.dart';

class EditReportCubit extends Cubit<EditReportState> {
  EditReportCubit() : super(EditReportInitial());

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// تحديث الريبورت
  /// البنية: daily_reports/{date}/branches/{branchId}/shifts/{shiftType}
  Future<void> updateReport(ShiftReportModel report, String date) async {
    emit(EditReportLoading());

    try {
      final reportData = report.toJson();
      reportData['updatedAt'] = FieldValue.serverTimestamp();

      // Update في المسار الصحيح
      await _db
          .collection('daily_reports')
          .doc(date)
          .collection('branches')
          .doc(report.branchId)
          .collection('shifts')
          .doc(report.shiftType.name)
          .update(reportData);

      emit(EditReportSuccess());
    } catch (e) {
      emit(EditReportError(message: e.toString()));
    }
  }
}

