import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/features/report/data/helpers/report_firestore_helper.dart';
import 'package:pharmacy/features/report/data/models/daily_report_model.dart';
import 'package:pharmacy/features/report/logic/shift_report_state.dart';

class ShiftReportCubit extends Cubit<ShiftReportState> {
  ShiftReportCubit() : super(ShiftReportInitial());

  // Current shift data
  ShiftType? selectedShiftType;
  double drawerAmount = 0.0;
  ComputerDifferenceType? computerDifferenceType;
  double computerDifference = 0.0;
  double electronicWalletAmount = 0.0;
  String? notes;
  final List<ExpenseItem> expenses = [];
  final List<String> attachments = [];

  // Current date
  DateTime currentDate = DateTime.now();

  // Track submitted shifts for today (to disable them)
  final Set<ShiftType> submittedShifts = {};

  /// Load all submitted shifts for today
  Future<void> loadTodaySubmittedShifts() async {
    try {
      final shifts = await ReportFirestoreHelper.getBranchShifts(
        currentDate,
        currentUser.branchId,
      );

      submittedShifts.clear();
      for (var shift in shifts) {
        submittedShifts.add(shift.shiftType);
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Check if a shift already exists for today
  Future<void> checkExistingShift(ShiftType shiftType) async {
    try {
      emit(ShiftReportLoading());

      final existingShift = await ReportFirestoreHelper.getShift(
        currentDate,
        currentUser.branchId,
        shiftType,
      );

      if (existingShift != null) {
        // Load existing data
        selectedShiftType = existingShift.shiftType;
        drawerAmount = existingShift.drawerAmount;
        computerDifferenceType = existingShift.computerDifferenceType;
        computerDifference = existingShift.computerDifference;
        electronicWalletAmount = existingShift.electronicWalletAmount;
        notes = existingShift.notes;
        expenses.clear();
        expenses.addAll(existingShift.expenses);
        attachments.clear();
        attachments.addAll(existingShift.attachments);

        emit(ShiftAlreadyExists(existingShift));
      } else {
        emit(NoExistingShift());
      }
    } catch (e) {
      emit(ShiftReportError('Failed to check existing shift: ${e.toString()}'));
    }
  }

  /// Load my shift for today
  Future<void> loadMyTodayShift() async {
    try {
      emit(ShiftReportLoadingMyShift());

      // Load all submitted shifts first
      await loadTodaySubmittedShifts();

      final myShift = await ReportFirestoreHelper.getMyTodayShift(
        currentUser.uid,
      );

      if (myShift != null) {
        // Check if shift is already submitted
        if (submittedShifts.contains(myShift.shiftType)) {
          // Shift already submitted - make it read-only
          emit(ShiftAlreadyExists(myShift));
          return;
        }

        // Load data
        selectedShiftType = myShift.shiftType;
        drawerAmount = myShift.drawerAmount;
        computerDifferenceType = myShift.computerDifferenceType;
        computerDifference = myShift.computerDifference;
        electronicWalletAmount = myShift.electronicWalletAmount;
        notes = myShift.notes;
        expenses.clear();
        expenses.addAll(myShift.expenses);
        attachments.clear();
        attachments.addAll(myShift.attachments);

        emit(ShiftReportLoaded(myShift));
      } else {
        emit(ShiftReportInitial());
      }
    } catch (e) {
      emit(ShiftReportError('Failed to load shift: ${e.toString()}'));
    }
  }

  /// Update shift type
  void updateShiftType(ShiftType type) {
    selectedShiftType = type;
    emit(ShiftReportUpdated());
  }

  /// Update drawer amount
  void updateDrawerAmount(double amount) {
    drawerAmount = amount;
    emit(ShiftReportUpdated());
  }

  /// Update computer difference
  void updateComputerDifference(
    ComputerDifferenceType? type,
    double difference,
  ) {
    computerDifferenceType = type;
    computerDifference = difference;
    emit(ShiftReportUpdated());
  }

  /// Update electronic wallet amount
  void updateElectronicWallet(double amount) {
    electronicWalletAmount = amount;
    emit(ShiftReportUpdated());
  }

  /// Update notes
  void updateNotes(String? note) {
    notes = note;
    emit(ShiftReportUpdated());
  }

  /// Add expense
  void addExpense(ExpenseItem expense) {
    expenses.add(expense);
    emit(ExpenseAdded(List.from(expenses)));
  }

  /// Remove expense
  void removeExpense(ExpenseItem expense) {
    expenses.remove(expense);
    emit(ExpenseRemoved(List.from(expenses)));
  }

  /// Calculate total expenses
  double get totalExpenses {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Calculate net amount (drawer - expenses)
  double get netAmount {
    return drawerAmount - totalExpenses;
  }

  /// Upload attachment to Firebase Storage
  Future<void> uploadAttachment(File file) async {
    try {
      emit(AttachmentUploading());

      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance.ref().child(
            'shift_reports/${currentUser.branchId}/$fileName',
          );

      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      attachments.add(downloadUrl);
      emit(AttachmentUploaded(downloadUrl, List.from(attachments)));
    } catch (e) {
      emit(AttachmentUploadError('Failed to upload attachment: ${e.toString()}'));
    }
  }

  /// Remove attachment
  void removeAttachment(String url) {
    attachments.remove(url);
    emit(ShiftReportUpdated());
  }

  /// Validate shift data before submission
  String? validateShiftData() {
    if (selectedShiftType == null) {
      return 'Please select shift type';
    }

    if (drawerAmount <= 0) {
      return 'Please enter a valid drawer amount';
    }

    if (computerDifferenceType != null &&
        computerDifferenceType != ComputerDifferenceType.none) {
      if (computerDifference <= 0) {
        return 'Please enter a valid computer difference amount';
      }
    }

    return null;
  }

  /// Submit shift report
  Future<void> submitShiftReport() async {
    try {
      // Validate
      final validationError = validateShiftData();
      if (validationError != null) {
        emit(ShiftReportValidationError(validationError));
        return;
      }

      emit(ShiftReportLoading());

      // Create report model
      final report = ShiftReportModel(
        id: '${currentUser.branchId}_${_formatDate(currentDate)}_${selectedShiftType!.name}',
        branchId: currentUser.branchId,
        branchName: currentUser.branchName,
        shiftType: selectedShiftType!,
        employeeId: currentUser.uid,
        employeeName: currentUser.name,
        employeePhoto: currentUser.photoUrl,
        drawerAmount: drawerAmount,
        expenses: List.from(expenses),
        notes: notes,
        computerDifferenceType: computerDifferenceType,
        computerDifference: computerDifference,
        electronicWalletAmount: electronicWalletAmount,
        attachments: List.from(attachments),
        submittedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await ReportFirestoreHelper.saveShift(
        currentDate,
        currentUser.branchId,
        report,
      );

      emit(ShiftReportSubmitted(report));
    } catch (e) {
      emit(ShiftReportError('Failed to submit report: ${e.toString()}'));
    }
  }

  /// Update existing shift report
  Future<void> updateShiftReport() async {
    try {
      // Validate
      final validationError = validateShiftData();
      if (validationError != null) {
        emit(ShiftReportValidationError(validationError));
        return;
      }

      emit(ShiftReportLoading());

      // Create updated report model
      final report = ShiftReportModel(
        id: '${currentUser.branchId}_${_formatDate(currentDate)}_${selectedShiftType!.name}',
        branchId: currentUser.branchId,
        branchName: currentUser.branchName,
        shiftType: selectedShiftType!,
        employeeId: currentUser.uid,
        employeeName: currentUser.name,
        employeePhoto: currentUser.photoUrl,
        drawerAmount: drawerAmount,
        expenses: List.from(expenses),
        notes: notes,
        computerDifferenceType: computerDifferenceType,
        computerDifference: computerDifference,
        electronicWalletAmount: electronicWalletAmount,
        attachments: List.from(attachments),
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      await ReportFirestoreHelper.saveShift(
        currentDate,
        currentUser.branchId,
        report,
      );

      emit(ShiftReportSubmitted(report));
    } catch (e) {
      emit(ShiftReportError('Failed to update report: ${e.toString()}'));
    }
  }

  /// Reset all data
  void reset() {
    selectedShiftType = null;
    drawerAmount = 0.0;
    computerDifferenceType = null;
    computerDifference = 0.0;
    electronicWalletAmount = 0.0;
    notes = null;
    expenses.clear();
    attachments.clear();
    emit(ShiftReportInitial());
  }

  /// Helper: Format date to yyyy-MM-dd
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

