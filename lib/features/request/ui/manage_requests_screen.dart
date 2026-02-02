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
import 'package:pharmacy/features/user/data/models/user_model.dart';


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

  bool _canCurrentUserManageRequests() {
    return currentUser.isManagement ||
        (currentUser.role == Role.subManager && currentUser.hasRequestsPermission);
  }

  bool _canCurrentUserProcessThisRequest(RequestModel request) {
    // SubManager can manage requests for their branch, but cannot approve/reject their own requests.
    if (!_canCurrentUserManageRequests()) return false;
    if (currentUser.role == Role.subManager &&
        currentUser.hasRequestsPermission &&
        request.employeeId == currentUser.uid) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = getIt<RequestCubit>();
    final topPad = MediaQuery.of(context).padding.top;

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
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.56),
            border: Border(
              bottom: BorderSide(
                color: ColorsManger.primary.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Requests · ${currentUser.currentBranch.name}',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.80),
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            actions: [
              BlocBuilder<RequestCubit, RequestState>(
                buildWhen: (previous, current) =>
                    current is FetchRequestsSuccess || current is FetchRequestsLoading,
                builder: (context, state) {
                  final selectedMonth = cubit.selectedMonth;
                  final isCurrentMonth = selectedMonth.year == DateTime.now().year &&
                      selectedMonth.month == DateTime.now().month;

                  return PopupMenuButton<int>(
                    icon: const Icon(Icons.calendar_month, color: ColorsManger.primary),
                    tooltip: 'Select Month',
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: -1,
                        child: Row(
                          children: [
                            Icon(Icons.arrow_back, size: 18, color: Colors.black),
                            SizedBox(width: 8),
                            Text('Previous Month'),
                          ],
                        ),
                      ),
                      if (!isCurrentMonth)
                        const PopupMenuItem(
                          value: 0,
                          child: Row(
                            children: [
                              Icon(Icons.today, size: 18, color: ColorsManger.primary),
                              SizedBox(width: 8),
                              Text(
                                'Current Month',
                                style: TextStyle(color: ColorsManger.primary),
                              ),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 1,
                        enabled: !isCurrentMonth,
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: isCurrentMonth ? Colors.grey : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Next Month',
                              style: TextStyle(color: isCurrentMonth ? Colors.grey : null),
                            ),
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
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          const _ManageRequestsBackground(),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              topPad + kToolbarHeight + 12,
              16,
              0,
            ),
            child: BlocBuilder<RequestCubit, RequestState>(
        buildWhen: (previous, current) =>
            current is FetchRequestsSuccess ||
            current is FetchRequestsLoading ||
            current is FetchRequestsFailure,
        builder: (context, state) {
          return Column(
            children: [
              // Month indicator
              _PanelCard(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: ColorsManger.primary),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMMM yyyy').format(cubit.selectedMonth),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),

              // Status filter
              const SizedBox(height: 12),
              _PanelCard(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    _buildStatusTab(context, RequestStatus.pending, 'Pending', Icons.pending),
                    _buildStatusTab(context, RequestStatus.approved, 'Approved', Icons.check_circle),
                    _buildStatusTab(context, RequestStatus.rejected, 'Rejected', Icons.cancel),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Requests list
              Expanded(
                child: _buildRequestsList(state),
              ),
            ],
          );
        },
      ),
          ),
        ],
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
    final canProcess = _canCurrentUserProcessThisRequest(request);
    final isOwnRequest = request.employeeId == currentUser.uid;

    return GestureDetector(
      onTap: () {
        navigateTo(
          context,
          RequestDetailsScreen(
            request: request,
            canManage: canProcess,
          ),
        );
      },
      child: _PanelCard(
        margin: const EdgeInsets.only(bottom: 12),
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
                  _buildRequestTypeChip(request),
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
                        onPressed: canProcess ? () => _rejectRequest(context, request) : null,
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
                        onPressed: canProcess ? () => _approveRequest(context, request) : null,
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
                if (!canProcess && isOwnRequest) ...[
                  const SizedBox(height: 10),
                  Text(
                    "You can't approve/reject your own request.",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                ],
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
                          color: request.status.color,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${request.status == RequestStatus.approved ? 'Approved' : 'Rejected'} by ${request.processedByName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: request.status.color,
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
    );
  }

  Widget _buildRequestTypeChip(RequestModel request) {
    Color color;
    IconData icon;
    String label;

    switch (request.type) {
      case RequestType.annualLeave:
        color = Colors.blue;
        icon = Icons.beach_access;
        label = request.type.name;
        break;
      case RequestType.sickLeave:
        color = Colors.orange;
        icon = Icons.local_hospital;
        label = request.type.name;
        break;
      case RequestType.extraHours:
        color = Colors.purple;
        icon = Icons.access_time;
        label = request.type.name;
        break;
      case RequestType.coverageShift:
        color = Colors.teal;
        icon = Icons.swap_horiz;
        label = request.type.name;
        break;
      case RequestType.attend:
        color = Colors.green;
        icon = Icons.fingerprint;
        label = request.type.name;
        break;
      case RequestType.permission:
        final details = PermissionDetails.fromJson(request.details);
        if (details.type == PermissionType.lateArrival) {
          color = Colors.red;
          icon = Icons.login;
          label = 'Late Arrival';
        } else {
          color = Colors.indigo;
          icon = Icons.logout;
          label = 'Early Leave';
        }
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
            label,
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
        final permissionTypeText = details.type == PermissionType.lateArrival
            ? 'Late Arrival'
            : 'Early Leave';
        final icon = details.type == PermissionType.lateArrival
            ? Icons.login
            : Icons.logout;

        return Column(
          children: [
            _buildDetailRow(
              'Type',
              permissionTypeText,
              icon,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Duration',
              '${details.hours}h ${details.minutes}m on ${DateFormat('MMM dd, yyyy').format(details.date)}',
              Icons.schedule,
            ),
          ],
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

class _ManageRequestsBackground extends StatelessWidget {
  const _ManageRequestsBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColorsManger.primary.withValues(alpha: 0.08),
            ColorsManger.primaryBackground,
            ColorsManger.primaryBackground,
          ],
        ),
      ),
    );
  }
}

List<BoxShadow> _panelShadow() => [
      BoxShadow(
        color: ColorsManger.primary.withValues(alpha: 0.14),
        blurRadius: 22,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ];

class _PanelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const _PanelCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.16)),
        boxShadow: _panelShadow(),
      ),
      child: child,
    );
  }
}