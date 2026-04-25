import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/quarterly_incentives/data/models/employee_quarterly_incentive_model.dart';
import 'package:pharmacy/features/quarterly_incentives/data/models/quarterly_incentive_period_model.dart';
import 'package:pharmacy/features/quarterly_incentives/logic/quarterly_incentives_cubit.dart';
import 'package:pharmacy/features/quarterly_incentives/logic/quarterly_incentives_state.dart';

class QuarterlyIncentivesScreen extends StatefulWidget {
  const QuarterlyIncentivesScreen({super.key});

  @override
  State<QuarterlyIncentivesScreen> createState() =>
      _QuarterlyIncentivesScreenState();
}

class _QuarterlyIncentivesScreenState extends State<QuarterlyIncentivesScreen> {
  late final QuarterlyIncentivesCubit _cubit;
  String? _selectedPeriodKey;
  List<QuarterlyIncentivePeriodModel> _periods = [];

  @override
  void initState() {
    super.initState();
    _cubit = QuarterlyIncentivesCubit()..fetchPeriods();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return BlocProvider.value(
      value: _cubit,
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
                ),
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              centerTitle: true,
              title: const Text(
                'الحوافز',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ),
        ),
        body: BlocConsumer<QuarterlyIncentivesCubit, QuarterlyIncentivesState>(
          listener: (context, state) {
            if (state is QuarterlyIncentivesPeriodsLoaded) {
              setState(() {
                _periods = state.periods;
                if (_periods.isEmpty) {
                  _selectedPeriodKey = null;
                  return;
                }
                final valid = _selectedPeriodKey != null &&
                    _periods.any((p) => p.periodKey == _selectedPeriodKey);
                if (!valid) {
                  _selectedPeriodKey = _periods.first.periodKey;
                }
              });
              if (_periods.isNotEmpty && _selectedPeriodKey != null) {
                _cubit.fetchMyIncentiveForPeriod(_selectedPeriodKey!);
              }
            }
          },
          builder: (context, state) {
            if (state is QuarterlyIncentivesLoading &&
                _periods.isEmpty &&
                _selectedPeriodKey == null) {
              return Padding(
                padding: EdgeInsets.only(top: topPad + kToolbarHeight + 40),
                child: const Center(
                  child: CircularProgressIndicator(color: ColorsManger.primary),
                ),
              );
            }
            if (state is QuarterlyIncentivesError && _periods.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(24 + topPad),
                child: Center(
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (_periods.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(24 + topPad),
                child: Center(
                  child: Text(
                    'لا توجد فترات مرفوعة بعد.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                topPad + kToolbarHeight + 12,
                16,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _periodDropdown(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildBody(state),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _periodDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedPeriodKey,
          items: _periods.map((p) {
            final uploaded = p.uploadedAt != null
                ? DateFormat('dd/MM/yyyy').format(p.uploadedAt!)
                : '';
            return DropdownMenuItem(
              value: p.periodKey,
              child: Text(
                '${p.displayPeriod} — ${p.uploadedSheetName}'
                '${uploaded.isEmpty ? '' : ' ($uploaded)'}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (key) {
            if (key == null) return;
            setState(() => _selectedPeriodKey = key);
            _cubit.fetchMyIncentiveForPeriod(key);
          },
        ),
      ),
    );
  }

  Widget _buildBody(QuarterlyIncentivesState state) {
    if (state is QuarterlyIncentivesLoading) {
      return const Center(
        child: CircularProgressIndicator(color: ColorsManger.primary),
      );
    }
    if (state is QuarterlyIncentivesError) {
      return Center(child: Text(state.message, textAlign: TextAlign.center));
    }
    if (state is QuarterlyIncentivesEmpty) {
      return Center(
        child: Text(
          'لا توجد بيانات لك في فترة ${state.period.periodKey}.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      );
    }
    if (state is QuarterlyIncentiveSingleLoaded) {
      return SingleChildScrollView(
        child: _IncentiveDetails(data: state.bundle.data, period: state.bundle.period),
      );
    }
    return const SizedBox.shrink();
  }
}

class _IncentiveDetails extends StatelessWidget {
  final EmployeeQuarterlyIncentiveModel data;
  final QuarterlyIncentivePeriodModel period;

  const _IncentiveDetails({
    required this.data,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section(
          'الفترة',
          [
            _row('المفتاح', period.periodKey),
            _row('الشيت المرفوع', period.uploadedSheetName),
          ],
        ),
        const SizedBox(height: 12),
        _section(
          'بيانات الموظف',
          [
            _row('الاسم', data.nameArabic),
            _row('Name', data.nameEnglish),
            _row('كود الصيدلية', data.pharmacyCode),
            _row('اسم الصيدلية', data.pharmacyName),
            _row('ACC', data.acc),
          ],
        ),
        const SizedBox(height: 12),
        _section(
          'مرتب وحوافز أساسية',
          [
            _row('المرتب', data.basicSalary),
            _row('الحافز الشهري', data.monthlyIncentive),
            _row('مكافئات', data.bonuses),
            _row('الحافز الإداري', data.adminIncentive),
            _row('العيديات', data.eideya),
            _row('خصم عجز الشيفتات الربع سنوى', data.quarterlyShiftDeficitDeduction),
            _row('الإجمالي', data.lineTotal),
          ],
        ),
        const SizedBox(height: 12),
        _section(
          'تبديل وإكسبير',
          [
            _row('حافز الليسته', data.listIncentive),
            _row('زيادة الريستات', data.restIncrease),
            _row('تبديل آجل', data.creditExchange),
            _row('تبديل نقدي', data.cashExchange),
            _row('إجمالي التبديل', data.totalExchange),
            _row('0.02 / نسبة', data.rate02),
            _row('الأكسبير', data.expiryAmount),
            _row('25% من الأكسبير', data.expiry25Percent),
          ],
        ),
        const SizedBox(height: 12),
        _section(
          'جرد',
          [
            _row('تعديل كميات أصناف', data.quantityAdjustments),
            _row('كود زيادات الجرد', data.inventoryIncreaseCode),
            _row('القيمة النهائية للجرد', data.inventoryFinalValue),
            _row('ما يتم ترحيله', data.deficitCarryover),
            _row('ما يضاف أو يُخصم على الفرع', data.branchAdjustment),
          ],
        ),
        const SizedBox(height: 12),
        _section(
          'الإجماليات ونصيب الفرد',
          [
            _row('إجمالى ±', data.totalPlusMinus),
            _row('عدد موظفي الفرع', data.branchEmployeeCount),
            _row('نصيب الفرد', data.perCapitaShare),
            _row('المستحق للعامل', data.netDue,
                emphasize: true),
          ],
        ),
        if (data.notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _section('ملاحظات', [_row('', data.notes)]),
        ],
      ],
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasize = false}) {
    if (label.isEmpty && value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.55),
                  fontSize: 13,
                ),
              ),
            ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
                fontSize: emphasize ? 16 : 14,
                color: emphasize ? ColorsManger.primary : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
