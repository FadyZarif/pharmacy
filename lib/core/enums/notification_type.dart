enum NotificationType {
  // Request Approved/Rejected
  annualLeaveApproved('annual_leave_approved'),
  annualLeaveRejected('annual_leave_rejected'),
  sickLeaveApproved('sick_leave_approved'),
  sickLeaveRejected('sick_leave_rejected'),
  permissionApproved('permission_approved'), // انصراف مبكر
  permissionRejected('permission_rejected'),
  attendApproved('attend_approved'), // نسيان بصمة
  attendRejected('attend_rejected'),
  coverageShiftApproved('coverage_shift_approved'), // تبديل شيفت
  coverageShiftRejected('coverage_shift_rejected'),
  extraHoursApproved('extra_hours_approved'), // ساعات إضافية
  extraHoursRejected('extra_hours_rejected'),

  // New Requests (for managers/admin)
  newAnnualLeaveRequest('new_annual_leave_request'),
  newSickLeaveRequest('new_sick_leave_request'),
  newPermissionRequest('new_permission_request'),
  newAttendRequest('new_attend_request'),
  newCoverageShiftRequest('new_coverage_shift_request'),
  newExtraHoursRequest('new_extra_hours_request'),

  // Salary
  salaryAdded('salary_added'),

  // Shift Reports
  newShiftReport('new_shift_report'),
  shiftReportUpdated('shift_report_updated'),

  // Job Opportunities
  newJobOpportunity('new_job_opportunity'),

  // Maintenance Reports
  newMaintenanceReport('new_maintenance_report'),

  // Daily Report
  netProfitCollected('net_profit_collected');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.salaryAdded,
    );
  }
}
