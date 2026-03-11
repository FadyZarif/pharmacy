import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/vault/logic/vault_cubit.dart';
import 'package:pharmacy/features/vault/logic/vault_state.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<VaultCubit>()..fetchVaultBalance(),
      child: const _VaultView(),
    );
  }
}

/// Deposit items
enum DepositItem { emad, marhal, other }

extension DepositItemExt on DepositItem {
  String get label {
    switch (this) {
      case DepositItem.emad:
        return 'Dr Emad';
      case DepositItem.marhal:
        return 'Carried forward';
      case DepositItem.other:
        return 'Other';
    }
  }
}

/// Withdrawal items
enum WithdrawalItem { deposit, warehouse, company, maintenance, other }

extension WithdrawalItemExt on WithdrawalItem {
  String get label {
    switch (this) {
      case WithdrawalItem.deposit:
        return 'Deposit';
      case WithdrawalItem.warehouse:
        return 'Store claim settlement';
      case WithdrawalItem.company:
        return 'Company claim settlement';
      case WithdrawalItem.maintenance:
        return 'Maintenance';
      case WithdrawalItem.other:
        return 'Other';
    }
  }
}

class _VaultView extends StatelessWidget {
  const _VaultView();

  static final _egp = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManger.primaryBackground,
      appBar: AppBar(
        title: const Text('Bank'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: ColorsManger.primary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocListener<VaultCubit, VaultState>(
        listenWhen: (prev, curr) => curr is VaultError,
        listener: (context, state) {
          if (state is VaultError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: BlocBuilder<VaultCubit, VaultState>(
        builder: (context, state) {
          if (state is VaultLoading ||
              state is VaultInitial ||
              state is VaultWithdrawLoading) {
            return const Center(
              child: CircularProgressIndicator(color: ColorsManger.primary),
            );
          }
          if (state is VaultError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: ColorsManger.error),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.read<VaultCubit>().fetchVaultBalance(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: FilledButton.styleFrom(
                        backgroundColor: ColorsManger.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is VaultWithdrawLoading) {
            return Stack(
              children: [
                _buildContent(context, state as VaultLoaded),
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black26,
                    child: Center(
                      child: CircularProgressIndicator(color: ColorsManger.primary),
                    ),
                  ),
                ),
              ],
            );
          }
          if (state is VaultLoaded) {
            return _buildContent(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, VaultLoaded state) {
    return RefreshIndicator(
      onRefresh: () => context.read<VaultCubit>().fetchVaultBalance(),
      color: ColorsManger.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBalanceCard(state.balance),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddDepositDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Deposit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showAddWithdrawalDialog(context),
                    icon: const Icon(Icons.remove_circle_outline),
                    label: const Text('Withdraw'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorsManger.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSmallCard(
                    'Total In',
                    state.totalCollected + state.totalDeposited,
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSmallCard(
                    'Total Withdrawn',
                    state.totalWithdrawn,
                    Icons.payments,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.add_circle, color: Colors.green, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Deposit History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Collected from branches + manual deposits',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            ..._buildDepositHistoryList(context, state),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.list, color: ColorsManger.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Withdrawal History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.withdrawals.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No withdrawals recorded',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              )
            else
              ...state.withdrawals.map((e) => _buildWithdrawalTile(context, e)),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorsManger.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: ColorsManger.primary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet, color: ColorsManger.primary, size: 28),
              const SizedBox(width: 10),
              Text(
                'Bank Balance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            child: Text(
              _egp.format(balance),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: balance >= 0 ? ColorsManger.primary : ColorsManger.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _egp.format(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Combined list: collected from branches + manual deposits, sorted by date desc
  List<Widget> _buildDepositHistoryList(BuildContext context, VaultLoaded state) {
    final List<Map<String, dynamic>> combined = [];
    for (final e in state.collectedEntries) {
      final date = e['collectedAt'];
      combined.add({
        ...e,
        'type': 'branch',
        '_sortAt': date != null && date is Timestamp ? date.toDate() : DateTime(0),
      });
    }
    for (final e in state.deposits) {
      final date = e['createdAt'];
      combined.add({
        ...e,
        'type': 'manual',
        '_sortAt': date != null && date is Timestamp ? date.toDate() : DateTime(0),
      });
    }
    combined.sort((a, b) => (b['_sortAt'] as DateTime).compareTo(a['_sortAt'] as DateTime));

    if (combined.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No deposits recorded',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ),
      ];
    }
    return combined.map<Widget>((e) {
      if (e['type'] == 'branch') {
        return _buildCollectedEntryTile(e);
      }
      return _buildDepositTile(context, e);
    }).toList();
  }

  Widget _buildCollectedEntryTile(Map<String, dynamic> e) {
    final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
    final branchName = e['branchName'] as String? ?? '—';
    final date = e['collectedAt'];
    String dateStr = '—';
    if (date != null && date is Timestamp) {
      dateStr = DateFormat('yyyy-MM-dd HH:mm').format(date.toDate());
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: ColorsManger.primary.withValues(alpha: 0.2),
              child: Icon(Icons.store, color: ColorsManger.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From: $branchName',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _egp.format(amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _depositTileTitle(Map<String, dynamic> e) {
    final depositItem = e['depositItem'] as String?;
    final description = (e['description'] as String?)?.trim() ?? '';
    if (depositItem == null || depositItem.isEmpty) {
      return description.isNotEmpty ? description : '—';
    }
    switch (depositItem) {
      case 'emad':
        return 'د/ عماد';
      case 'marhal':
        return 'المرحل';
      case 'other':
        return description.isEmpty ? 'أخرى' : 'أخرى: $description';
      default:
        return description.isNotEmpty ? description : depositItem;
    }
  }

  Widget _buildDepositTile(BuildContext context, Map<String, dynamic> e) {
    final id = e['id'] as String? ?? '';
    final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
    final depositItem = e['depositItem'] as String? ?? '';
    final description = e['description'] as String? ?? '';
    final createdAt = e['createdAt'];
    String dateStr = '—';
    if (createdAt != null && createdAt is Timestamp) {
      dateStr = DateFormat('yyyy-MM-dd HH:mm').format(createdAt.toDate());
    }
    final createdByName = e['createdByName'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.withValues(alpha: 0.2),
              child: const Icon(Icons.add_circle, color: Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _depositTileTitle(e),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    softWrap: true,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dateStr ${createdByName.isNotEmpty ? '· $createdByName' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _egp.format(amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showEditDepositDialog(context, id, amount, depositItem, description),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700),
                      onPressed: () => _showDeleteConfirm(context, isDeposit: true, id: id, description: description),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _withdrawalTileTitle(Map<String, dynamic> e) {
    final withdrawalItem = e['withdrawalItem'] as String?;
    final description = (e['description'] as String?)?.trim() ?? '';
    if (withdrawalItem == null || withdrawalItem.isEmpty) {
      return description.isNotEmpty ? description : '—';
    }
    switch (withdrawalItem) {
      case 'deposit':
        return 'ايداع';
      case 'warehouse':
        return 'تسديد مطالبه مخزن';
      case 'company':
        return 'تسديد مطالبه شركه';
      case 'maintenance':
        return 'صيانه';
      case 'other':
        return description.isEmpty ? 'أخرى' : 'أخرى: $description';
      default:
        return description.isNotEmpty ? description : withdrawalItem;
    }
  }

  Widget _buildWithdrawalTile(BuildContext context, Map<String, dynamic> e) {
    final id = e['id'] as String? ?? '';
    final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
    final withdrawalItem = e['withdrawalItem'] as String? ?? '';
    final description = e['description'] as String? ?? '';
    final createdAt = e['createdAt'];
    String dateStr = '—';
    if (createdAt != null && createdAt is Timestamp) {
      dateStr = DateFormat('yyyy-MM-dd HH:mm').format(createdAt.toDate());
    }
    final createdByName = e['createdByName'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.orange.withValues(alpha: 0.2),
              child: const Icon(Icons.payments, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _withdrawalTileTitle(e),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    softWrap: true,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dateStr ${createdByName.isNotEmpty ? '· $createdByName' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _egp.format(amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showEditWithdrawalDialog(context, id, amount, withdrawalItem, description),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700),
                      onPressed: () => _showDeleteConfirm(context, isDeposit: false, id: id, description: _withdrawalTileTitle(e)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(
    BuildContext context, {
    required bool isDeposit,
    required String id,
    required String description,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isDeposit ? 'Delete Deposit' : 'Delete Withdrawal'),
        content: Text(
          'Delete "${description.length > 40 ? '${description.substring(0, 40)}...' : description}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (isDeposit) {
                await context.read<VaultCubit>().deleteDeposit(id);
              } else {
                await context.read<VaultCubit>().deleteWithdrawal(id);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditDepositDialog(
    BuildContext context,
    String id,
    double currentAmount,
    String currentDepositItem,
    String currentDescription,
  ) {
    final cubit = context.read<VaultCubit>();
    final amountController = TextEditingController(text: currentAmount.toString());
    final noteController = TextEditingController(text: currentDescription);
    DepositItem selectedItem = DepositItem.values.firstWhere(
      (e) => e.name == currentDepositItem,
      orElse: () =>
          currentDescription.trim().isNotEmpty ? DepositItem.other : DepositItem.emad,
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('Edit Deposit'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (EGP)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'البند',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...DepositItem.values.map((item) {
                    return RadioListTile<DepositItem>(
                      title: Text(item.label),
                      value: item,
                      groupValue: selectedItem,
                      activeColor: ColorsManger.primary,
                      onChanged: (v) => setState(() => selectedItem = v ?? selectedItem),
                    );
                  }),
                  if (selectedItem == DepositItem.other) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظة (أخرى)',
                        hintText: 'اكتب الملاحظة',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text.replaceFirst(',', '.'));
                  final note = noteController.text.trim();
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Enter a valid amount')),
                    );
                    return;
                  }
                  if (selectedItem == DepositItem.other && note.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('أدخل الملاحظة عند اختيار أخرى')),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  await cubit.updateDeposit(
                    id: id,
                    amount: amount,
                    depositItem: selectedItem.name,
                    description: selectedItem == DepositItem.other ? note : null,
                  );
                },
                style: FilledButton.styleFrom(backgroundColor: ColorsManger.primary),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditWithdrawalDialog(
    BuildContext context,
    String id,
    double currentAmount,
    String currentWithdrawalItem,
    String currentDescription,
  ) {
    final cubit = context.read<VaultCubit>();
    final amountController = TextEditingController(text: currentAmount.toString());
    final noteController = TextEditingController(text: currentDescription);
    WithdrawalItem selectedItem = WithdrawalItem.values.firstWhere(
      (e) => e.name == currentWithdrawalItem,
      orElse: () =>
          currentDescription.trim().isNotEmpty ? WithdrawalItem.other : WithdrawalItem.deposit,
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('Edit Withdrawal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (EGP)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'البند',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...WithdrawalItem.values.map((item) {
                    return RadioListTile<WithdrawalItem>(
                      title: Text(item.label),
                      value: item,
                      groupValue: selectedItem,
                      activeColor: ColorsManger.primary,
                      onChanged: (v) => setState(() => selectedItem = v ?? selectedItem),
                    );
                  }),
                  if (selectedItem == WithdrawalItem.other) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظة (أخرى)',
                        hintText: 'اكتب الملاحظة',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text.replaceFirst(',', '.'));
                  final note = noteController.text.trim();
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Enter a valid amount')),
                    );
                    return;
                  }
                  if (selectedItem == WithdrawalItem.other && note.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('أدخل الملاحظة عند اختيار أخرى')),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  await cubit.updateWithdrawal(
                    id: id,
                    amount: amount,
                    withdrawalItem: selectedItem.name,
                    description: selectedItem == WithdrawalItem.other ? note : null,
                  );
                },
                style: FilledButton.styleFrom(backgroundColor: ColorsManger.primary),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddDepositDialog(BuildContext context) {
    final cubit = context.read<VaultCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DepositItem selectedItem = DepositItem.emad;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('Deposit to Bank'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (EGP)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'البند',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...DepositItem.values.map((item) {
                    return RadioListTile<DepositItem>(
                      title: Text(item.label),
                      value: item,
                      groupValue: selectedItem,
                      activeColor: ColorsManger.primary,
                      onChanged: (v) => setState(() => selectedItem = v ?? selectedItem),
                    );
                  }),
                  if (selectedItem == DepositItem.other) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظة (أخرى)',
                        hintText: 'اكتب الملاحظة',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text.replaceFirst(',', '.'));
                  final note = noteController.text.trim();
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Enter a valid amount')),
                    );
                    return;
                  }
                  if (selectedItem == DepositItem.other && note.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('أدخل الملاحظة عند اختيار أخرى')),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  await cubit.addDeposit(
                    amount: amount,
                    depositItem: selectedItem.name,
                    description: selectedItem == DepositItem.other ? note : null,
                  );
                  final newState = cubit.state;
                  if (newState is! VaultError && newState is VaultLoaded) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Deposit added'), backgroundColor: Colors.green),
                    );
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: ColorsManger.primary),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddWithdrawalDialog(BuildContext context) {
    final cubit = context.read<VaultCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    WithdrawalItem selectedItem = WithdrawalItem.deposit;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('Withdraw from Bank'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (EGP)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'البند',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...WithdrawalItem.values.map((item) {
                    return RadioListTile<WithdrawalItem>(
                      title: Text(item.label),
                      value: item,
                      groupValue: selectedItem,
                      activeColor: ColorsManger.primary,
                      onChanged: (v) => setState(() => selectedItem = v ?? selectedItem),
                    );
                  }),
                  if (selectedItem == WithdrawalItem.other) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظة (أخرى)',
                        hintText: 'اكتب الملاحظة',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text.replaceFirst(',', '.'));
                  final note = noteController.text.trim();
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Enter a valid amount')),
                    );
                    return;
                  }
                  if (selectedItem == WithdrawalItem.other && note.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('أدخل الملاحظة عند اختيار أخرى')),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  await cubit.addWithdrawal(
                    amount: amount,
                    withdrawalItem: selectedItem.name,
                    description: selectedItem == WithdrawalItem.other ? note : null,
                  );
                  final newState = cubit.state;
                  if (newState is! VaultError && newState is VaultLoaded) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Withdrawal added'), backgroundColor: Colors.green),
                    );
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: ColorsManger.primary),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
