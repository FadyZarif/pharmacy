import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/enums/notification_type.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/services/notification_service.dart';
import 'package:pharmacy/features/salary/data/models/employee_monthly_salary.dart';
import 'package:pharmacy/features/salary/data/models/month_salary_model.dart';
import 'package:pharmacy/features/salary/data/models/salary_model.dart';
import 'package:pharmacy/features/salary/logic/salary_state.dart';

class SalaryCubit extends Cubit<SalaryState> {
  SalaryCubit() : super(SalaryInitial());

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _salarySubscription;

  /// جلب معلومات الشهر فقط (بدون بيانات الموظف)
  Future<void> fetchMonthInfo(String monthKey) async {
    try {
      final monthDoc = await _db.collection('salaries').doc(monthKey).get();

      if (!monthDoc.exists) {
        emit(MonthInfoLoaded(monthInfo: null));
      } else {
        final monthData = monthDoc.data()!;
        if (monthData['uploadedAt'] != null) {
          monthData['uploadedAt'] =
              (monthData['uploadedAt'] as Timestamp).toDate().toIso8601String();
        }
        final monthInfo = MonthSalaryModel.fromJson(monthData);
        emit(MonthInfoLoaded(monthInfo: monthInfo));
      }
    } catch (e) {
      emit(MonthInfoLoaded(monthInfo: null));
    }
  }

  /// جلب بيانات مرتب شهر معين
  Future<void> fetchSalaryByMonthKey(String monthKey) async {
    emit(SalaryLoading());

    try {
      final salary = await getSalaryByMonthKey(monthKey);

      if (salary == null) {
        emit(SalaryError(error: 'No data available for this month'));
      } else {
        emit(SingleSalaryLoaded(salary: salary));
      }
    } catch (e) {
      emit(SalaryError(error: e.toString()));
    }
  }

  /// جلب مرتب شهر معين بـ monthKey (مثل: "2024-11")
  Future<EmployeeMonthlySalary?> getSalaryByMonthKey(String monthKey) async {
    try {
      // جلب معلومات الشهر
      final monthDoc = await _db.collection('salaries').doc(monthKey).get();

      if (!monthDoc.exists) {
        return null;
      }

      final monthData = monthDoc.data()!;
      if (monthData['uploadedAt'] != null) {
        monthData['uploadedAt'] =
            (monthData['uploadedAt'] as Timestamp).toDate().toIso8601String();
      }

      final monthInfo = MonthSalaryModel.fromJson(monthData);

      // جلب بيانات الموظف
      final employeeDoc = await _db
          .collection('salaries')
          .doc(monthKey)
          .collection('employees')
          .doc(currentUser.uid)
          .get();

      if (!employeeDoc.exists) {
        return null;
      }

      final salaryData = SalaryModel.fromJson(employeeDoc.data()!);

      return EmployeeMonthlySalary(
        monthInfo: monthInfo,
        salaryData: salaryData,
      );
    } catch (e) {
      return null;
    }
  }

  /// رفع بيانات المرتبات من ملف Excel
  Future<void> uploadSalaryFromExcel({
    required String filePath,
    required int year,
    required int month,
    String? notes,
  }) async {
    emit(SalaryUploading());

    try {
      // قراءة ملف Excel
      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      // الحصول على أول ورقة عمل
      if (excel.tables.isEmpty) {
        emit(SalaryError(error: 'File is empty or invalid'));
        return;
      }

      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null || sheet.rows.isEmpty) {
        emit(SalaryError(error: 'Sheet is empty'));
        return;
      }

      // إنشاء monthKey
      final monthKey = MonthSalaryModel.createMonthKey(year, month);

      // قائمة لتخزين بيانات الموظفين
      final List<SalaryModel> salaries = [];

      // قراءة البيانات من الصفوف (نبدأ من الصف 3 لأن الصف 1 رأس والصف 2 عناوين)
      // في Excel index يبدأ من 0، لذا الصف 3 = index 2
      for (int i = 2; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];

        // تخطي الصفوف الفارغة
        if (row.isEmpty || row.every((cell) => cell?.value == null)) {
          continue;
        }

        try {
          // استخراج البيانات من الأعمدة حسب الترتيب الصحيح:
          // العمود 0: رقم تسلسلي (نتخطاه)
          // العمود 1: كود الموظف uid
          // العمود 2: كود الصيدلية
          // العمود 3: اسم الصيدلية
          // العمود 4: ACC
          // العمود 5: الاسم بالإنجليزية
          // العمود 6: الاسم بالعربية
          // العمود 7: الساعة الشهرية (hourlyRate)
          // العمود 8: نظام العمل بالساعات (hoursWorked)
          // العمود 9: المرتب (basicSalary)
          // العمود 10: الحافز (incentive)
          // العمود 11: الإضافي (additional)
          // العمود 12: حوافز مبيعات ربع سنوية (quarterlySalesIncentive)
          // العمود 13: مكافأة عن العمل (workBonus)
          // العمود 14: المكافآت الإدارية (administrativeBonus)
          // العمود 15: بدل مواصلات (transportAllowance)
          // العمود 16: صاحب عمل (employerShare)
          // العمود 17: العيديات (eideya)
          // العمود 18: الخصم بالساعات (hourlyDeduction)
          // العمود 19: جزاءات (penalties)
          // العمود 20: خصم من كود السحب الدوائي (pharmacyCodeDeduction)
          // العمود 21: خصم مصاريف فتح فيزا (visaDeduction)
          // العمود 22: خصم سلف (advanceDeduction)
          // العمود 23: خصم عجز الشيفتات الربع سنوي (quarterlyShiftDeficitDeduction)
          // العمود 24: خصم تأمينات (insuranceDeduction)
          // العمود 25: ما يستحقه العامل (netSalary)
          // العمود 26: المتبقي من السلف (remainingAdvance)
          // العمود 27: ملاحظات (notes) - اختياري

          final salary = SalaryModel(
            employeeUid: _getCellValue(row, 1), // كود الموظف
            pharmacyCode: _getCellValue(row, 2), // كود الصيدلية
            pharmacyName: _getCellValue(row, 3), // اسم الصيدلية
            acc: _getCellValue(row, 4), // ACC
            nameEnglish: _getCellValue(row, 5), // الاسم بالإنجليزية
            nameArabic: _getCellValue(row, 6), // الاسم بالعربية
            hourlyRate: _getCellValue(row, 7), // الساعة الشهرية
            hoursWorked: _getCellValue(row, 8), // نظام العمل بالساعات
            basicSalary: _getCellValue(row, 9), // المرتب
            incentive: _getCellValue(row, 10), // الحافز
            additional: _getCellValue(row, 11), // الإضافي
            quarterlySalesIncentive:
            _getCellValue(row, 12), // حوافز مبيعات ربع سنوية
            workBonus: _getCellValue(row, 13), // مكافأة عن العمل
            administrativeBonus: _getCellValue(row, 14), // المكافآت الإدارية
            transportAllowance: _getCellValue(row, 15), // بدل مواصلات
            employerShare: _getCellValue(row, 16), // صاحب عمل
            eideya: _getCellValue(row, 17), // العيديات
            hourlyDeduction: _getCellValue(row, 18), // الخصم بالساعات
            penalties: _getCellValue(row, 19), // جزاءات
            pharmacyCodeDeduction:
            _getCellValue(row, 20), // خصم من كود السحب الدوائي
            visaDeduction: _getCellValue(row, 21), // خصم مصاريف فتح فيزا
            advanceDeduction: _getCellValue(row, 22), // خصم سلف
            quarterlyShiftDeficitDeduction:
            _getCellValue(row, 23), // خصم عجز الشيفتات
            insuranceDeduction: _getCellValue(row, 24), // خصم تأمينات
            netSalary: _getCellValue(row, 25), // ما يستحقه العامل
            remainingAdvance: _getCellValue(row, 26), // المتبقي من السلف
            notes: notes ?? _getCellValue(row, 27), // ملاحظات من الملف أو المدخلة
            uploadedAt: DateTime.now(),
            uploadedBy: currentUser.uid,
          );

          // تأكد من أن employeeUid موجود
          if (salary.employeeUid.isEmpty || salary.employeeUid == '0') {
            continue;
          }

          salaries.add(salary);
        } catch (e) {
          // تخطي الصف في حالة وجود خطأ
          print('خطأ في الصف ${i + 1}: $e');
          continue;
        }
      }

      if (salaries.isEmpty) {
        emit(SalaryError(error: 'No valid data found in the file'));
        return;
      }

      // حذف البيانات القديمة أولاً (Overwrite)
      final monthDoc = _db.collection('salaries').doc(monthKey);

      // جلب جميع وثائق الموظفين القديمة
      final oldEmployeesSnapshot = await monthDoc.collection('employees').get();

      // حذف جميع وثائق الموظفين القديمة
      if (oldEmployeesSnapshot.docs.isNotEmpty) {
        final deleteBatch = _db.batch();
        for (final doc in oldEmployeesSnapshot.docs) {
          deleteBatch.delete(doc.reference);
        }
        await deleteBatch.commit();
        print('Deleted ${oldEmployeesSnapshot.docs.length} old employee records');
      }

      // رفع البيانات الجديدة
      final uploadBatch = _db.batch();

      // إنشاء أو تحديث وثيقة الشهر
      final monthData = MonthSalaryModel.create(
        year: year,
        month: month,
        uploadedBy: currentUser.uid,
        employeeCount: salaries.length,
        notes: notes,
      );
      uploadBatch.set(monthDoc, monthData.toJson());

      // إضافة بيانات الموظفين الجديدة
      for (final salary in salaries) {
        final employeeDoc =
            monthDoc.collection('employees').doc(salary.employeeUid);
        uploadBatch.set(employeeDoc, salary.toJson());
      }

      // تنفيذ الدفعة
      await uploadBatch.commit();
      print('Uploaded ${salaries.length} new employee records');

      // Send notification to all employees who received salary
      await _sendSalaryUploadedNotification(salaries, monthKey, year, month);

      emit(SalaryUploadSuccess(employeeCount: salaries.length));
    } catch (e) {
      emit(SalaryError(error: 'Failed to upload data: $e'));
    }
  }

  /// مساعد لاستخراج قيمة الخلية وتحويلها لنص
  String _getCellValue(List<Data?> row, int index) {
    if (index >= row.length) return '0';
    final cell = row[index];
    if (cell == null || cell.value == null) return '0';

    final value = cell.value;

    // معالجة الأنواع المختلفة من القيم
    if (value is num) {
      // أرقام (int أو double)
      return value.toString();
    } else if (value is String) {
      // نصوص
      final trimmed = value.toString().trim();
      return trimmed.isEmpty ? '0' : trimmed;
    } else if (value is FormulaCellValue) {
      // معادلات Excel
      // package excel لا يقوم بحساب المعادلات تلقائياً
      // الحل الموصى به:
      // 1. في Excel، اضغط Ctrl+A لتحديد كل شيء
      // 2. انسخ البيانات (Ctrl+C)
      // 3. الصق كقيم (Paste Special > Values) بدلاً من المعادلات
      // 4. احفظ الملف

      // نرجع 0 افتراضياً للمعادلات غير المحسوبة
      print('تحذير: تم العثور على معادلة في العمود ${index + 1}. يُنصح بتحويل المعادلات إلى قيم قبل الرفع.');
      return '0';
    } else {
      // أي نوع آخر، نحوله لنص
      final str = value.toString().trim();
      return str.isEmpty ? '0' : str;
    }
  }

  /// Helper: Send notification to all employees when salary is uploaded
  Future<void> _sendSalaryUploadedNotification(
    List<SalaryModel> salaries,
    String monthKey,
    int year,
    int month,
  ) async {
    try {
      final notificationService = getIt<NotificationService>();

      // Get all employee IDs who received salary
      final employeeIds = salaries
          .map((salary) => salary.employeeUid)
          .where((uid) => uid.isNotEmpty && uid != '0')
          .toList();

      if (employeeIds.isEmpty) return;

      // Get month name in Arabic
      final monthNames = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      final monthName = monthNames[month - 1];

      await notificationService.sendNotificationToUsers(
        userIds: employeeIds,
        title: 'تم رفع المرتب',
        body: 'تم رفع مرتب شهر $monthName $year',
        type: NotificationType.salaryAdded,
        additionalData: {
          'monthKey': monthKey,
          'year': year.toString(),
          'month': month.toString(),
        },
      );
    } catch (e) {
      print('Error sending salary uploaded notification: $e');
    }
  }

  @override
  Future<void> close() {
    _salarySubscription?.cancel();
    return super.close();
  }
}