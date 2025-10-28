// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_report_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShiftReportModel _$ShiftReportModelFromJson(Map<String, dynamic> json) =>
    ShiftReportModel(
      id: json['id'] as String,
      branchId: json['branchId'] as String,
      branchName: json['branchName'] as String,
      shiftType: $enumDecode(_$ShiftTypeEnumMap, json['shiftType']),
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String,
      employeePhoto: json['employeePhoto'] as String?,
      drawerAmount: (json['drawerAmount'] as num).toDouble(),
      expenses:
          (json['expenses'] as List<dynamic>?)
              ?.map((e) => ExpenseItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      notes: json['notes'] as String?,
      computerDifferenceType: $enumDecodeNullable(
        _$ComputerDifferenceTypeEnumMap,
        json['computerDifferenceType'],
      ),
      computerDifference:
          (json['computerDifference'] as num?)?.toDouble() ?? 0.0,
      electronicWalletAmount:
          (json['electronicWalletAmount'] as num?)?.toDouble() ?? 0.0,
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      updatedAt: const ServerNullableTimestampConverter().fromJson(
        json['updatedAt'],
      ),
      submittedAt: const ServerTimestampOnNullConverter().fromJson(
        json['submittedAt'],
      ),
    );

Map<String, dynamic> _$ShiftReportModelToJson(ShiftReportModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'branchId': instance.branchId,
      'branchName': instance.branchName,
      'shiftType': _$ShiftTypeEnumMap[instance.shiftType]!,
      'employeeId': instance.employeeId,
      'employeeName': instance.employeeName,
      'employeePhoto': instance.employeePhoto,
      'drawerAmount': instance.drawerAmount,
      'expenses': instance.expenses.map((e) => e.toJson()).toList(),
      'notes': instance.notes,
      'computerDifferenceType':
          _$ComputerDifferenceTypeEnumMap[instance.computerDifferenceType],
      'computerDifference': instance.computerDifference,
      'electronicWalletAmount': instance.electronicWalletAmount,
      'attachments': instance.attachments,
      'updatedAt': const ServerNullableTimestampConverter().toJson(
        instance.updatedAt,
      ),
      'submittedAt': const ServerTimestampOnNullConverter().toJson(
        instance.submittedAt,
      ),
    };

const _$ShiftTypeEnumMap = {
  ShiftType.midnight: 'midnight',
  ShiftType.morning: 'morning',
  ShiftType.afternoon: 'afternoon',
  ShiftType.evening: 'evening',
};

const _$ComputerDifferenceTypeEnumMap = {
  ComputerDifferenceType.shortage: 'shortage',
  ComputerDifferenceType.excess: 'excess',
  ComputerDifferenceType.none: 'none',
};

ExpenseItem _$ExpenseItemFromJson(Map<String, dynamic> json) => ExpenseItem(
  id: json['id'] as String,
  type: $enumDecode(_$ExpenseTypeEnumMap, json['type']),
  amount: (json['amount'] as num).toDouble(),
  deliveryArea: json['deliveryArea'] as String?,
  companyName: json['companyName'] as String?,
  warehouseName: json['warehouseName'] as String?,
  electronicMethod: $enumDecodeNullable(
    _$ElectronicPaymentMethodEnumMap,
    json['electronicMethod'],
  ),
  administrativeStaff: $enumDecodeNullable(
    _$AdministrativeStaffEnumMap,
    json['administrativeStaff'],
  ),
  governmentType: $enumDecodeNullable(
    _$GovernmentExpenseTypeEnumMap,
    json['governmentType'],
  ),
  other: json['other'] as String?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$ExpenseItemToJson(ExpenseItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ExpenseTypeEnumMap[instance.type]!,
      'deliveryArea': instance.deliveryArea,
      'companyName': instance.companyName,
      'warehouseName': instance.warehouseName,
      'electronicMethod':
          _$ElectronicPaymentMethodEnumMap[instance.electronicMethod],
      'administrativeStaff':
          _$AdministrativeStaffEnumMap[instance.administrativeStaff],
      'governmentType': _$GovernmentExpenseTypeEnumMap[instance.governmentType],
      'other': instance.other,
      'amount': instance.amount,
      'notes': instance.notes,
    };

const _$ExpenseTypeEnumMap = {
  ExpenseType.medicines: 'medicines',
  ExpenseType.delivery: 'delivery',
  ExpenseType.ahmedAboghnima: 'ahmedAboghnima',
  ExpenseType.companyCollection: 'companyCollection',
  ExpenseType.warehouseCollection: 'warehouseCollection',
  ExpenseType.electronicPayment: 'electronicPayment',
  ExpenseType.administrative: 'administrative',
  ExpenseType.accounting: 'accounting',
  ExpenseType.government: 'government',
  ExpenseType.other: 'other',
};

const _$ElectronicPaymentMethodEnumMap = {
  ElectronicPaymentMethod.instapay: 'instapay',
  ElectronicPaymentMethod.wallet: 'wallet',
  ElectronicPaymentMethod.visa: 'visa',
};

const _$AdministrativeStaffEnumMap = {
  AdministrativeStaff.fadyEssam: 'fady_essam',
  AdministrativeStaff.ragyZakaria: 'ragy_zakaria',
  AdministrativeStaff.bolaFahim: 'bola_fahim',
  AdministrativeStaff.emadFawzy: 'emad_fawzy',
};

const _$GovernmentExpenseTypeEnumMap = {
  GovernmentExpenseType.electricity: 'electricity',
  GovernmentExpenseType.water: 'water',
  GovernmentExpenseType.other: 'other',
};
