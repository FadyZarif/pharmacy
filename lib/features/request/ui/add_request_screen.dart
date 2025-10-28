import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/helpers/constants.dart';
import '../logic/request_cubit.dart';
import '../logic/request_state.dart';

class AddRequestScreen extends StatelessWidget {
  final Widget body;
  final RequestCubit requestCubit ;
  const AddRequestScreen({super.key, required this.body, required this.requestCubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
  value: getIt<RequestCubit>(),
  child: BlocListener<RequestCubit, RequestState>(
    listenWhen: (_,current)=>current is AddRequestLoading || current is AddRequestSuccess|| current is AddRequestFailure ,
      listener: (context, state) async {
        if (state is AddRequestLoading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          if (state is AddRequestSuccess) {
            await defToast2(context: context, msg: 'request has been submitted successfully', dialogType: DialogType.success);

          } else if (state is AddRequestFailure) {
            await defToast2(context: context, msg: state.error, dialogType: DialogType.error);
          }
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child:body,
    ),
);
  }
}
