import 'package:json_annotation/json_annotation.dart';

part 'salary_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SalaryModel {
  final String employeeUid; // كود الموظف uid (Document ID in sub-collection)

  // البيانات الأساسية
  final String pharmacyCode; // كود الصيدلية
  final String pharmacyName; // اسم الصيدلية
  final String acc; // ACC
  final String nameEnglish; // Name
  final String nameArabic; // الاسم

  // نظام العمل بالساعات
  final String hourlyRate; // الساعة الشهرية = مبلغ
  final String hoursWorked; // نظام العمل بالساعات

  // المرتب والحوافز
  final String basicSalary; // المرتب
  final String incentive; // الحافز
  final String additional; // الإضافي
  final String quarterlySalesIncentive; // حوافز مبيعات تبديل ربع سنوى
  final String workBonus; // مكافئة عن العمل
  final String administrativeBonus; // المكافئات الإدارية
  final String transportAllowance; // بدل مواصلات
  final String employerShare; // صاحب عمل
  final String eideya; // العيديات

  // الخصومات
  final String hourlyDeduction; // الخصم بالساعات
  final String penalties; // جزاءات
  final String pharmacyCodeDeduction; // خصم من كود السحب الدوائى
  final String visaDeduction; // خصم مصاريف فتح فيزا
  final String advanceDeduction; // خصم سلف
  final String quarterlyShiftDeficitDeduction; // خصم عجز الشيفتات الربع سنوى
  final String insuranceDeduction; // خصم تأمينات

  // النتيجة النهائية
  final String netSalary; // ما يستحقه العامل
  final String remainingAdvance; // المتبقي من السلف على العامل

  final String? notes; // ملاحظات

  final DateTime? uploadedAt; // تاريخ رفع الملف
  final String? uploadedBy; // من رفع الملف (Admin UID)

  SalaryModel({
    required this.employeeUid,
    required this.pharmacyCode,
    required this.pharmacyName,
    required this.acc,
    required this.nameEnglish,
    required this.nameArabic,
    required this.hourlyRate,
    required this.hoursWorked,
    required this.basicSalary,
    required this.incentive,
    required this.additional,
    required this.quarterlySalesIncentive,
    required this.workBonus,
    required this.administrativeBonus,
    required this.transportAllowance,
    required this.employerShare,
    required this.eideya,
    required this.hourlyDeduction,
    required this.penalties,
    required this.pharmacyCodeDeduction,
    required this.visaDeduction,
    required this.advanceDeduction,
    required this.quarterlyShiftDeficitDeduction,
    required this.insuranceDeduction,
    required this.netSalary,
    required this.remainingAdvance,
    this.notes,
    this.uploadedAt,
    this.uploadedBy,
  });

  factory SalaryModel.fromJson(Map<String, dynamic> json) =>
      _$SalaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$SalaryModelToJson(this);

  // نسخة فارغة للقيم الافتراضية
  factory SalaryModel.empty(String employeeUid) {
    return SalaryModel(
      employeeUid: employeeUid,
      pharmacyCode: '',
      pharmacyName: '',
      acc: '',
      nameEnglish: '',
      nameArabic: '',
      hourlyRate: '0',
      hoursWorked: '0',
      basicSalary: '0',
      incentive: '0',
      additional: '0',
      quarterlySalesIncentive: '0',
      workBonus: '0',
      administrativeBonus: '0',
      transportAllowance: '0',
      employerShare: '0',
      eideya: '0',
      hourlyDeduction: '0',
      penalties: '0',
      pharmacyCodeDeduction: '0',
      visaDeduction: '0',
      advanceDeduction: '0',
      quarterlyShiftDeficitDeduction: '0',
      insuranceDeduction: '0',
      netSalary: '0',
      remainingAdvance: '0',
    );
  }

  // حساب إجمالي الحوافز والمكافآت
  String get totalBonuses {
    try {
      final total = (double.tryParse(incentive) ?? 0) +
          (double.tryParse(additional) ?? 0) +
          (double.tryParse(quarterlySalesIncentive) ?? 0) +
          (double.tryParse(workBonus) ?? 0) +
          (double.tryParse(administrativeBonus) ?? 0) +
          (double.tryParse(transportAllowance) ?? 0) +
          (double.tryParse(eideya) ?? 0);
      return total.toStringAsFixed(2);
    } catch (e) {
      return '0';
    }
  }

  // حساب إجمالي الخصومات
  String get totalDeductions {
    try {
      final total = (double.tryParse(hourlyDeduction) ?? 0) +
          (double.tryParse(penalties) ?? 0) +
          (double.tryParse(pharmacyCodeDeduction) ?? 0) +
          (double.tryParse(visaDeduction) ?? 0) +
          (double.tryParse(advanceDeduction) ?? 0) +
          (double.tryParse(quarterlyShiftDeficitDeduction) ?? 0) +
          (double.tryParse(insuranceDeduction) ?? 0) +
          (double.tryParse(employerShare) ?? 0);
      return total.toStringAsFixed(2);
    } catch (e) {
      return '0';
    }
  }
}

