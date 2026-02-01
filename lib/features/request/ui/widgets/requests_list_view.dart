import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/request/data/models/request_model.dart';
import 'package:pharmacy/features/request/logic/request_cubit.dart';
import 'package:pharmacy/features/request/logic/request_state.dart';
import 'package:pharmacy/features/request/ui/request_details_screen.dart';

import '../../../../core/di/dependency_injection.dart';
import '../add_request_screen_unified.dart';

class RequestsListView extends StatelessWidget {
  const RequestsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RequestCubit, RequestState>(
      buildWhen: (_, current) {
        return current is FetchRequestsSuccess ||
               current is FetchRequestsLoading ||
               current is FetchRequestsFailure ||
               current is DeleteRequestSuccess;
      },
      builder: (context, state) {
        final cubit = getIt<RequestCubit>();

        if (state is FetchRequestsLoading && cubit.requests.isEmpty) {
          // Show loading only if no data is available yet
          return const Center(child: CircularProgressIndicator());
        } else if (state is FetchRequestsFailure && cubit.requests.isEmpty) {
          // Show error only if no data is available
          return Center(child: Text('Error: ${state.error}',style: TextStyle(color: Colors.red),));
        }

        // Show data (or empty state if no requests)
        final requests = cubit.requests;
        if (requests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'No requests found.',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final request = requests[index];
            final borderRadius = BorderRadius.circular(18);

            return Dismissible(
              key: ValueKey(request.id),
              direction: DismissDirection.horizontal,

                // خلفية عند السحب من اليمين لليسار (شمال) = حذف
                background: ClipRRect(
                  borderRadius: borderRadius,
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.green,
                    child: const Row(
                      children: [
                        Icon(Icons.edit, color: Colors.white),
                        SizedBox(width: 8),
                        Text('تعديل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),

                // خلفية عند السحب من اليسار لليمين (شمال) = حذف
                secondaryBackground: ClipRRect(
                  borderRadius: borderRadius,
                  child: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.red,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('حذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                        SizedBox(width: 8),
                        Icon(Icons.delete, color: Colors.white),
                      ],
                    ),
                  ),
                ),

                // نستخدم confirmDismiss للتمييز بين يمين/شمال وتنفيذ الدالة فقط
                confirmDismiss: (dir) async {

                  if(request.status != RequestStatus.pending){
                    // لا تسمح بالتعديل أو الحذف إذا لم يكن الطلب في حالة انتظار
                   defToast2(context: context, msg: 'لا يمكن تعديل أو حذف الطلبات التي تم الموافقة عليها أو رفضها.', dialogType: DialogType.error);
                    return false;
                  }

                  if (dir == DismissDirection.startToEnd) {
                    // يمين = تعديل
                    // onEditRequest(request);
                    // TODO: اكتب منطق التعديل
                    onTapRequestItem(context, request,false);
                  } else {
                    // شمال = حذف
                    // onDeleteRequest(request);
                    // TODO: اكتب منطق الحذف (ممكن تعرض Dialog تأكيد)
                    AwesomeDialog(
                      context: context,
                      dialogType: DialogType.question,
                      headerAnimationLoop: false,
                      animType: AnimType.bottomSlide,
                      title: 'Sure Delete?',
                      desc: 'Are you sure you want to delete this request?',
                      btnCancelOnPress: () {},
                      btnOkOnPress: () {
                        // نفذ الحذف
                        context.read<RequestCubit>().deleteRequest(request.id);
                      },
                    ).show();
                  }
                  // رجّع false علشان العنصر ما يتمسحش تلقائيًا من الليست
                  return false;
                },

              child: _PanelCard(
                borderRadius: borderRadius,
                child: InkWell(
                  borderRadius: borderRadius,
                  onTap: () => onTapRequestItem(context, request, true),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatusPill(status: request.status),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.type.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.black.withValues(alpha: 0.55),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      DateFormat.yMMMd().add_jm().format(request.createdAt!),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black.withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (request.status != RequestStatus.pending &&
                                  request.processedByName != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '${request.status == RequestStatus.approved ? 'Approved' : 'Rejected'} by ${request.processedByName}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: request.status.color,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
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
  final BorderRadius borderRadius;

  const _PanelCard({
    required this.child,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        border: Border.all(color: Colors.grey.withValues(alpha: 0.16)),
        boxShadow: _panelShadow(),
      ),
      child: child,
    );
  }
}

class _StatusPill extends StatelessWidget {
  final RequestStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg = status == RequestStatus.approved
        ? Colors.green
        : status == RequestStatus.rejected
            ? Colors.red
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        status.name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

void onTapRequestItem(BuildContext context, RequestModel request, bool isReadOnly) {
  HapticFeedback.mediumImpact();
  if(isReadOnly){
    navigateTo(context, RequestDetailsScreen(request: request,canManage: false,));
    return;
  }else{

  }
  navigateTo(context, AddRequestScreenUnified(
    requestType: request.type,
    existingRequest: request,
    isReadOnly: isReadOnly,
  ));
}