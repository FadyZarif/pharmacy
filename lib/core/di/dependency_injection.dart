import 'package:get_it/get_it.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/features/employee/logic/employee_layout_cubit.dart';
import 'package:pharmacy/features/login/logic/login_cubit.dart';
import 'package:pharmacy/features/repair/logic/repair_cubit.dart';
import 'package:pharmacy/features/report/logic/edit_report_cubit.dart';
import 'package:pharmacy/features/report/logic/shift_report_cubit.dart';
import 'package:pharmacy/features/report/logic/view_reports_cubit.dart';
import 'package:pharmacy/features/request/logic/request_cubit.dart';
import 'package:pharmacy/features/request/data/services/coverage_shift_service.dart';

import '../../features/salary/logic/salary_cubit.dart';
import '../../features/user/logic/users_cubit.dart';
import '../../features/job_opportunity/logic/job_opportunity_cubit.dart';
import '../services/notification_service.dart';



final getIt = GetIt.instance;

Future setupGetIt() async{


  ///Auth
  getIt.registerFactory<LoginCubit>(()=>LoginCubit());

  ///Employee
  getIt.registerLazySingleton<EmployeeLayoutCubit>(()=>EmployeeLayoutCubit());

  ///Request
  getIt.registerLazySingleton<RequestCubit>(()=>(currentUser.isManagement? (RequestCubit()..fetchManagementRequests()): RequestCubit()..fetchRequests()));

  ///Coverage Shift Service
  getIt.registerLazySingleton<CoverageShiftService>(()=>CoverageShiftService());

  ///Repair
  getIt.registerLazySingleton<RepairCubit>(()=>RepairCubit());

  ///Salary
  getIt.registerLazySingleton<SalaryCubit>(()=>SalaryCubit());

  ///Shift Report
  getIt.registerFactory<ShiftReportCubit>(()=>ShiftReportCubit());

  ///View Reports (Management)
  getIt.registerFactory<ViewReportsCubit>(()=>ViewReportsCubit());
  getIt.registerFactory<EditReportCubit>(()=>EditReportCubit());

  ///User
  getIt.registerLazySingleton<UsersCubit>(()=>UsersCubit());

  ///Job Opportunity
  getIt.registerLazySingleton<JobOpportunityCubit>(()=>JobOpportunityCubit());

  ///Notification Service
  getIt.registerLazySingleton<NotificationService>(()=>NotificationService());


}
