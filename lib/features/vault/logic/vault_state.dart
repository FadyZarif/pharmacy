abstract class VaultState {}

class VaultInitial extends VaultState {}

class VaultLoading extends VaultState {}

class VaultLoaded extends VaultState {
  final double totalCollected;
  final double totalDeposited;
  final double totalWithdrawn;
  final double balance;
  /// Collected from branches (Collect from Reports) — shown in deposit history
  final List<Map<String, dynamic>> collectedEntries;
  final List<Map<String, dynamic>> deposits;
  final List<Map<String, dynamic>> withdrawals;

  VaultLoaded({
    required this.totalCollected,
    required this.totalDeposited,
    required this.totalWithdrawn,
    required this.balance,
    required this.collectedEntries,
    required this.deposits,
    required this.withdrawals,
  });
}

class VaultError extends VaultState {
  final String message;

  VaultError({required this.message});
}

class VaultWithdrawLoading extends VaultState {}
