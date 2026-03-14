abstract class VaultState {}

class VaultInitial extends VaultState {}

class VaultLoading extends VaultState {}

class VaultLoaded extends VaultState {
  final double totalCollected;
  final double totalDeposited;
  final double totalWithdrawn;
  final double balance;
  /// إجمالي الداخل (محصل + إيداع) للشهر الحالي — للبطاقتين فوق
  final double monthlyTotalIn;
  /// إجمالي المسحوب للشهر الحالي — للبطاقتين فوق
  final double monthlyTotalWithdrawn;
  /// Collected from branches (Collect from Reports) — shown in deposit history
  final List<Map<String, dynamic>> collectedEntries;
  final List<Map<String, dynamic>> deposits;
  final List<Map<String, dynamic>> withdrawals;
  /// مدى التاريخ المعروض (null = الكل)
  final DateTime? filterFrom;
  final DateTime? filterTo;
  /// الشهر المعروض لإجماليات البطاقتين (أول يوم من الشهر)
  final DateTime selectedMonth;

  VaultLoaded({
    required this.totalCollected,
    required this.totalDeposited,
    required this.totalWithdrawn,
    required this.balance,
    required this.monthlyTotalIn,
    required this.monthlyTotalWithdrawn,
    required this.collectedEntries,
    required this.deposits,
    required this.withdrawals,
    this.filterFrom,
    this.filterTo,
    required this.selectedMonth,
  });
}

class VaultError extends VaultState {
  final String message;

  VaultError({required this.message});
}

class VaultWithdrawLoading extends VaultState {}
