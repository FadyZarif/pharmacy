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
import 'package:pharmacy/features/request/ui/add_attend_request_screen.dart';
import 'package:pharmacy/features/request/ui/add_coverage_request_screen.dart';
import 'package:pharmacy/features/request/ui/add_extra_request_screen.dart';
import 'package:pharmacy/features/request/ui/add_permission_request_screen.dart';
import 'package:pharmacy/features/request/ui/add_request_screen.dart';
import 'package:pharmacy/features/request/ui/add_sick_request_screen.dart';

import '../../../../core/di/dependency_injection.dart';
import '../add_annual_request_screen.dart';

class RequestsListView extends StatelessWidget {
  const RequestsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RequestCubit, RequestState>(
      buildWhen: (_, current) {
        return current is FetchRequestsSuccess || current is FetchRequestsLoading || current is FetchRequestsFailure;
      },
      builder: (context, state) {
        if (state is FetchRequestsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is FetchRequestsFailure) {
          return Center(child: Text('Error: ${state.error}',style: TextStyle(color: Colors.red),));
        } else if (state is FetchRequestsSuccess) {
          final requests = getIt<RequestCubit>().requests;
          if (requests.isEmpty) {
            return Expanded(
              child: const Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No requests found.'),
                ],
              )),
            );
          }
          return Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                final borderRadius = BorderRadius.circular(16);

                return Dismissible(
                  key: ValueKey(request.id ?? index),
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
                          Text('تعديل', style: TextStyle(color: Colors.white)),
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
                          Text('حذف', style: TextStyle(color: Colors.white)),
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

                  child: Card(
                    elevation: 2,
                    shadowColor: Colors.black38,
                    child: ListTile(
                      title: Text(
                        request.type.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        DateFormat.yMMMd().add_jm().format(request.createdAt!),
                      ),
                      onTap: () => onTapRequestItem(context, request, true),
                      trailing: Container(
                        width: 70,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: request.status == RequestStatus.approved
                              ? Colors.green
                              : request.status == RequestStatus.rejected
                              ? Colors.red
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          request.status.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: borderRadius,
                      ),
                      tileColor: ColorsManger.cardColor,
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 5),
            ),
          );

        }
        return const SizedBox.shrink();
      },
    );
  }
}

void onTapRequestItem(BuildContext context, RequestModel request,bool isReadOnly){
  print('isReadOnly $isReadOnly');
  HapticFeedback.mediumImpact();
  final Widget body;
  switch (request.type) {
    case RequestType.annualLeave:
      body = AddAnnualRequestScreen(requestModel: request,isReadOnly: isReadOnly,);
      break;
    case RequestType.sickLeave:
      body = AddSickRequestScreen(requestModel: request,isReadOnly: isReadOnly,);
      break;
    case RequestType.extraHours:
      body = AddExtraRequestScreen(requestModel: request,isReadOnly: isReadOnly,);
      break;
    case RequestType.coverageShift:
      body = AddCoverageRequestScreen(requestModel: request,isReadOnly: isReadOnly,);
      break;
    case RequestType.attend:
      body = AddAttendRequestScreen(requestModel: request,isReadOnly: isReadOnly,);
      break;
    case RequestType.permission:
      body = AddPermissionRequestScreen(requestModel: request,isReadOnly: isReadOnly,);
      break;
  }
  navigateTo(context, AddRequestScreen(body: body, requestCubit: context.read<RequestCubit>(),),);
}