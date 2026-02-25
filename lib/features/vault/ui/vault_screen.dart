import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/vault/logic/vault_cubit.dart';
import 'package:pharmacy/features/vault/logic/vault_state.dart';

/// Positions FAB above the bottom navigation bar (avoid overlap).
class _FabAboveNavLocation extends FloatingActionButtonLocation {
  const _FabAboveNavLocation();

  static const double _bottomOffset = 90;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    const double end = 16;
    final double bottom = 16 + _bottomOffset;
    return Offset(
      geometry.scaffoldSize.width - geometry.floatingActionButtonSize.width - end,
      geometry.scaffoldSize.height - geometry.floatingActionButtonSize.height - bottom,
    );
  }
}

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
      body: BlocBuilder<VaultCubit, VaultState>(
        builder: (context, state) {
          if (state is VaultLoading || state is VaultInitial) {
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
      floatingActionButton: BlocBuilder<VaultCubit, VaultState>(
        buildWhen: (p, c) => c is! VaultWithdrawLoading,
        builder: (context, state) {
          if (state is! VaultLoaded) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _showAddWithdrawalDialog(context),
            backgroundColor: ColorsManger.primary,
            icon: const Icon(Icons.remove_circle_outline),
            label: const Text('Withdraw'),
          );
        },
      ),
      floatingActionButtonLocation: const _FabAboveNavLocation(),
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
                  child: _buildSmallCard(
                    'Total Collected',
                    state.totalCollected,
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
              ...state.withdrawals.map((e) => _buildWithdrawalTile(e)),
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
              Icon(Icons.account_balance, color: ColorsManger.primary, size: 28),
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

  Widget _buildWithdrawalTile(Map<String, dynamic> e) {
    final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
    final description = e['description'] as String? ?? '—';
    final createdAt = e['createdAt'];
    String dateStr = '—';
    if (createdAt != null && createdAt is Timestamp) {
      dateStr = DateFormat('yyyy-MM-dd HH:mm').format(createdAt.toDate());
    }
    final createdByName = e['createdByName'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withValues(alpha: 0.2),
          child: const Icon(Icons.payments, color: Colors.orange),
        ),
        title: Text(
          description,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('$dateStr ${createdByName.isNotEmpty ? '· $createdByName' : ''}'),
        trailing: Text(
          _egp.format(amount),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      ),
    );
  }

  void _showAddWithdrawalDialog(BuildContext context) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw from Bank'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
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
              final description = descriptionController.text.trim();
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Enter a valid amount')),
                );
                return;
              }
              if (description.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Enter description')),
                );
                return;
              }
              Navigator.pop(ctx);
              await context.read<VaultCubit>().addWithdrawal(
                    amount: amount,
                    description: description,
                  );
            },
            style: FilledButton.styleFrom(backgroundColor: ColorsManger.primary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
