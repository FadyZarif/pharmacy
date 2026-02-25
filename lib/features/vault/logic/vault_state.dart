abstract class VaultState {}

class VaultInitial extends VaultState {}

class VaultLoading extends VaultState {}

class VaultLoaded extends VaultState {
  final double totalCollected;
  final double totalWithdrawn;
  final double balance;
  final List<Map<String, dynamic>> withdrawals;

  VaultLoaded({
    required this.totalCollected,
    required this.totalWithdrawn,
    required this.balance,
    required this.withdrawals,
  });
}

class VaultError extends VaultState {
  final String message;

  VaultError({required this.message});
}

class VaultWithdrawLoading extends VaultState {}
