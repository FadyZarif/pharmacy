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
import 'package:url_launcher/url_launcher.dart';

class RequestDetailsScreen extends StatelessWidget {
  final RequestModel request;
  final bool canManage;

  const RequestDetailsScreen({
    super.key,
    required this.request,
    this.canManage = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<RequestCubit>(),
      child: BlocListener<RequestCubit, RequestState>(
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

            // Close the details screen
            if (!context.mounted) return;
              Navigator.pop(context);
              Navigator.pop(context);

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
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: request.status.color,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                request.type.enName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      request.status.color,
                      request.status.color.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // const SizedBox(height: 40),
                    _buildStatusBadge(),
                  ],
                ),
              ),
            ),
            foregroundColor: Colors.white,

          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Employee Info Card
                  _buildEmployeeCard(),
                  const SizedBox(height: 16),

                  // Request Details Card
                  _buildDetailsCard(context),

                  // Notes Card (if exists)
                  if (request.notes != null && request.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildNotesCard(),
                  ],

                  const SizedBox(height: 16),

                  // Timeline Card
                  _buildTimelineCard(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Floating Action Buttons (for pending requests)
      floatingActionButton: canManage && request.status == RequestStatus.pending
          ? _buildActionButtons(context)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    String label;
    IconData icon;

    switch (request.status) {
      case RequestStatus.pending:
        bgColor = Colors.orange;
        label = 'Pending Approval';
        icon = Icons.pending_outlined;
        break;
      case RequestStatus.approved:
        bgColor = Colors.green;
        label = 'Approved';
        icon = Icons.check_circle_outline;
        break;
      case RequestStatus.rejected:
        bgColor = Colors.red;
        label = 'Rejected';
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard() {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar
            ProfileCircle(
              photoUrl: request.employeePhoto,
              size: 35,
            ),
            const SizedBox(width: 16),

            // Employee Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.employeeName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.store, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        request.employeeBranchName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        request.employeePhone,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
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

  Widget _buildDetailsCard(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(request.type.icon, color: ColorsManger.primary),
                const SizedBox(width: 8),
                const Text(
                  'Request Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Type-specific details
            ..._buildTypeSpecificDetails(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTypeSpecificDetails(BuildContext context) {
    switch (request.type) {
      case RequestType.annualLeave:
        return _buildAnnualLeaveDetails();
      case RequestType.sickLeave:
        return _buildSickLeaveDetails(context);
      case RequestType.extraHours:
        return _buildExtraHoursDetails();
      case RequestType.coverageShift:
        return _buildCoverageShiftDetails();
      case RequestType.attend:
        return _buildAttendDetails();
      case RequestType.permission:
        return _buildPermissionDetails();
    }
  }

  List<Widget> _buildAnnualLeaveDetails() {
    final details = AnnualLeaveDetails.fromJson(request.details);

    return [
      _buildDetailRow(
        'Start Date',
        DateFormat('EEEE, MMM dd, yyyy').format(details.startDate),
        Icons.calendar_today,
        Colors.blue,
      ),
      const SizedBox(height: 12),
      _buildDetailRow(
        'End Date',
        DateFormat('EEEE, MMM dd, yyyy').format(details.endDate),
        Icons.event,
        Colors.blue,
      ),
      const SizedBox(height: 12),
      _buildDetailRow(
        'Duration',
        '${details.totalDays} day${details.totalDays > 1 ? 's' : ''}',
        Icons.access_time,
        Colors.orange,
      ),
    ];
  }

  List<Widget> _buildSickLeaveDetails(BuildContext context) {
    final details = SickLeaveDetails.fromJson(request.details);
    final duration = details.endDate.difference(details.startDate).inDays + 1;

    return [
      _buildDetailRow(
        'Start Date',
        DateFormat('EEEE, MMM dd, yyyy').format(details.startDate),
        Icons.calendar_today,
        Colors.orange,
      ),
      const SizedBox(height: 12),
      _buildDetailRow(
        'End Date',
        DateFormat('EEEE, MMM dd, yyyy').format(details.endDate),
        Icons.event,
        Colors.orange,
      ),
      const SizedBox(height: 12),
      _buildDetailRow(
        'Duration',
        '$duration day${duration > 1 ? 's' : ''}',
        Icons.access_time,
        Colors.orange,
      ),
      const SizedBox(height: 12),
      _buildPrescriptionRow(details.prescription,context),
    ];
  }

  List<Widget> _buildExtraHoursDetails() {
    final details = ExtraHoursDetails.fromJson(request.details);

    return [
      _buildDetailRow(
        'Date',
        DateFormat('EEEE, MMM dd, yyyy').format(details.date),
        Icons.calendar_today,
        Colors.purple,
      ),
      const SizedBox(height: 12),
      _buildDetailRow(
        'Extra Hours',
        '${details.hours} hour${details.hours > 1 ? 's' : ''}',
        Icons.schedule,
        Colors.purple,
      ),
    ];
  }

  List<Widget> _buildCoverageShiftDetails() {
    final details = CoverageShiftDetails.fromJson(request.details);

    return [
      _buildDetailRow(
        'Date',
        DateFormat('EEEE, MMM dd, yyyy').format(details.date),
        Icons.calendar_today,
        Colors.teal,
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.swap_horiz, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Shift Coverage Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSwapInfo(
              'Employee',
              request.employeeName,
              request.employeeBranchName,
              Icons.person,
            ),
            const SizedBox(height: 8),
            const Icon(Icons.swap_vert, color: Colors.teal),
            const SizedBox(height: 8),
            _buildSwapInfo(
              'Will swap with',
              details.peerEmployeeName,
              details.peerBranchName,
              Icons.person_outline,
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildSwapInfo(String label, String name, String branch, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.teal),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                branch,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAttendDetails() {
    final details = AttendDetails.fromJson(request.details);

    return [
      _buildDetailRow(
        'Forgot to punch on',
        DateFormat('EEEE, MMM dd, yyyy').format(details.date),
        Icons.fingerprint,
        Colors.green,
      ),
    ];
  }

  List<Widget> _buildPermissionDetails() {
    final details = PermissionDetails.fromJson(request.details);

    return [
      _buildDetailRow(
        'Date',
        DateFormat('EEEE, MMM dd, yyyy').format(details.date),
        Icons.calendar_today,
        Colors.indigo,
      ),
      const SizedBox(height: 12),
      _buildDetailRow(
        'Early Leave Duration',
        '${details.hours} hour${details.hours > 1 ? 's' : ''}',
        Icons.logout,
        Colors.indigo,
      ),
    ];
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionRow(String url,BuildContext context) {
    return InkWell(
      onTap: () async {
        // Show prescription in a dialog or navigate to image viewer
        // For now, just show a toast
        // You can implement a full-screen image viewer here
        try {
          // Otherwise, try to read URL from existing request details
          if (url.isEmpty) {
            await defToast2(
            context: context,
            msg: 'No prescription available to preview',
            dialogType: DialogType.warning,
            );
            return;
          }

          final uri = Uri.tryParse(url);
          if (uri == null) {
            throw 'Invalid prescription URL';
          }

          if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
        throw 'Cannot open prescription URL';
        }
        } catch (e) {
        if (!context.mounted) return;
        await defToast2(
        context: context,
        msg: 'Failed to preview prescription: $e',
        dialogType: DialogType.error,
        );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.attachment, color: Colors.orange, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Medical Prescription',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tap to view document',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, color: Colors.orange, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: Colors.grey[700]),
                const SizedBox(width: 8),
                const Text(
                  'Additional Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                request.notes!,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Colors.grey[700]),
                const SizedBox(width: 8),
                const Text(
                  'Timeline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Created At
            _buildTimelineItem(
              'Request Submitted',
              request.createdAt!,
              Icons.send,
              Colors.blue,
              isFirst: true,
            ),

            // Processed At (if approved or rejected)
            if (request.status != RequestStatus.pending &&
                request.processedByName != null &&
                request.updatedAt != null) ...[
              const SizedBox(height: 16),
              _buildTimelineItem(
                request.status == RequestStatus.approved
                    ? 'Approved by ${request.processedByName}'
                    : 'Rejected by ${request.processedByName}',
                request.updatedAt!,
                request.status == RequestStatus.approved
                    ? Icons.check_circle
                    : Icons.cancel,
                request.status.color,
                isLast: true,
              ),
            ]
            // Updated At (if different from created but no processedByName)
            else if (request.updatedAt != null &&
                request.updatedAt!.difference(request.createdAt!).inSeconds > 5) ...[
              const SizedBox(height: 16),
              _buildTimelineItem(
                'Updated',
                request.updatedAt!,
                Icons.edit,
                Colors.orange,
                isLast: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    DateTime dateTime,
    IconData icon,
    Color color, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16,),
      child: Row(
        children: [
          Expanded(
            child: FloatingActionButton.extended(
              heroTag: 'reject',
              foregroundColor: Colors.white,
              onPressed: () => _rejectRequest(context),
              backgroundColor: Colors.red,
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FloatingActionButton.extended(
              heroTag: 'approve',
              foregroundColor: Colors.white,
              onPressed: () => _approveRequest(context),
              backgroundColor: Colors.green,
              icon: const Icon(Icons.check),
              label: const Text('Approve'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRequest(BuildContext context) async {
    await AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: 'Approve Request',
      desc: 'Are you sure you want to approve this ${request.type.enName}?',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await getIt<RequestCubit>().approveRequest(request);


      },
    ).show();

  }

  Future<void> _rejectRequest(BuildContext context) async {
    await AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Reject Request',
      desc: 'Are you sure you want to reject this ${request.type.enName}?',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await getIt<RequestCubit>().rejectRequest(request);

      },
    ).show();



  }


}

