
import 'package:get_it/get_it.dart';
import 'package:pharmacy/features/employee/logic/employee_layout_cubit.dart';
import 'package:pharmacy/features/login/logic/login_cubit.dart';
import 'package:pharmacy/features/repair/logic/repair_cubit.dart';
import 'package:pharmacy/features/report/logic/shift_report_cubit.dart';
import 'package:pharmacy/features/request/logic/request_cubit.dart';



final getIt = GetIt.instance;

Future setupGetIt() async{


  ///Auth
  getIt.registerLazySingleton<LoginCubit>(()=>LoginCubit());

  ///Employee
  getIt.registerLazySingleton<EmployeeLayoutCubit>(()=>EmployeeLayoutCubit());

  ///Request
  getIt.registerLazySingleton<RequestCubit>(()=>RequestCubit());

  ///Repair
  getIt.registerLazySingleton<RepairCubit>(()=>RepairCubit());

  ///Shift Report
  getIt.registerFactory<ShiftReportCubit>(()=>ShiftReportCubit());




}
