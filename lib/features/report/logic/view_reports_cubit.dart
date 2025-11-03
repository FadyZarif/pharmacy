import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/features/report/data/models/daily_report_model.dart';
import 'package:pharmacy/features/report/logic/view_reports_state.dart';

class ViewReportsCubit extends Cubit<ViewReportsState> {
  ViewReportsCubit() : super(ViewReportsInitial());

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// جلب جميع الريبورتات ليوم محدد
  /// البنية: daily_reports/{date}/branches/{branchId}/shifts/{shiftType}
  Future<void> fetchDailyReports(String dateKey) async {
    emit(ViewReportsLoading());

    try {
      // جلب كل الشيفتات للفرع في هذا اليوم
      final shiftsSnapshot = await _db
          .collection('daily_reports')
          .doc(dateKey)
          .collection('branches')
          .doc(currentUser.branchId)
          .collection('shifts')
          .get();

      if (shiftsSnapshot.docs.isEmpty) {
        emit(ViewReportsEmpty());
        return;
      }

      final reports = <ShiftReportModel>[];

      for (var doc in shiftsSnapshot.docs) {
        final report = ShiftReportModel.fromJson(doc.data());
        reports.add(report);
      }

      // ترتيب حسب نوع الشيفت
      reports.sort((a, b) => a.shiftType.index.compareTo(b.shiftType.index));

      emit(ViewReportsLoaded(reports: reports));
    } catch (e) {
      emit(ViewReportsError(message: e.toString()));
    }
  }
}

