import 'package:json_annotation/json_annotation.dart';
import 'package:pharmacy/core/helpers/server_timestamp_helper.dart';

part 'daily_report_model.g.dart';

/// نوع الوردية
@JsonEnum(alwaysCreate: true)
enum ShiftType {
  @JsonValue('midnight')
  midnight, // ميدنايت

  @JsonValue('morning')
  morning, // صباحي

  @JsonValue('afternoon')
  afternoon, // ظهر

  @JsonValue('evening')
  evening, // مسائي
}



/// نوع التغيير في الكمبيوتر (عجز أو زيادة)
@JsonEnum(alwaysCreate: true)
enum ComputerDifferenceType {
  @JsonValue('shortage')
  shortage, // عجز

  @JsonValue('excess')
  excess, // زيادة

  @JsonValue('none')
  none, // لا يوجد
}

/// نوع المصروف
@JsonEnum(alwaysCreate: true)
enum ExpenseType {
  @JsonValue('medicines')
  medicines, // أدوية (بديل نقدي)

  @JsonValue('delivery')
  delivery, // ديلفري

  @JsonValue('ahmedAboghonima')
  ahmedAboghonima, // أحمد أبوغنيمة

  @JsonValue('companyCollection')
  companyCollection, // تحصيل شركات

  @JsonValue('warehouseCollection')
  warehouseCollection, // تحصيل مخازن

  @JsonValue('electronicPayment')
  electronicPayment, // دفع إلكتروني

  @JsonValue('administrative')
  administrative, // مصاريف إدارية

  @JsonValue('accounting')
  accounting, // مصاريف حسابات

  @JsonValue('government')
  government, // مصاريف حكومية

  @JsonValue('other')
  other, // أخرى
}


/// طريقة الدفع الإلكتروني
@JsonEnum(alwaysCreate: true)
enum ElectronicPaymentMethod {
  @JsonValue('instapay')
  instapay, // إنستا باي

  @JsonValue('wallet')
  wallet, // محفظة

  @JsonValue('visa')
  visa, // فيزا
}

/// الموظفين الإداريين
@JsonEnum(alwaysCreate: true)
enum AdministrativeStaff {
  @JsonValue('fady_essam')
  fadyEssam, // فادي عصام

  @JsonValue('ragy_zakaria')
  ragyZakaria, // راجي ذكريا

  @JsonValue('bola_fahim')
  bolaFahim, // بولا فهيم

  @JsonValue('emad_fawzy')
  emadFawzy, // عماد فوزي
}

/// نوع المصروف الحكومي
@JsonEnum(alwaysCreate: true)
enum GovernmentExpenseType {
  @JsonValue('electricity')
  electricity, // كهرباء

  @JsonValue('water')
  water, // مياه

  @JsonValue('other')
  other, // أخرى
}

/// تقرير شيفت واحد
@JsonSerializable(explicitToJson: true)
class ShiftReportModel {
  final String id; // معرف فريد للشيفت
  final String branchId; // الفرع
  final String branchName;

  final ShiftType shiftType; // نوع الشيفت
  final String employeeId; // الموظف المسؤول عن الشيفت
  final String employeeName;
  final String? employeePhoto;
  final double drawerAmount; // الدرج (المبيعات)
  final List<ExpenseItem> expenses; // المصاريف الخاصة بالشيفت
  final String? notes; // ملاحظات الشيفت

  /// بيانات الكمبيوتر (عجز/زيادة) - خاصة بالشيفت
  final ComputerDifferenceType? computerDifferenceType;
  final double computerDifference;

  /// المحفظة الإلكترونية - خاصة بالشيفت
  final double electronicWalletAmount;

  /// مرفقات متعددة (صور أو PDFs) - خاصة بالشيفت
  final List<String> attachmentUrls;

  @ServerNullableTimestampConverter()
  final DateTime? updatedAt; // آخر تعديل

  @ServerTimestampOnNullConverter()
  final DateTime? submittedAt; // متى تم تسليم/حفظ الشيفت

  ShiftReportModel({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.shiftType,
    required this.employeeId,
    required this.employeeName,
    this.employeePhoto,
    required this.drawerAmount,
    this.expenses = const [],
    this.notes,
    this.computerDifferenceType,
    this.computerDifference = 0.0,
    this.electronicWalletAmount = 0.0,
    this.attachmentUrls = const [],
    this.updatedAt,
    this.submittedAt,
  });

  factory ShiftReportModel.fromJson(Map<String, dynamic> json) {
    // Migration logic: handle old 'attachmentUrl' field
    List<String> urls = [];

    // Check for new format (attachmentUrls list)
    if (json.containsKey('attachmentUrls') && json['attachmentUrls'] != null) {
      urls = (json['attachmentUrls'] as List<dynamic>)
          .map((e) => e as String)
          .toList();
    }
    // Check for old format (single attachmentUrl string)
    else if (json.containsKey('attachmentUrl') && json['attachmentUrl'] != null) {
      final oldUrl = json['attachmentUrl'] as String;
      if (oldUrl.isNotEmpty) {
        urls = [oldUrl]; // Convert single URL to list
      }
    }

    // Add the migrated URLs to json for processing
    json['attachmentUrls'] = urls;

    return _$ShiftReportModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ShiftReportModelToJson(this);

  /// حساب إجمالي مصاريف الشيفت
  double get totalExpenses {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// حساب مصاريف تغير الادويه
  double get medicineExpenses {
    return expenses
        .where((expense) => expense.type == ExpenseType.medicines)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// حساب مصاريف المحفظة الإلكترونية
  double get electronicWalletExpenses {
    return expenses
        .where((expense) => expense.type == ExpenseType.electronicPayment)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// حساب صافي الشيفت = الدرج - المصاريف
  double get netAmount {
    return drawerAmount - totalExpenses;
  }

  /// اسم الشيفت بالعربي
  String get shiftNameAr {
    switch (shiftType) {
      case ShiftType.midnight:
        return 'ميدنايت';
      case ShiftType.morning:
        return 'صباحي';
      case ShiftType.afternoon:
        return 'ظهر';
      case ShiftType.evening:
        return 'مسائي';
    }
  }

  ShiftReportModel copyWith({
    String? id,
    String? branchId,
    String? branchName,
    ShiftType? shiftType,
    String? employeeId,
    String? employeeName,
    String? employeePhoto,
    double? drawerAmount,
    List<ExpenseItem>? expenses,
    String? notes,
    ComputerDifferenceType? computerDifferenceType,
    double? computerDifference,
    double? electronicWalletAmount,
    List<String>? attachmentUrls,
    DateTime? updatedAt,
    DateTime? submittedAt,
  }) {
    return ShiftReportModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      shiftType: shiftType ?? this.shiftType,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeePhoto: employeePhoto ?? this.employeePhoto,
      drawerAmount: drawerAmount ?? this.drawerAmount,
      expenses: expenses ?? this.expenses,
      notes: notes ?? this.notes,
      computerDifferenceType: computerDifferenceType ?? this.computerDifferenceType,
      computerDifference: computerDifference ?? this.computerDifference,
      electronicWalletAmount: electronicWalletAmount ?? this.electronicWalletAmount,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
}

/// بند مصروف
@JsonSerializable()
class ExpenseItem {
  final String id; // معرف فريد للبند
  final ExpenseType type; // نوع المصروف

  // تفاصيل حسب نوع المصروف
  final String? deliveryArea; // منطقة الديلفري
  final String? companyName; // اسم الشركة (تحصيل شركات)
  final String? warehouseName; // اسم المخزن (تحصيل مخازن)
  final ElectronicPaymentMethod? electronicMethod; // طريقة الدفع الإلكتروني
  final AdministrativeStaff? administrativeStaff; // الموظف الإداري
  final GovernmentExpenseType? governmentType; // نوع المصروف الحكومي
  final String? other;

  final double amount; // المبلغ
  final String? notes; // ملاحظات إضافية
  final String? fileUrl; // رابط الملف المرفق (صورة أو PDF) - اختياري

  ExpenseItem({
    required this.id,
    required this.type,
    required this.amount,
    this.deliveryArea,
    this.companyName,
    this.warehouseName,
    this.electronicMethod,
    this.administrativeStaff,
    this.governmentType,
    this.other,
    this.notes,
    this.fileUrl,
  });

  factory ExpenseItem.fromJson(Map<String, dynamic> json) =>
      _$ExpenseItemFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseItemToJson(this);

  /// وصف المصروف (للعرض)
  String get description {
    switch (type) {
      case ExpenseType.medicines:
        return 'أدوية (بديل نقدي)';
      case ExpenseType.delivery:
        return 'ديلفري - ${deliveryArea ?? "غير محدد"}';
      case ExpenseType.ahmedAboghonima:
        return 'أحمد أبوغنيمة';
      case ExpenseType.companyCollection:
        return 'تحصيل شركات - ${companyName ?? "غير محدد"}';
      case ExpenseType.warehouseCollection:
        return 'تحصيل مخازن - ${warehouseName ?? "غير محدد"}';
      case ExpenseType.electronicPayment:
        String method = '';
        switch (electronicMethod) {
          case ElectronicPaymentMethod.instapay:
            method = 'إنستا باي';
            break;
          case ElectronicPaymentMethod.wallet:
            method = 'محفظة';
            break;
          case ElectronicPaymentMethod.visa:
            method = 'فيزا';
            break;
          default:
            method = 'غير محدد';
        }
        return 'دفع إلكتروني - $method';
      case ExpenseType.administrative:
        String staff = '';
        switch (administrativeStaff) {
          case AdministrativeStaff.fadyEssam:
            staff = 'فادي عصام';
            break;
          case AdministrativeStaff.ragyZakaria:
            staff = 'راجي ذكريا';
            break;
          case AdministrativeStaff.bolaFahim:
            staff = 'بولا فهيم';
            break;
          case AdministrativeStaff.emadFawzy:
            staff = 'عماد فوزي';
            break;
          default:
            staff = 'غير محدد';
        }
        return 'مصاريف إدارية - $staff';
      case ExpenseType.accounting:
        return 'مصاريف حسابات';
      case ExpenseType.government:
        String govType = '';
        switch (governmentType) {
          case GovernmentExpenseType.electricity:
            govType = 'كهرباء';
            break;
          case GovernmentExpenseType.water:
            govType = 'مياه';
            break;
          case GovernmentExpenseType.other:
            govType = 'أخرى';
            break;
          default:
            govType = 'غير محدد';
        }
        return 'مصاريف حكومية - $govType';
      case ExpenseType.other:
        return other ?? 'أخرى';
    }
  }

  ExpenseItem copyWith({
    String? id,
    ExpenseType? type,
    double? amount,
    String? deliveryArea,
    String? companyName,
    String? warehouseName,
    ElectronicPaymentMethod? electronicMethod,
    AdministrativeStaff? administrativeStaff,
    GovernmentExpenseType? governmentType,
    String? notes,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      deliveryArea: deliveryArea ?? this.deliveryArea,
      companyName: companyName ?? this.companyName,
      warehouseName: warehouseName ?? this.warehouseName,
      electronicMethod: electronicMethod ?? this.electronicMethod,
      administrativeStaff: administrativeStaff ?? this.administrativeStaff,
      governmentType: governmentType ?? this.governmentType,
      notes: notes ?? this.notes,
    );
  }
}



