import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/enums/notification_type.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/services/notification_service.dart';
import 'package:pharmacy/features/report/data/helpers/report_firestore_helper.dart';
import 'package:pharmacy/features/report/data/models/daily_report_model.dart';
import 'package:pharmacy/features/report/logic/shift_report_state.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';

// Model to hold file data for both web and mobile
class AttachmentFileData {
  final String name;
  final Uint8List bytes;
  final String? path; // null on web

  AttachmentFileData({
    required this.name,
    required this.bytes,
    this.path,
  });
}

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
  List<String> attachmentUrls = []; // Multiple attachment URLs
  List<AttachmentFileData> attachmentFiles = []; // Local files before upload

  // Current date
  DateTime currentDate = DateTime.now();

  // Track submitted shifts for today (to disable them)
  final Set<ShiftType> submittedShifts = {};

  /// Load all submitted shifts for today
  Future<void> loadTodaySubmittedShifts() async {
    try {
      final shifts = await ReportFirestoreHelper.getBranchShifts(
        currentDate,
        currentUser.currentBranch.id,
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
        currentUser.currentBranch.id,
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
        attachmentUrls = List.from(existingShift.attachmentUrls);

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
        attachmentUrls = List.from(myShift.attachmentUrls);

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

  /// Pick and store attachment locally (will be uploaded on submit)
  void pickAttachment(AttachmentFileData fileData) {
    attachmentFiles.add(fileData);
    emit(ShiftReportUpdated());
  }

  /// Remove attachment by index
  void removeAttachment(int index) {
    if (index < attachmentFiles.length) {
      attachmentFiles.removeAt(index);
    } else {
      // Remove from uploaded URLs
      final urlIndex = index - attachmentFiles.length;
      if (urlIndex >= 0 && urlIndex < attachmentUrls.length) {
        attachmentUrls.removeAt(urlIndex);
      }
    }
    emit(AttachmentRemoved());
  }

  /// Upload attachment to Firebase Storage
  Future<String> _uploadAttachment(AttachmentFileData fileData) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = fileData.name.split('.').last;
      final dateStr = _formatDate(currentDate);
      final fileName = '${timestamp}_${selectedShiftType!.name}.$extension';

      final storageRef = FirebaseStorage.instance.ref().child(
        'shift_reports/${currentUser.currentBranch.id}/$dateStr/$fileName',
      );

      // Use bytes for upload (works on both web and mobile)
      final uploadTask = await storageRef.putData(
        fileData.bytes,
        SettableMetadata(
          contentType: _getContentType(extension),
        ),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload attachment: ${e.toString()}');
    }
  }

  /// Get content type based on file extension
  String _getContentType(String extension) {
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

      // Upload all attachments if exist
      final List<String> uploadedUrls = List.from(attachmentUrls);
      if (attachmentFiles.isNotEmpty) {
        try {
          for (var file in attachmentFiles) {
            final url = await _uploadAttachment(file);
            uploadedUrls.add(url);
          }
        } catch (e) {
          emit(AttachmentUploadError(e.toString()));
          return;
        }
      }

      // Create report model
      final report = ShiftReportModel(
        id: '${currentUser.currentBranch.id}_${_formatDate(currentDate)}_${selectedShiftType!.name}',
        branchId: currentUser.currentBranch.id,
        branchName: currentUser.currentBranch.name,
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
        attachmentUrls: uploadedUrls,
        submittedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await ReportFirestoreHelper.saveShift(
        currentDate,
        currentUser.currentBranch.id,
        report,
      );

      // Send notification to subManagers, managers and admins
      await _sendNewShiftReportNotification(report, _formatDate(currentDate));

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
        id: '${currentUser.currentBranch.id}_${_formatDate(currentDate)}_${selectedShiftType!.name}',
        branchId: currentUser.currentBranch.id,
        branchName: currentUser.currentBranch.name,
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
        attachmentUrls: List.from(attachmentUrls),
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      await ReportFirestoreHelper.saveShift(
        currentDate,
        currentUser.currentBranch.id,
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
    attachmentUrls.clear();
    attachmentFiles.clear();
    emit(ShiftReportInitial());
  }

  /// Helper: Format date to yyyy-MM-dd
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Helper: Send notification when new shift report is added
  Future<void> _sendNewShiftReportNotification(ShiftReportModel report, String date) async {
    try {
      final notificationService = getIt<NotificationService>();

      // Get subManagers, managers and admins for this branch
      final managerIds = await notificationService.getUserIdsByRoleAndBranches(
        roles: [Role.subManager.name, Role.manager.name, Role.admin.name],
        branchIds: [report.branchId],
      );

      if (managerIds.isEmpty) return;

      // Get shift type name in Arabic
      String shiftTypeName = report.shiftNameAr;

      await notificationService.sendNotificationToUsers(
        userIds: managerIds,
        title: 'تقرير شيفت جديد - فرع ${report.branchName}',
        body: 'تم إضافة تقرير شيفت $shiftTypeName بتاريخ $date',
        type: NotificationType.newShiftReport,
        additionalData: {
          'branchId': report.branchId,
          'shiftType': report.shiftType.name,
          'date': date,
        },
      );
    } catch (e) {
      print('Error sending new shift report notification: $e');
    }
  }
}

