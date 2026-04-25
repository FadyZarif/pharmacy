import 'package:cloud_firestore/cloud_firestore.dart';

/// One employee row from the quarterly incentives Excel (sheet row mapped to fields).
class EmployeeQuarterlyIncentiveModel {
  final String employeeUid;
  final String pharmacyCode;
  final String pharmacyName;
  final String acc;
  final String nameEnglish;
  final String nameArabic;
  final String basicSalary;
  final String monthlyIncentive;
  final String bonuses;
  final String adminIncentive;
  final String eideya;
  final String quarterlyShiftDeficitDeduction;
  final String lineTotal;
  final String listIncentive;
  final String restIncrease;
  final String creditExchange;
  final String cashExchange;
  final String totalExchange;
  final String rate02;
  final String expiryAmount;
  final String expiry25Percent;
  final String quantityAdjustments;
  final String inventoryIncreaseCode;
  final String inventoryFinalValue;
  final String deficitCarryover;
  final String branchAdjustment;
  final String totalPlusMinus;
  final String branchEmployeeCount;
  final String perCapitaShare;
  final String netDue;
  final String notes;

  EmployeeQuarterlyIncentiveModel({
    required this.employeeUid,
    required this.pharmacyCode,
    required this.pharmacyName,
    required this.acc,
    required this.nameEnglish,
    required this.nameArabic,
    required this.basicSalary,
    required this.monthlyIncentive,
    required this.bonuses,
    required this.adminIncentive,
    required this.eideya,
    required this.quarterlyShiftDeficitDeduction,
    required this.lineTotal,
    required this.listIncentive,
    required this.restIncrease,
    required this.creditExchange,
    required this.cashExchange,
    required this.totalExchange,
    required this.rate02,
    required this.expiryAmount,
    required this.expiry25Percent,
    required this.quantityAdjustments,
    required this.inventoryIncreaseCode,
    required this.inventoryFinalValue,
    required this.deficitCarryover,
    required this.branchAdjustment,
    required this.totalPlusMinus,
    required this.branchEmployeeCount,
    required this.perCapitaShare,
    required this.netDue,
    required this.notes,
  });

  factory EmployeeQuarterlyIncentiveModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? <String, dynamic>{};
    String s(String key) => (d[key] as String?) ?? '';
    return EmployeeQuarterlyIncentiveModel(
      employeeUid: doc.id,
      pharmacyCode: s('pharmacyCode'),
      pharmacyName: s('pharmacyName'),
      acc: s('acc'),
      nameEnglish: s('nameEnglish'),
      nameArabic: s('nameArabic'),
      basicSalary: s('basicSalary'),
      monthlyIncentive: s('monthlyIncentive'),
      bonuses: s('bonuses'),
      adminIncentive: s('adminIncentive'),
      eideya: s('eideya'),
      quarterlyShiftDeficitDeduction: s('quarterlyShiftDeficitDeduction'),
      lineTotal: s('lineTotal'),
      listIncentive: s('listIncentive'),
      restIncrease: s('restIncrease'),
      creditExchange: s('creditExchange'),
      cashExchange: s('cashExchange'),
      totalExchange: s('totalExchange'),
      rate02: s('rate02'),
      expiryAmount: s('expiryAmount'),
      expiry25Percent: s('expiry25Percent'),
      quantityAdjustments: s('quantityAdjustments'),
      inventoryIncreaseCode: s('inventoryIncreaseCode'),
      inventoryFinalValue: s('inventoryFinalValue'),
      deficitCarryover: s('deficitCarryover'),
      branchAdjustment: s('branchAdjustment'),
      totalPlusMinus: s('totalPlusMinus'),
      branchEmployeeCount: s('branchEmployeeCount'),
      perCapitaShare: s('perCapitaShare'),
      netDue: s('netDue'),
      notes: s('notes'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeUid': employeeUid,
      'pharmacyCode': pharmacyCode,
      'pharmacyName': pharmacyName,
      'acc': acc,
      'nameEnglish': nameEnglish,
      'nameArabic': nameArabic,
      'basicSalary': basicSalary,
      'monthlyIncentive': monthlyIncentive,
      'bonuses': bonuses,
      'adminIncentive': adminIncentive,
      'eideya': eideya,
      'quarterlyShiftDeficitDeduction': quarterlyShiftDeficitDeduction,
      'lineTotal': lineTotal,
      'listIncentive': listIncentive,
      'restIncrease': restIncrease,
      'creditExchange': creditExchange,
      'cashExchange': cashExchange,
      'totalExchange': totalExchange,
      'rate02': rate02,
      'expiryAmount': expiryAmount,
      'expiry25Percent': expiry25Percent,
      'quantityAdjustments': quantityAdjustments,
      'inventoryIncreaseCode': inventoryIncreaseCode,
      'inventoryFinalValue': inventoryFinalValue,
      'deficitCarryover': deficitCarryover,
      'branchAdjustment': branchAdjustment,
      'totalPlusMinus': totalPlusMinus,
      'branchEmployeeCount': branchEmployeeCount,
      'perCapitaShare': perCapitaShare,
      'netDue': netDue,
      'notes': notes,
    };
  }
}
