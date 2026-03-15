import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/vault/logic/vault_cubit.dart';
import 'package:pharmacy/features/vault/logic/vault_state.dart';
import 'package:url_launcher/url_launcher.dart';

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
            _buildMonthSelectorRow(context, state),
            const SizedBox(height: 16),
            _buildDateFilterRow(context, state),
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
                    _monthCardLabel(state.selectedMonth, 'Total In'),
                    state.monthlyTotalIn,
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSmallCard(
                    _monthCardLabel(state.selectedMonth, 'Total Withdrawn'),
                    state.monthlyTotalWithdrawn,
                    Icons.payments,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.history, color: ColorsManger.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Transaction History',
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
              'All deposits and withdrawals by time',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            ..._buildCombinedHistoryList(context, state),
          ],
        ),
      ),
    );
  }

  String _monthCardLabel(DateTime selectedMonth, String prefix) {
    final now = DateTime.now();
    if (selectedMonth.year == now.year && selectedMonth.month == now.month) {
      return '$prefix (this month)';
    }
    return '$prefix (${DateFormat('MMM yyyy').format(selectedMonth)})';
  }

  Widget _buildMonthSelectorRow(BuildContext context, VaultLoaded state) {
    final cubit = context.read<VaultCubit>();
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final isCurrentMonth = state.selectedMonth.year == currentMonth.year &&
        state.selectedMonth.month == currentMonth.month;
    final prevMonth = DateTime(state.selectedMonth.year, state.selectedMonth.month - 1, 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'View month',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            IconButton(
              onPressed: () => cubit.setSelectedMonth(prevMonth),
              icon: const Icon(Icons.chevron_left),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: ColorsManger.primary.withValues(alpha: 0.3)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ColorsManger.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  DateFormat('MMMM yyyy').format(state.selectedMonth),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                final nextMonth = DateTime(state.selectedMonth.year, state.selectedMonth.month + 1, 1);
                final canGoNext = nextMonth.year < now.year ||
                    (nextMonth.year == now.year && nextMonth.month <= now.month);
                if (canGoNext) cubit.setSelectedMonth(nextMonth);
              },
              icon: const Icon(Icons.chevron_right),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: ColorsManger.primary.withValues(alpha: 0.3)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (!isCurrentMonth)
              TextButton(
                onPressed: () => cubit.setSelectedMonth(currentMonth),
                child: const Text('This month'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateFilterRow(BuildContext context, VaultLoaded state) {
    final cubit = context.read<VaultCubit>();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final hasFilter = state.filterFrom != null && state.filterTo != null;
    bool isToday = false;
    bool isYesterday = false;
    bool isCustomRange = false;
    if (hasFilter && state.filterFrom != null && state.filterTo != null) {
      isToday = state.filterFrom!.year == now.year &&
          state.filterFrom!.month == now.month &&
          state.filterFrom!.day == now.day &&
          state.filterTo!.year == now.year &&
          state.filterTo!.month == now.month &&
          state.filterTo!.day == now.day;
      isYesterday = state.filterFrom!.year == yesterdayStart.year &&
          state.filterFrom!.month == yesterdayStart.month &&
          state.filterFrom!.day == yesterdayStart.day;
      isCustomRange = hasFilter && !isToday && !isYesterday;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Show transactions',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _filterChip(context, 'Today', () {
              cubit.setDateFilter(todayStart, now);
            }, isToday),
            _filterChip(context, 'Yesterday', () {
              cubit.setDateFilter(yesterdayStart, yesterdayStart.add(const Duration(hours: 23, minutes: 59, seconds: 59)));
            }, isYesterday),
            _filterChip(context, 'From – To', () {
              _showCustomDateRangeDialog(context, cubit);
            }, isCustomRange),
            _filterChip(context, 'All', () {
              cubit.setDateFilter(null, null);
            }, !hasFilter),
          ],
        ),
      ],
    );
  }

  Future<void> _showCustomDateRangeDialog(BuildContext context, VaultCubit cubit) async {
    DateTime from = DateTime.now().subtract(const Duration(days: 30));
    DateTime to = DateTime.now();
    final picked = await showDialog<({DateTime from, DateTime to})>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('From – To'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    title: Text('From: ${DateFormat('d MMM yyyy').format(from)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: from,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => from = DateTime(d.year, d.month, d.day));
                    },
                  ),
                  ListTile(
                    title: Text('To: ${DateFormat('d MMM yyyy').format(to)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: to,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => to = DateTime(d.year, d.month, d.day, 23, 59, 59));
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (from.isAfter(to)) {
                      final t = to;
                      to = from;
                      from = t;
                    }
                    Navigator.pop(ctx, (from: from, to: to));
                  },
                  style: FilledButton.styleFrom(backgroundColor: ColorsManger.primary),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
    if (picked != null && context.mounted) {
      final fromDay = DateTime(picked.from.year, picked.from.month, picked.from.day);
      final toDay = DateTime(picked.to.year, picked.to.month, picked.to.day);
      final toEnd = DateTime(picked.to.year, picked.to.month, picked.to.day, 23, 59, 59);
      if (fromDay.isAfter(toDay)) {
        cubit.setDateFilter(toDay, DateTime(picked.from.year, picked.from.month, picked.from.day, 23, 59, 59));
      } else {
        cubit.setDateFilter(fromDay, toEnd);
      }
    }
  }

  Widget _filterChip(BuildContext context, String label, VoidCallback onTap, bool selected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: ColorsManger.primary.withValues(alpha: 0.3),
      checkmarkColor: ColorsManger.primary,
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

  /// For a given date key (yyyy-MM-dd), returns total deposit and total withdrawal that day.
  ({double deposit, double withdraw}) _dayTotals(String dateKey, VaultLoaded state) {
    double dep = 0;
    for (final e in state.collectedEntries) {
      final date = e['collectedAt'];
      final dt = date != null && date is Timestamp ? date.toDate() : null;
      if (dt != null && DateFormat('yyyy-MM-dd').format(dt) == dateKey) {
        dep += (e['amount'] as num?)?.toDouble() ?? 0.0;
      }
    }
    for (final e in state.deposits) {
      final date = e['createdAt'];
      final dt = date != null && date is Timestamp ? date.toDate() : null;
      if (dt != null && DateFormat('yyyy-MM-dd').format(dt) == dateKey) {
        dep += (e['amount'] as num?)?.toDouble() ?? 0.0;
      }
    }
    double wit = 0;
    for (final e in state.withdrawals) {
      final date = e['createdAt'];
      final dt = date != null && date is Timestamp ? date.toDate() : null;
      if (dt != null && DateFormat('yyyy-MM-dd').format(dt) == dateKey) {
        wit += (e['amount'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return (deposit: dep, withdraw: wit);
  }

  Widget _buildDaySummaryRow(String dateKey, VaultLoaded state) {
    final t = _dayTotals(dateKey, state);
    final remaining = t.deposit - t.withdraw;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildDaySummaryBox(
              'Deposit',
              t.deposit,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildDaySummaryBox(
              'Withdrew',
              t.withdraw,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildDaySummaryBox(
              'Remaining',
              remaining,
              remaining >= 0 ? ColorsManger.primary : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySummaryBox(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _egp.format(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// One list: all transactions (collected + deposits + withdrawals) sorted by time, grouped by day
  List<Widget> _buildCombinedHistoryList(BuildContext context, VaultLoaded state) {
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
    for (final e in state.withdrawals) {
      final date = e['createdAt'];
      combined.add({
        ...e,
        'type': 'withdrawal',
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
                'No transactions recorded',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ),
      ];
    }
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final e in combined) {
      final dt = e['_sortAt'] as DateTime;
      final key = DateFormat('yyyy-MM-dd').format(dt);
      grouped.putIfAbsent(key, () => []).add(e);
    }
    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final list = <Widget>[];
    for (final key in keys) {
      final date = DateTime.tryParse(key);
      final dayItems = grouped[key]!;
      // Within each day: deposits first (branch, manual), then withdrawals; within each group newest first
      dayItems.sort((a, b) {
        final aDeposit = a['type'] != 'withdrawal';
        final bDeposit = b['type'] != 'withdrawal';
        if (aDeposit != bDeposit) return aDeposit ? -1 : 1;
        return (b['_sortAt'] as DateTime).compareTo(a['_sortAt'] as DateTime);
      });
      list.add(
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            date != null ? DateFormat('EEEE, d MMM yyyy').format(date) : key,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
      );
      list.add(_buildDaySummaryRow(key, state));
      for (final e in dayItems) {
        if (e['type'] == 'branch') {
          list.add(_buildCollectedEntryTile(e));
        } else if (e['type'] == 'manual') {
          list.add(_buildDepositTile(context, e));
        } else {
          list.add(_buildWithdrawalTile(context, e));
        }
      }
    }
    return list;
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

  String _vaultContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
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
    final comment = (e['comment'] as String?)?.trim() ?? '';
    final attachmentUrl = e['attachmentUrl'] as String? ?? '';

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
                  if (comment.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      comment,
                      style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                      softWrap: true,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (attachmentUrl.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final uri = Uri.parse(attachmentUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.attach_file, size: 16, color: ColorsManger.primary),
                          SizedBox(width: 4),
                          Text(
                            'View attachment',
                            style: TextStyle(
                              fontSize: 12,
                              color: ColorsManger.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 100),
              child: Column(
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
                      _buildActionIcon(
                        icon: Icons.edit_outlined,
                        color: ColorsManger.primary,
                        onTap: () => _showEditDepositDialog(context, id, amount, depositItem, description),
                      ),
                      const SizedBox(width: 4),
                      _buildActionIcon(
                        icon: Icons.delete_outline,
                        color: const Color(0xFFC62828),
                        onTap: () => _showDeleteConfirm(context, isDeposit: true, id: id, description: description),
                        webLabel: kIsWeb ? 'حذف' : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? webLabel,
  }) {
    if (kIsWeb && webLabel != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text(
              webLabel,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ),
      );
    }
    if (kIsWeb) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 24, color: color),
          ),
        ),
      );
    }
    return IconButton(
      icon: Icon(icon, size: 22, color: color),
      onPressed: onTap,
      style: IconButton.styleFrom(
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
        foregroundColor: color,
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
    final comment = (e['comment'] as String?)?.trim() ?? '';
    final attachmentUrl = e['attachmentUrl'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE65100).withValues(alpha: 0.25),
              radius: 22,
              child: kIsWeb
                  ? Text(
                      '−',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFFE65100),
                        height: 1.1,
                      ),
                    )
                  : Icon(
                      Icons.remove_circle_outline,
                      size: 26,
                      color: Colors.orange[800],
                    ),
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
                  if (comment.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      comment,
                      style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                      softWrap: true,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (attachmentUrl.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final uri = Uri.parse(attachmentUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.attach_file, size: 16, color: ColorsManger.primary),
                          SizedBox(width: 4),
                          Text(
                            'View attachment',
                            style: TextStyle(
                              fontSize: 12,
                              color: ColorsManger.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 100),
              child: Column(
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
                      _buildActionIcon(
                        icon: Icons.edit_outlined,
                        color: ColorsManger.primary,
                        onTap: () => _showEditWithdrawalDialog(context, id, amount, withdrawalItem, description),
                      ),
                      const SizedBox(width: 4),
                      _buildActionIcon(
                        icon: Icons.delete_outline,
                        color: const Color(0xFFC62828),
                        onTap: () => _showDeleteConfirm(context, isDeposit: false, id: id, description: _withdrawalTileTitle(e)),
                        webLabel: kIsWeb ? 'حذف' : null,
                      ),
                    ],
                  ),
                ],
              ),
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
    final commentController = TextEditingController();
    String? attachmentUrl;
    String? attachmentName;
    bool isUploading = false;

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
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Comment',
                      hintText: 'Optional comment',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.attach_file),
                          label: Text(
                            attachmentName == null ? 'Add attachment' : 'Change attachment',
                          ),
                          onPressed: isUploading
                              ? null
                              : () async {
                                  setState(() => isUploading = true);
                                  final result = await FilePicker.platform.pickFiles(
                                    withData: true,
                                    allowMultiple: false,
                                    type: FileType.custom,
                                    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                                  );
                                  if (result != null && result.files.isNotEmpty) {
                                    final file = result.files.first;
                                    final bytes = file.bytes;
                                    if (bytes == null) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(content: Text('Failed to read file bytes')),
                                      );
                                    } else {
                                      try {
                                        final ext = (file.extension ?? 'bin').toLowerCase();
                                        final ts = DateTime.now().millisecondsSinceEpoch;
                                        final ref = FirebaseStorage.instance.ref().child(
                                          'vault/deposits/${currentUser.uid}_$ts.$ext',
                                        );
                                        final metadata = SettableMetadata(
                                          contentType: _vaultContentType(ext),
                                        );
                                        final uploadTask = await ref.putData(bytes, metadata);
                                        final url = await uploadTask.ref.getDownloadURL();
                                        setState(() {
                                          attachmentUrl = url;
                                          attachmentName = file.name;
                                        });
                                      } catch (e) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(content: Text('Upload failed: $e')),
                                        );
                                      }
                                    }
                                  }
                                  setState(() => isUploading = false);
                                },
                        ),
                      ),
                    ],
                  ),
                  if (attachmentName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      attachmentName!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
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
                  final comment = commentController.text.trim();
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
                    comment: comment.isEmpty ? null : comment,
                    attachmentUrl: attachmentUrl,
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
    final commentController = TextEditingController();
    String? attachmentUrl;
    String? attachmentName;
    bool isUploading = false;

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
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Comment',
                      hintText: 'Optional comment',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.attach_file),
                          label: Text(
                            attachmentName == null ? 'Add attachment' : 'Change attachment',
                          ),
                          onPressed: isUploading
                              ? null
                              : () async {
                                  setState(() => isUploading = true);
                                  final result = await FilePicker.platform.pickFiles(
                                    withData: true,
                                    allowMultiple: false,
                                    type: FileType.custom,
                                    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                                  );
                                  if (result != null && result.files.isNotEmpty) {
                                    final file = result.files.first;
                                    final bytes = file.bytes;
                                    if (bytes == null) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(content: Text('Failed to read file bytes')),
                                      );
                                    } else {
                                      try {
                                        final ext = (file.extension ?? 'bin').toLowerCase();
                                        final ts = DateTime.now().millisecondsSinceEpoch;
                                        final ref = FirebaseStorage.instance.ref().child(
                                          'vault/withdrawals/${currentUser.uid}_$ts.$ext',
                                        );
                                        final metadata = SettableMetadata(
                                          contentType: _vaultContentType(ext),
                                        );
                                        final uploadTask = await ref.putData(bytes, metadata);
                                        final url = await uploadTask.ref.getDownloadURL();
                                        setState(() {
                                          attachmentUrl = url;
                                          attachmentName = file.name;
                                        });
                                      } catch (e) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(content: Text('Upload failed: $e')),
                                        );
                                      }
                                    }
                                  }
                                  setState(() => isUploading = false);
                                },
                        ),
                      ),
                    ],
                  ),
                  if (attachmentName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      attachmentName!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
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
                  final comment = commentController.text.trim();
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
                    comment: comment.isEmpty ? null : comment,
                    attachmentUrl: attachmentUrl,
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
