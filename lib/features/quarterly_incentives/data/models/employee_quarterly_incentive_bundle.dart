import 'package:pharmacy/features/quarterly_incentives/data/models/employee_quarterly_incentive_model.dart';
import 'package:pharmacy/features/quarterly_incentives/data/models/quarterly_incentive_period_model.dart';

class EmployeeQuarterlyIncentiveBundle {
  final QuarterlyIncentivePeriodModel period;
  final EmployeeQuarterlyIncentiveModel data;

  EmployeeQuarterlyIncentiveBundle({
    required this.period,
    required this.data,
  });
}
