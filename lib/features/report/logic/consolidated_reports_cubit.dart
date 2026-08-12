import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/features/report/data/helpers/report_firestore_helper.dart';
import 'package:pharmacy/features/report/data/models/daily_report_model.dart';
import 'package:pharmacy/features/report/logic/consolidated_reports_state.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';

class ConsolidatedReportsCubit extends Cubit<ConsolidatedReportsState> {
  ConsolidatedReportsCubit() : super(ConsolidatedReportsInitial());

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// جلب ملخص يومي لجميع الفروع
  Future<void> fetchDailyConsolidatedReports(
    List<Branch> branches,
    DateTime selectedDate,
  ) async {
    emit(ConsolidatedReportsInitial());

    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);

      // Show initial loading
      emit(ConsolidatedReportsLoading(
        currentBranchName: 'Starting...',
        completedBranches: 0,
        totalBranches: branches.length,
      ));

      // Track completed branches
      int completedCount = 0;
      final results = <Map<String, dynamic>?>[];

      // Fetch branches with progress updates
      for (var branch in branches) {
        emit(ConsolidatedReportsLoading(
          currentBranchName: branch.name,
          completedBranches: completedCount,
          totalBranches: branches.length,
        ));

        final result = await _fetchBranchDailyData(branch, dateKey, selectedDate);
        results.add(result);
        completedCount++;
      }

      // Aggregate results
      double totalSales = 0.0;
      double totalExpenses = 0.0;
      double totalMedicinesExpenses = 0.0;
      double totalElectronicPaymentExpenses = 0.0;
      double vaultAmount = 0.0;
      double totalSurplus = 0.0;
      double totalDeficit = 0.0;
      List<ExpenseItem> allExpenses = [];
      Map<String, BranchSummary> branchSummaries = {};
      final branchElectronicBreakdowns = <String, BranchElectronicBreakdown>{};
      final branchDeliveryTotals = <String, double>{};

      for (var result in results) {
        if (result != null) {
          totalSales += result['sales'] as double;
          totalExpenses += result['expenses'] as double;
          totalMedicinesExpenses += result['medicinesExpenses'] as double;
          totalElectronicPaymentExpenses += result['electronicPaymentExpenses'] as double;
          vaultAmount += result['vaultAmount'] as double;
          totalSurplus += result['surplus'] as double;
          totalDeficit += result['deficit'] as double;
          allExpenses.addAll(result['allExpenses'] as List<ExpenseItem>);
          final branchElectronicBreakdown =
              result['branchElectronicBreakdown'] as BranchElectronicBreakdown?;
          if (branchElectronicBreakdown != null) {
            branchElectronicBreakdowns[branchElectronicBreakdown.branchId] =
                branchElectronicBreakdown;
          }
          final deliveryTotal = (result['deliveryExpenses'] as double?) ?? 0.0;
          final branchId = (result['branchId'] as String?) ?? '';
          if (branchId.isNotEmpty) {
            branchDeliveryTotals[branchId] = deliveryTotal;
          }

          final summary = result['summary'] as BranchSummary;
          branchSummaries[summary.branchId] = summary;
        }
      }

      final netProfit = totalSales - totalExpenses;
      final electronicBreakdown = _computeElectronicBreakdown(allExpenses);
      final totalDeliveryExpenses = _sumExpensesByType(
        allExpenses,
        ExpenseType.delivery,
      );

      emit(ConsolidatedReportsLoaded(
        totalSales: totalSales,
        totalExpenses: totalExpenses,
        netProfit: netProfit,
        totalMedicinesExpenses: totalMedicinesExpenses,
        totalMedicinesWithInvoicesExpenses: _sumExpensesByType(
          allExpenses,
          ExpenseType.medicinesWithInvoices,
        ),
        totalElectronicPaymentExpenses: totalElectronicPaymentExpenses,
        totalInstapayExpenses: electronicBreakdown.instapay,
        totalWalletExpenses: electronicBreakdown.wallet,
        totalVisaExpenses: electronicBreakdown.visa,
        totalDeliveryExpenses: totalDeliveryExpenses,
        branchDeliveryTotals: branchDeliveryTotals,
        branchElectronicBreakdowns: branchElectronicBreakdowns,
        vaultAmount: vaultAmount,
        totalSurplus: totalSurplus,
        totalDeficit: totalDeficit,
        allExpenses: allExpenses,
        branchSummaries: branchSummaries,
        monthlyTarget: null, // Daily reports don't have targets
        branchMonthlyTargets: const {},
        totalPurchases: 0.0,
        branchMonthlyPurchases: const {},
      ));
    } catch (e) {
      emit(ConsolidatedReportsError(message: e.toString()));
    }
  }

  /// جلب ملخص شهري لجميع الفروع
  Future<void> fetchMonthlyConsolidatedReports(
    List<Branch> branches,
    DateTime selectedDate,
  ) async {
    emit(ConsolidatedReportsInitial());

    try {
      final lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0);

      // Show initial loading
      emit(ConsolidatedReportsLoading(
        currentBranchName: 'Starting...',
        completedBranches: 0,
        totalBranches: branches.length,
      ));

      // Track completed branches
      int completedCount = 0;
      final results = <Map<String, dynamic>?>[];

      // Fetch branches with progress updates
      for (var branch in branches) {
        emit(ConsolidatedReportsLoading(
          currentBranchName: branch.name,
          completedBranches: completedCount,
          totalBranches: branches.length,
        ));

        final result = await _fetchBranchMonthlyData(branch, selectedDate, lastDay);
        results.add(result);
        completedCount++;
      }

      // Aggregate results
      double totalSales = 0.0;
      double totalExpenses = 0.0;
      double totalMedicinesExpenses = 0.0;
      double totalElectronicPaymentExpenses = 0.0;
      double vaultAmount = 0.0;
      double totalSurplus = 0.0;
      double totalDeficit = 0.0;
      List<ExpenseItem> allExpenses = [];
      Map<String, BranchSummary> branchSummaries = {};
      final branchElectronicBreakdowns = <String, BranchElectronicBreakdown>{};
      final branchDeliveryTotals = <String, double>{};

      for (var result in results) {
        if (result != null) {
          totalSales += result['sales'] as double;
          totalExpenses += result['expenses'] as double;
          totalMedicinesExpenses += result['medicinesExpenses'] as double;
          totalElectronicPaymentExpenses += result['electronicPaymentExpenses'] as double;
          vaultAmount += result['vaultAmount'] as double;
          totalSurplus += result['surplus'] as double;
          totalDeficit += result['deficit'] as double;
          allExpenses.addAll(result['allExpenses'] as List<ExpenseItem>);
          final branchElectronicBreakdown =
              result['branchElectronicBreakdown'] as BranchElectronicBreakdown?;
          if (branchElectronicBreakdown != null) {
            branchElectronicBreakdowns[branchElectronicBreakdown.branchId] =
                branchElectronicBreakdown;
          }
          final deliveryTotal = (result['deliveryExpenses'] as double?) ?? 0.0;
          final branchId = (result['branchId'] as String?) ?? '';
          if (branchId.isNotEmpty) {
            branchDeliveryTotals[branchId] = deliveryTotal;
          }

          final summary = result['summary'] as BranchSummary;
          branchSummaries[summary.branchId] = summary;
        }
      }

      final netProfit = totalSales - totalExpenses;
      final electronicBreakdown = _computeElectronicBreakdown(allExpenses);
      final totalDeliveryExpenses = _sumExpensesByType(
        allExpenses,
        ExpenseType.delivery,
      );

      // جلب الهدف الشهري الموحد (مجموع أهداف كل الفروع)
      double? monthlyTarget;
      final branchMonthlyTargets = <String, double>{};
      final branchMonthlyPurchases = <String, double>{};
      double totalPurchases = 0.0;
      try {
        final monthKey = DateFormat('yyyy-MM').format(selectedDate);
        double totalTargets = 0.0;
        int branchesWithTargets = 0;

        for (var branch in branches) {
          try {
            final targetDoc = await _db
                .collection('branches')
                .doc(branch.id)
                .collection('monthly_target')
                .doc(monthKey)
                .get();

            if (targetDoc.exists) {
              final branchTarget = (targetDoc.data()?['monthlyTarget'] as num?)?.toDouble();
              if (branchTarget != null) {
                totalTargets += branchTarget;
                branchesWithTargets++;
                branchMonthlyTargets[branch.id] = branchTarget;
              }
            }
          } catch (e) {
            continue;
          }
        }

        if (branchesWithTargets > 0) {
          monthlyTarget = totalTargets;
        }

        // إجمالي مشتريات كل الفروع لنفس الشهر
        final branchIds = branches.map((b) => b.id).toSet();
        if (branchIds.isNotEmpty) {
          final purchasesSnapshot = await _db
              .collection('branch_purchases')
              .where('monthKey', isEqualTo: monthKey)
              .get();
          for (final doc in purchasesSnapshot.docs) {
            final data = doc.data();
            final bid = data['branchId'] as String?;
            if (bid != null && branchIds.contains(bid)) {
              final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
              totalPurchases += amount;
              branchMonthlyPurchases[bid] =
                  (branchMonthlyPurchases[bid] ?? 0.0) + amount;
            }
          }
        }
      } catch (e) {
        print('Error fetching monthly targets: $e');
      }

      emit(ConsolidatedReportsLoaded(
        totalSales: totalSales,
        totalExpenses: totalExpenses,
        netProfit: netProfit,
        totalMedicinesExpenses: totalMedicinesExpenses,
        totalMedicinesWithInvoicesExpenses: _sumExpensesByType(
          allExpenses,
          ExpenseType.medicinesWithInvoices,
        ),
        totalElectronicPaymentExpenses: totalElectronicPaymentExpenses,
        totalInstapayExpenses: electronicBreakdown.instapay,
        totalWalletExpenses: electronicBreakdown.wallet,
        totalVisaExpenses: electronicBreakdown.visa,
        totalDeliveryExpenses: totalDeliveryExpenses,
        branchDeliveryTotals: branchDeliveryTotals,
        branchElectronicBreakdowns: branchElectronicBreakdowns,
        vaultAmount: vaultAmount,
        totalSurplus: totalSurplus,
        totalDeficit: totalDeficit,
        allExpenses: allExpenses,
        branchSummaries: branchSummaries,
        monthlyTarget: monthlyTarget,
        branchMonthlyTargets: branchMonthlyTargets,
        totalPurchases: totalPurchases,
        branchMonthlyPurchases: branchMonthlyPurchases,
      ));
    } catch (e) {
      emit(ConsolidatedReportsError(message: e.toString()));
    }
  }

  /// جلب ملخص مخصص لجميع الفروع بين تاريخين (شاملين)
  Future<void> fetchRangeConsolidatedReports(
    List<Branch> branches,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    emit(ConsolidatedReportsInitial());

    try {
      final start = DateTime(fromDate.year, fromDate.month, fromDate.day);
      final end = DateTime(toDate.year, toDate.month, toDate.day);
      if (end.isBefore(start)) {
        emit(ConsolidatedReportsError(message: 'Invalid date range'));
        return;
      }

      emit(ConsolidatedReportsLoading(
        currentBranchName: 'Starting...',
        completedBranches: 0,
        totalBranches: branches.length,
      ));

      int completedCount = 0;
      final results = <Map<String, dynamic>?>[];

      for (var branch in branches) {
        emit(ConsolidatedReportsLoading(
          currentBranchName: branch.name,
          completedBranches: completedCount,
          totalBranches: branches.length,
        ));

        final result = await _fetchBranchRangeData(branch, start, end);
        results.add(result);
        completedCount++;
      }

      double totalSales = 0.0;
      double totalExpenses = 0.0;
      double totalMedicinesExpenses = 0.0;
      double totalElectronicPaymentExpenses = 0.0;
      double vaultAmount = 0.0;
      double totalSurplus = 0.0;
      double totalDeficit = 0.0;
      List<ExpenseItem> allExpenses = [];
      Map<String, BranchSummary> branchSummaries = {};
      final branchElectronicBreakdowns = <String, BranchElectronicBreakdown>{};
      final branchDeliveryTotals = <String, double>{};

      for (var result in results) {
        if (result != null) {
          totalSales += result['sales'] as double;
          totalExpenses += result['expenses'] as double;
          totalMedicinesExpenses += result['medicinesExpenses'] as double;
          totalElectronicPaymentExpenses += result['electronicPaymentExpenses'] as double;
          vaultAmount += result['vaultAmount'] as double;
          totalSurplus += result['surplus'] as double;
          totalDeficit += result['deficit'] as double;
          allExpenses.addAll(result['allExpenses'] as List<ExpenseItem>);
          final branchElectronicBreakdown =
              result['branchElectronicBreakdown'] as BranchElectronicBreakdown?;
          if (branchElectronicBreakdown != null) {
            branchElectronicBreakdowns[branchElectronicBreakdown.branchId] =
                branchElectronicBreakdown;
          }
          final deliveryTotal = (result['deliveryExpenses'] as double?) ?? 0.0;
          final branchId = (result['branchId'] as String?) ?? '';
          if (branchId.isNotEmpty) {
            branchDeliveryTotals[branchId] = deliveryTotal;
          }

          final summary = result['summary'] as BranchSummary;
          branchSummaries[summary.branchId] = summary;
        }
      }

      final electronicBreakdown = _computeElectronicBreakdown(allExpenses);
      emit(ConsolidatedReportsLoaded(
        totalSales: totalSales,
        totalExpenses: totalExpenses,
        netProfit: totalSales - totalExpenses,
        totalMedicinesExpenses: totalMedicinesExpenses,
        totalMedicinesWithInvoicesExpenses: _sumExpensesByType(
          allExpenses,
          ExpenseType.medicinesWithInvoices,
        ),
        totalElectronicPaymentExpenses: totalElectronicPaymentExpenses,
        totalInstapayExpenses: electronicBreakdown.instapay,
        totalWalletExpenses: electronicBreakdown.wallet,
        totalVisaExpenses: electronicBreakdown.visa,
        totalDeliveryExpenses: _sumExpensesByType(
          allExpenses,
          ExpenseType.delivery,
        ),
        branchDeliveryTotals: branchDeliveryTotals,
        branchElectronicBreakdowns: branchElectronicBreakdowns,
        vaultAmount: vaultAmount,
        totalSurplus: totalSurplus,
        totalDeficit: totalDeficit,
        allExpenses: allExpenses,
        branchSummaries: branchSummaries,
        monthlyTarget: null,
        branchMonthlyTargets: const {},
        totalPurchases: 0.0,
        branchMonthlyPurchases: const {},
      ));
    } catch (e) {
      emit(ConsolidatedReportsError(message: e.toString()));
    }
  }

  /// Helper: جلب بيانات فرع واحد (يومي)
  Future<Map<String, dynamic>?> _fetchBranchDailyData(
    Branch branch,
    String dateKey,
    DateTime selectedDate,
  ) async {
    try {
      final shiftsSnapshot = await _db
          .collection('daily_reports')
          .doc(dateKey)
          .collection('branches')
          .doc(branch.id)
          .collection('shifts')
          .get();

      double branchSales = 0.0;
      double branchExpenses = 0.0;
      double medicinesExpenses = 0.0;
      double electronicPaymentExpenses = 0.0;
      double surplus = 0.0;
      double deficit = 0.0;
      List<ExpenseItem> expenses = [];

      for (var doc in shiftsSnapshot.docs) {
        final report = ShiftReportModel.fromJson(doc.data());

        branchSales += report.drawerAmount;
        branchExpenses += report.totalExpenses;
        medicinesExpenses += report.medicineExpenses;
        electronicPaymentExpenses += report.electronicWalletExpenses;
        expenses.addAll(report.expenses);

        if (report.computerDifferenceType == ComputerDifferenceType.excess) {
          surplus += report.computerDifference;
        } else if (report.computerDifferenceType == ComputerDifferenceType.shortage) {
          deficit += report.computerDifference;
        }
      }

      // Check if profit is collected
      double vaultAmount = 0.0;
      if (branchSales > 0 || branchExpenses > 0) {
        final isCollected = await ReportFirestoreHelper.getCollectionStatus(
          selectedDate,
          branch.id,
        );

        if (!isCollected) {
          vaultAmount = branchSales - branchExpenses;
        }
      }

      return {
        'sales': branchSales,
        'expenses': branchExpenses,
        'medicinesExpenses': medicinesExpenses,
        'electronicPaymentExpenses': electronicPaymentExpenses,
        'vaultAmount': vaultAmount,
        'surplus': surplus,
        'deficit': deficit,
        'branchId': branch.id,
        'deliveryExpenses': _sumExpensesByType(expenses, ExpenseType.delivery),
        'allExpenses': expenses,
        'branchElectronicBreakdown': BranchElectronicBreakdown(
          branchId: branch.id,
          branchName: branch.name,
          instapay: _sumElectronicByMethod(
            expenses,
            ElectronicPaymentMethod.instapay,
          ),
          wallet: _sumElectronicByMethod(expenses, ElectronicPaymentMethod.wallet),
          visa: _sumElectronicByMethod(expenses, ElectronicPaymentMethod.visa),
        ),
        'summary': BranchSummary(
          branchId: branch.id,
          branchName: branch.name,
          totalSales: branchSales,
          totalExpenses: branchExpenses,
          netProfit: branchSales - branchExpenses,
        ),
      };
    } catch (e) {
      print('Error fetching data for branch ${branch.name}: $e');
      return null;
    }
  }

  /// Helper: جلب بيانات فرع واحد (شهري)
  Future<Map<String, dynamic>?> _fetchBranchMonthlyData(
    Branch branch,
    DateTime selectedDate,
    DateTime lastDay,
  ) async {
    try {
      double branchSales = 0.0;
      double branchExpenses = 0.0;
      double medicinesExpenses = 0.0;
      double electronicPaymentExpenses = 0.0;
      double surplus = 0.0;
      double deficit = 0.0;
      double vaultAmount = 0.0;
      List<ExpenseItem> expenses = [];
      double instapay = 0.0;
      double wallet = 0.0;
      double visa = 0.0;

      // Fetch all days in parallel
      final dayResults = await Future.wait(
        List.generate(lastDay.day, (index) {
          final day = index + 1;
          final date = DateTime(selectedDate.year, selectedDate.month, day);
          return _fetchBranchDayData(branch, date);
        }),
        eagerError: false,
      );

      // Aggregate day results
      for (var dayResult in dayResults) {
        if (dayResult != null) {
          branchSales += dayResult['sales'] as double;
          branchExpenses += dayResult['expenses'] as double;
          medicinesExpenses += dayResult['medicinesExpenses'] as double;
          electronicPaymentExpenses += dayResult['electronicPaymentExpenses'] as double;
          vaultAmount += dayResult['vaultAmount'] as double;
          surplus += dayResult['surplus'] as double;
          deficit += dayResult['deficit'] as double;
          expenses.addAll(dayResult['allExpenses'] as List<ExpenseItem>);
          instapay += (dayResult['instapay'] as double?) ?? 0.0;
          wallet += (dayResult['wallet'] as double?) ?? 0.0;
          visa += (dayResult['visa'] as double?) ?? 0.0;
        }
      }

      return {
        'sales': branchSales,
        'expenses': branchExpenses,
        'medicinesExpenses': medicinesExpenses,
        'electronicPaymentExpenses': electronicPaymentExpenses,
        'vaultAmount': vaultAmount,
        'surplus': surplus,
        'deficit': deficit,
        'branchId': branch.id,
        'deliveryExpenses': _sumExpensesByType(expenses, ExpenseType.delivery),
        'allExpenses': expenses,
        'branchElectronicBreakdown': BranchElectronicBreakdown(
          branchId: branch.id,
          branchName: branch.name,
          instapay: instapay,
          wallet: wallet,
          visa: visa,
        ),
        'summary': BranchSummary(
          branchId: branch.id,
          branchName: branch.name,
          totalSales: branchSales,
          totalExpenses: branchExpenses,
          netProfit: branchSales - branchExpenses,
        ),
      };
    } catch (e) {
      print('Error fetching monthly data for branch ${branch.name}: $e');
      return null;
    }
  }

  /// Helper: جلب بيانات يوم واحد لفرع
  Future<Map<String, dynamic>?> _fetchBranchDayData(
    Branch branch,
    DateTime date,
  ) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      final shiftsSnapshot = await _db
          .collection('daily_reports')
          .doc(dateStr)
          .collection('branches')
          .doc(branch.id)
          .collection('shifts')
          .get();

      double dailySales = 0.0;
      double dailyExpenses = 0.0;
      double medicinesExpenses = 0.0;
      double electronicPaymentExpenses = 0.0;
      double surplus = 0.0;
      double deficit = 0.0;
      List<ExpenseItem> expenses = [];
      double instapay = 0.0;
      double wallet = 0.0;
      double visa = 0.0;

      for (var doc in shiftsSnapshot.docs) {
        final report = ShiftReportModel.fromJson(doc.data());

        dailySales += report.drawerAmount;
        dailyExpenses += report.totalExpenses;
        medicinesExpenses += report.medicineExpenses;
        electronicPaymentExpenses += report.electronicWalletExpenses;
        expenses.addAll(report.expenses);
        instapay += _sumElectronicByMethod(
          report.expenses,
          ElectronicPaymentMethod.instapay,
        );
        wallet +=
            _sumElectronicByMethod(report.expenses, ElectronicPaymentMethod.wallet);
        visa += _sumElectronicByMethod(report.expenses, ElectronicPaymentMethod.visa);

        if (report.computerDifferenceType == ComputerDifferenceType.excess) {
          surplus += report.computerDifference;
        } else if (report.computerDifferenceType == ComputerDifferenceType.shortage) {
          deficit += report.computerDifference;
        }
      }

      // Check if profit is collected
      double vaultAmount = 0.0;
      if (dailySales > 0 || dailyExpenses > 0) {
        final isCollected = await ReportFirestoreHelper.getCollectionStatus(
          date,
          branch.id,
        );

        if (!isCollected) {
          vaultAmount = dailySales - dailyExpenses;
        }
      }

      return {
        'sales': dailySales,
        'expenses': dailyExpenses,
        'medicinesExpenses': medicinesExpenses,
        'electronicPaymentExpenses': electronicPaymentExpenses,
        'vaultAmount': vaultAmount,
        'surplus': surplus,
        'deficit': deficit,
        'deliveryExpenses': _sumExpensesByType(expenses, ExpenseType.delivery),
        'allExpenses': expenses,
        'instapay': instapay,
        'wallet': wallet,
        'visa': visa,
      };
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchBranchRangeData(
    Branch branch,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    try {
      double branchSales = 0.0;
      double branchExpenses = 0.0;
      double medicinesExpenses = 0.0;
      double electronicPaymentExpenses = 0.0;
      double surplus = 0.0;
      double deficit = 0.0;
      double vaultAmount = 0.0;
      final expenses = <ExpenseItem>[];
      double instapay = 0.0;
      double wallet = 0.0;
      double visa = 0.0;

      for (DateTime day = fromDate;
          !day.isAfter(toDate);
          day = day.add(const Duration(days: 1))) {
        final dayResult = await _fetchBranchDayData(branch, day);
        if (dayResult == null) continue;
        branchSales += dayResult['sales'] as double;
        branchExpenses += dayResult['expenses'] as double;
        medicinesExpenses += dayResult['medicinesExpenses'] as double;
        electronicPaymentExpenses += dayResult['electronicPaymentExpenses'] as double;
        vaultAmount += dayResult['vaultAmount'] as double;
        surplus += dayResult['surplus'] as double;
        deficit += dayResult['deficit'] as double;
        expenses.addAll(dayResult['allExpenses'] as List<ExpenseItem>);
        instapay += (dayResult['instapay'] as double?) ?? 0.0;
        wallet += (dayResult['wallet'] as double?) ?? 0.0;
        visa += (dayResult['visa'] as double?) ?? 0.0;
      }

      return {
        'sales': branchSales,
        'expenses': branchExpenses,
        'medicinesExpenses': medicinesExpenses,
        'electronicPaymentExpenses': electronicPaymentExpenses,
        'vaultAmount': vaultAmount,
        'surplus': surplus,
        'deficit': deficit,
        'branchId': branch.id,
        'deliveryExpenses': _sumExpensesByType(expenses, ExpenseType.delivery),
        'allExpenses': expenses,
        'branchElectronicBreakdown': BranchElectronicBreakdown(
          branchId: branch.id,
          branchName: branch.name,
          instapay: instapay,
          wallet: wallet,
          visa: visa,
        ),
        'summary': BranchSummary(
          branchId: branch.id,
          branchName: branch.name,
          totalSales: branchSales,
          totalExpenses: branchExpenses,
          netProfit: branchSales - branchExpenses,
        ),
      };
    } catch (e) {
      return null;
    }
  }

  double _sumExpensesByType(List<ExpenseItem> expenses, ExpenseType type) {
    return expenses
        .where((e) => e.type == type)
        .fold(0.0, (acc, e) => acc + e.amount);
  }

  double _sumElectronicByMethod(
    List<ExpenseItem> expenses,
    ElectronicPaymentMethod method,
  ) {
    return expenses
        .where(
          (e) => e.type == ExpenseType.electronicPayment && e.electronicMethod == method,
        )
        .fold(0.0, (acc, e) => acc + e.amount);
  }

  ({double instapay, double wallet, double visa}) _computeElectronicBreakdown(
    List<ExpenseItem> expenses,
  ) {
    double instapay = 0.0;
    double wallet = 0.0;
    double visa = 0.0;
    for (final expense in expenses) {
      if (expense.type != ExpenseType.electronicPayment) continue;
      switch (expense.electronicMethod) {
        case ElectronicPaymentMethod.instapay:
          instapay += expense.amount;
          break;
        case ElectronicPaymentMethod.wallet:
          wallet += expense.amount;
          break;
        case ElectronicPaymentMethod.visa:
          visa += expense.amount;
          break;
        default:
          break;
      }
    }
    return (instapay: instapay, wallet: wallet, visa: visa);
  }
}

