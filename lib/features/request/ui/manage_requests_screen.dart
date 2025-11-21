import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/core/di/dependency_injection.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/core/widgets/profile_circle.dart';
import 'package:pharmacy/features/request/data/models/request_model.dart';
import 'package:pharmacy/features/request/logic/request_cubit.dart';
import 'package:pharmacy/features/request/logic/request_state.dart';
import 'package:pharmacy/features/request/ui/request_details_screen.dart';


class ManageRequestsScreen extends StatelessWidget {
  const ManageRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<RequestCubit>(),
      child: const _ManageRequestsBody(),
    );
  }
}

class _ManageRequestsBody extends StatelessWidget {
  const _ManageRequestsBody();

  @override
  Widget build(BuildContext context) {
    final cubit = getIt<RequestCubit>();

    return BlocListener<RequestCubit, RequestState>(
      listenWhen: (previous, current) =>
      current is AddRequestLoading ||
          current is AddRequestSuccess ||
          current is AddRequestFailure,
      listener: (context, state) async {
        if (state is AddRequestLoading) {
          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(
                color: ColorsManger.primary,
              ),
            ),
          );
        } else if (state is AddRequestSuccess) {
          // Close loading dialog
          Navigator.pop(context);

          // Show success message
          await defToast2(
            context: context,
            msg: 'Request updated successfully',
            dialogType: DialogType.success,
          );

        } else if (state is AddRequestFailure) {
          // Close loading dialog
          Navigator.pop(context);

          // Show error message
          await defToast2(
            context: context,
            msg: state.error,
            dialogType: DialogType.error,
            sec: 5,

          );
        }
      },
  child: Scaffold(
      backgroundColor: ColorsManger.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Requests [${currentUser.currentBranch.name}]',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: ColorsManger.primary,
        foregroundColor: Colors.white,
        actions: [
          // Month selector
          BlocBuilder<RequestCubit, RequestState>(
            buildWhen: (previous, current) =>
                current is FetchRequestsSuccess || current is FetchRequestsLoading,
            builder: (context, state) {
              final selectedMonth = cubit.selectedMonth;
              final isCurrentMonth = selectedMonth.year == DateTime.now().year &&
                  selectedMonth.month == DateTime.now().month;

              return PopupMenuButton<int>(
                icon: const Icon(Icons.calendar_month, color: Colors.white),
                tooltip: 'Select Month',
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: -1,
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back, size: 18, color: Colors.black),
                        const SizedBox(width: 8),
                        Text('Previous Month'),
                      ],
                    ),
                  ),
                  if (!isCurrentMonth)
                    PopupMenuItem(
                      value: 0,
                      child: Row(
                        children: [
                          const Icon(Icons.today, size: 18, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text('Current Month', style: TextStyle(color: Colors.blue)),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 1,
                    enabled: !isCurrentMonth,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_forward, size: 18, color: isCurrentMonth ? Colors.grey : Colors.black),
                        const SizedBox(width: 8),
                        Text('Next Month', style: TextStyle(color: isCurrentMonth ? Colors.grey : null)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == -1) {
                    cubit.previousMonth();
                  } else if (value == 0) {
                    cubit.resetToCurrentMonth();
                  } else if (value == 1) {
                    cubit.nextMonth();
                  }
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<RequestCubit, RequestState>(
        buildWhen: (previous, current) =>
            current is FetchRequestsSuccess ||
            current is FetchRequestsLoading ||
            current is FetchRequestsFailure,
        builder: (context, state) {
          return Column(
            children: [
              // Month indicator
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: ColorsManger.primary.withValues(alpha: 0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMMM yyyy').format(cubit.selectedMonth),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Status filter
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildStatusTab(context, RequestStatus.pending, 'Pending', Icons.pending),
                    _buildStatusTab(context, RequestStatus.approved, 'Approved', Icons.check_circle),
                    _buildStatusTab(context, RequestStatus.rejected, 'Rejected', Icons.cancel),
                  ],
                ),
              ),

              // Requests list
              Expanded(
                child: _buildRequestsList(state),
              ),
            ],
          );
        },
      ),
    ),
);
  }

  Widget _buildRequestsList(RequestState state) {
    if (state is FetchRequestsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is FetchRequestsFailure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return BlocBuilder<RequestCubit, RequestState>(
      builder: (context, state) {
        final cubit = getIt<RequestCubit>();
        final requests = cubit.managementRequests;

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${cubit.selectedStatus.name} requests',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'for ${DateFormat('MMMM yyyy').format(cubit.selectedMonth)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _buildRequestCard(context, requests[index]);
          },
        );
      },
    );
  }

  Widget _buildStatusTab(BuildContext context, RequestStatus status, String label, IconData icon) {
    return BlocBuilder<RequestCubit, RequestState>(
      builder: (context, state) {
        final cubit = getIt<RequestCubit>();
        final isSelected = cubit.selectedStatus == status;

        // Count requests for this status
        final count = isSelected ? cubit.managementRequests.length : 0;

        Color selectedColor;
        switch (status) {
          case RequestStatus.pending:
            selectedColor = Colors.orange;
            break;
          case RequestStatus.approved:
            selectedColor = Colors.green;
            break;
          case RequestStatus.rejected:
            selectedColor = Colors.red;
            break;
        }

        return Expanded(
          child: GestureDetector(
            onTap: () => cubit.changeStatus(status),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isSelected && count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count.toString(),
                            style: TextStyle(
                              color: selectedColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildRequestCard(BuildContext context, RequestModel request) {
    final cubit = getIt<RequestCubit>();

    return GestureDetector(
      onTap: () {
        navigateTo(context, RequestDetailsScreen(request: request));
      },
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  ProfileCircle(
                    photoUrl: request.employeePhoto,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.employeeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          request.employeeBranchName,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildRequestTypeChip(request.type),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Details
              _buildRequestDetails(request),

              // Notes (if any)
              if (request.notes != null && request.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          request.notes!,
                          style: TextStyle(color: Colors.grey[800]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action buttons (only for pending requests)
              if (cubit.selectedStatus == RequestStatus.pending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _rejectRequest(context, request),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveRequest(context, request),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),


                  ],
                ),
              ],

              // Timestamp
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Created: ${DateFormat('MMM dd, yyyy - hh:mm a').format(request.createdAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  // Show who processed the request if it's approved or rejected
                  if (request.status != RequestStatus.pending &&
                      request.processedByName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          request.status == RequestStatus.approved
                            ? Icons.check_circle
                            : Icons.cancel,
                          size: 14,
                          color: request.statusColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${request.status == RequestStatus.approved ? 'Approved' : 'Rejected'} by ${request.processedByName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: request.statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestTypeChip(RequestType type) {
    Color color;
    IconData icon;

    switch (type) {
      case RequestType.annualLeave:
        color = Colors.blue;
        icon = Icons.beach_access;
        break;
      case RequestType.sickLeave:
        color = Colors.orange;
        icon = Icons.local_hospital;
        break;
      case RequestType.extraHours:
        color = Colors.purple;
        icon = Icons.access_time;
        break;
      case RequestType.coverageShift:
        color = Colors.teal;
        icon = Icons.swap_horiz;
        break;
      case RequestType.attend:
        color = Colors.green;
        icon = Icons.fingerprint;
        break;
      case RequestType.permission:
        color = Colors.indigo;
        icon = Icons.exit_to_app;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            type.name,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestDetails(RequestModel request) {
    switch (request.type) {
      case RequestType.annualLeave:
        final details = AnnualLeaveDetails.fromJson(request.details);
        return _buildDetailRow(
          'Period',
          '${DateFormat('MMM dd').format(details.startDate)} - ${DateFormat('MMM dd, yyyy').format(details.endDate)}',
          Icons.date_range,
        );

      case RequestType.sickLeave:
        final details = SickLeaveDetails.fromJson(request.details);
        return Column(
          children: [
            _buildDetailRow(
              'Period',
              '${DateFormat('MMM dd').format(details.startDate)} - ${DateFormat('MMM dd, yyyy').format(details.endDate)}',
              Icons.date_range,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Prescription',
              'View Document',
              Icons.attachment,
              onTap: () {
                // TODO: Open prescription

              },
            ),
          ],
        );

      case RequestType.extraHours:
        final details = ExtraHoursDetails.fromJson(request.details);
        return _buildDetailRow(
          'Extra Hours',
          '${details.hours}h on ${DateFormat('MMM dd, yyyy').format(details.date)}',
          Icons.schedule,
        );

      case RequestType.coverageShift:
        final details = CoverageShiftDetails.fromJson(request.details);
        return Column(
          children: [
            _buildDetailRow(
              'Date',
              DateFormat('MMM dd, yyyy').format(details.date),
              Icons.calendar_today,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Swap with',
              '${details.peerEmployeeName} (${details.peerBranchName})',
              Icons.person_outline,
            ),
          ],
        );

      case RequestType.attend:
        final details = AttendDetails.fromJson(request.details);
        return _buildDetailRow(
          'Forgot to punch',
          DateFormat('MMM dd, yyyy').format(details.date),
          Icons.fingerprint,
        );

      case RequestType.permission:
        final details = PermissionDetails.fromJson(request.details);
        return _buildDetailRow(
          'Early Leave',
          '${details.hours}h on ${DateFormat('MMM dd, yyyy').format(details.date)}',
          Icons.logout,
        );
    }
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: ColorsManger.primary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: onTap != null ? Colors.blue : Colors.black87,
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRequest(BuildContext context, RequestModel request) async {
    await AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: 'Approve Request',
      desc: 'Are you sure you want to approve this ${request.type.name} request?',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await getIt<RequestCubit>().approveRequest(request);

      },
    ).show();



  }

  Future<void> _rejectRequest(BuildContext context, RequestModel request) async {
    await AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Reject Request',
      desc: 'Are you sure you want to reject this ${request.type.name} request?',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await getIt<RequestCubit>().rejectRequest(request);

      },
    ).show();



  }
}

