import 'dart:math' as math;

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/employee/logic/employee_layout_cubit.dart';
import 'package:pharmacy/features/login/ui/login_screen.dart';
import 'package:pharmacy/features/repair/logic/repair_cubit.dart';
import 'package:pharmacy/features/request/data/services/coverage_shift_service.dart';
import 'package:pharmacy/features/request/logic/request_cubit.dart';
import 'package:pharmacy/features/request/logic/request_state.dart';
import 'package:pharmacy/features/request/ui/add_request_screen_unified.dart';
import 'package:pharmacy/features/request/ui/manage_requests_screen.dart';
import 'package:pharmacy/features/request/ui/widgets/requests_list_view.dart';
import 'package:pharmacy/features/salary/logic/salary_cubit.dart';
import 'package:pharmacy/features/user/logic/users_cubit.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/widgets/profile_circle.dart';
import '../../request/data/models/request_model.dart';
import '../../job_opportunity/ui/view_job_opportunities_screen.dart';
import '../../job_opportunity/logic/job_opportunity_cubit.dart';
import 'widgets/request_tile.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<RequestCubit>(),
      child: Scaffold(
        backgroundColor: ColorsManger.primaryBackground,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.50),
              border: Border(
                bottom: BorderSide(
                  color: ColorsManger.primary.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
            ),
            child: AppBar(
              foregroundColor: ColorsManger.primary,
              title: Text(
                'Dashboard',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.78),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              actions: [
                if (currentUser.role == Role.subManager &&
                    currentUser.hasRequestsPermission)
                  IconButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      navigateTo(context, const ManageRequestsScreen());
                    },
                    icon: Icon(
                      Icons.event_note,
                      color: ColorsManger.primary.withValues(alpha: 0.95),
                    ),
                    tooltip: 'Manage Requests',
                  ),
                IconButton(
                  onPressed: () => _showLogoutDialog(context),
                  icon: Icon(
                    Icons.logout,
                    color: ColorsManger.primary.withValues(alpha: 0.95),
                  ),
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            const _AnimatedDashboardBackground(),
            RefreshIndicator(
              color: ColorsManger.primary,
              onRefresh: () async {
                final ok = await checkIsLogged();
                if (ok) {
                  setState(() {
                    getIt<RequestCubit>().fetchRequests();
                  });
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + kToolbarHeight + 12,
                    16,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _UserHeaderCard(
                        name: currentUser.name,
                        branchName: currentUser.currentBranch.name,
                        photoUrl: currentUser.photoUrl,
                        onView: () => context
                            .read<EmployeeLayoutCubit>()
                            .changeBottomNav(4),
                      ),
                      const SizedBox(height: 18),

                      _SectionCard(
                        title: 'Statistics',
                        subtitle:
                            'Quick view of your balances and pending requests',
                        icon: Icons.analytics,
                        child: LayoutBuilder(
                          builder: (context, c) {
                            final w = c.maxWidth;
                            final columns = w >= 900 ? 3 : (w >= 560 ? 3 : 2);
                            const spacing = 12.0;
                            final cardWidth =
                                (w - (spacing * (columns - 1))) / columns;
                            // Keep stat tiles visually consistent (same height) across different content lengths.
                            final tileHeight = w >= 560 ? 90.0 : 86.0;
                            final pendingTileWidth = columns == 2
                                ? (cardWidth * 2 + spacing)
                                : cardWidth;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  height: tileHeight,
                                  child: _StatCard(
                                    compact: true,
                                    icon: Icons.beach_access,
                                    iconColor: Colors.green,
                                    title: 'Vacation Balance',
                                    value: currentUser.vocationBalance,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  height: tileHeight,
                                  child: _StatCard(
                                    compact: true,
                                    icon: Icons.schedule,
                                    iconColor: Colors.blue,
                                    title: 'Overtime',
                                    value: '${currentUser.overTimeHours}h',
                                  ),
                                ),
                                SizedBox(
                                  width: pendingTileWidth,
                                  height: tileHeight,
                                  child: BlocBuilder<RequestCubit, RequestState>(
                                    buildWhen: (_, current) =>
                                        current is FetchRequestsSuccess,
                                    builder: (context, state) {
                                      return _StatCard(
                                        compact: true,
                                        icon: Icons.pending_actions,
                                        iconColor: Colors.orange,
                                        title: 'Pending Requests',
                                        value:
                                            '${getIt<RequestCubit>().pendingRequestsCount}',
                                        badge: true,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Job Opportunities',
                        subtitle:
                            'Browse open roles and apply directly from the app.',
                        icon: Icons.work_outline,
                        trailing: _PrimarySmallButton(
                          label: 'View All',
                          icon: Icons.arrow_forward,
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            navigateTo(
                              context,
                              BlocProvider.value(
                                value: getIt<JobOpportunityCubit>(),
                                child: const ViewJobOpportunitiesScreen(),
                              ),
                            );
                          },
                        ),
                        child: _InfoCard(
                          icon: Icons.campaign,
                          title: 'Check what’s new',
                          subtitle: 'New openings are posted regularly.',
                        ),
                      ),

                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Requests',
                        subtitle: 'Create and track your requests',
                        icon: Icons.event_note,
                        trailing: _PrimarySmallButton(
                          label: 'New',
                          icon: Icons.add,
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            showNewRequestSheet(context);
                          },
                        ),
                        child: const RequestsListView(),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      title: 'Logout',
      desc: 'are you sure you want to logout?',
      btnOkText: 'logout',
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        _logout(context);
      },
    ).show();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Reset all lazy singletons in GetIt (but keep factories)
      if (getIt.isRegistered<EmployeeLayoutCubit>()) {
        await getIt.resetLazySingleton<EmployeeLayoutCubit>();
      }
      if (getIt.isRegistered<RequestCubit>()) {
        await getIt.resetLazySingleton<RequestCubit>();
      }
      if (getIt.isRegistered<CoverageShiftService>()) {
        await getIt.resetLazySingleton<CoverageShiftService>();
      }
      if (getIt.isRegistered<RepairCubit>()) {
        await getIt.resetLazySingleton<RepairCubit>();
      }
      if (getIt.isRegistered<SalaryCubit>()) {
        await getIt.resetLazySingleton<SalaryCubit>();
      }
      if (getIt.isRegistered<UsersCubit>()) {
        await getIt.resetLazySingleton<UsersCubit>();
      }

      // Update isLogged flag
      isLogged = false;

      // Pop loading dialog
      if (context.mounted) Navigator.pop(context);

      // Navigate to login screen
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (ctx) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Pop loading dialog if still showing
      if (context.mounted) Navigator.pop(context);

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

Future<void> showNewRequestSheet(BuildContext context) async {
  final items = <RequestItem>[
    RequestItem(
      type: RequestType.annualLeave,
      title: 'Annual Leave',
      subtitle: 'طلب إجازة',
      icon: Icons.flight_takeoff,
      screen: const AddRequestScreenUnified(
        requestType: RequestType.annualLeave,
      ),
    ),
    RequestItem(
      type: RequestType.sickLeave,
      title: 'Sick Leave',
      subtitle: 'طلب إجازة مرضية',
      icon: Icons.local_hospital,
      screen: const AddRequestScreenUnified(requestType: RequestType.sickLeave),
    ),
    RequestItem(
      type: RequestType.extraHours,
      title: 'Extra Hours',
      subtitle: 'طلب ساعات إضافية',
      icon: Icons.access_time,
      screen: const AddRequestScreenUnified(
        requestType: RequestType.extraHours,
      ),
    ),
    RequestItem(
      type: RequestType.coverageShift,
      title: 'Coverage Shift',
      subtitle: 'طلب تغطية وردية',
      icon: Icons.swap_horiz,
      screen: const AddRequestScreenUnified(
        requestType: RequestType.coverageShift,
      ),
    ),
    RequestItem(
      type: RequestType.attend,
      title: 'Attend',
      subtitle: 'طلب حضور',
      icon: Icons.how_to_reg,
      screen: const AddRequestScreenUnified(requestType: RequestType.attend),
    ),
    RequestItem(
      type: RequestType.permission,
      title: 'Permission',
      subtitle: 'تأخير أو انصراف مبكر',
      icon: Icons.exit_to_app,
      screen: const AddRequestScreenUnified(
        requestType: RequestType.permission,
      ),
    ),
  ];

  await showModalBottomSheet(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: false,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'إيه نوع طلبك؟',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...items.map(
                (item) => RequestTile(
                  item: item,
                  requestCubit: getIt<RequestCubit>(),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      );
    },
  );
}

class _AnimatedDashboardBackground extends StatefulWidget {
  const _AnimatedDashboardBackground();

  @override
  State<_AnimatedDashboardBackground> createState() =>
      _AnimatedDashboardBackgroundState();
}

class _AnimatedDashboardBackgroundState
    extends State<_AnimatedDashboardBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  static const _bgAsset = 'assets/images/dashboard_bg.png';

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value; // 0..1
        final wave = math.sin(t * math.pi * 2); // -1..1
        final wave2 = math.cos((t * math.pi * 2) + 1.2);

        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage(_bgAsset),
              fit: BoxFit.cover,
              alignment: Alignment.center,
              // Keep it subtle so content stays readable.
              colorFilter: ColorFilter.mode(
                Colors.white.withValues(alpha: 0.55),
                BlendMode.srcATop,
              ),
            ),
          ),
          child: Stack(
            children: [
              _AnimatedGlowBlob(
                baseAlignment: const Alignment(-1.05, -0.85),
                radius: 180,
                color: const Color(0x0300B4D8),
                dx: 6 * wave,
                dy: 6 * wave2,
              ),
              _AnimatedGlowBlob(
                baseAlignment: const Alignment(1.10, -0.25),
                radius: 220,
                color: const Color(0x03008AC7),
                dx: -6 * wave2,
                dy: 6 * wave,
              ),
              _AnimatedGlowBlob(
                baseAlignment: const Alignment(0.15, 1.10),
                radius: 260,
                color: const Color(0x0200B4D8),
                dx: 5 * wave2,
                dy: -5 * wave,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Alignment alignment;
  final double radius;
  final Color color;

  const _GlowBlob({
    required this.alignment,
    required this.radius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: radius,
        height: radius,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: radius * 0.38,
              spreadRadius: radius * 0.06,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedGlowBlob extends StatelessWidget {
  final Alignment baseAlignment;
  final double radius;
  final Color color;
  final double dx;
  final double dy;

  const _AnimatedGlowBlob({
    required this.baseAlignment,
    required this.radius,
    required this.color,
    required this.dx,
    required this.dy,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: baseAlignment,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: _GlowBlob(
          alignment: Alignment.center,
          radius: radius,
          color: color,
        ),
      ),
    );
  }
}

List<BoxShadow> _cardShadow() => [
  BoxShadow(
    color: ColorsManger.primary.withValues(alpha: 0.18),
    blurRadius: 22,
    offset: const Offset(0, 12),
  ),
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.06),
    blurRadius: 18,
    offset: const Offset(0, 10),
  ),
];

class _UserHeaderCard extends StatelessWidget {
  final String name;
  final String branchName;
  final String? photoUrl;
  final VoidCallback onView;

  const _UserHeaderCard({
    required this.name,
    required this.branchName,
    required this.photoUrl,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.16)),
        boxShadow: _cardShadow(),
      ),
      child: Row(
        children: [
          ProfileCircle(photoUrl: photoUrl, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.store,
                      size: 14,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        branchName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: onView,
            icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
            label: const Text('View'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManger.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimarySmallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimarySmallButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorsManger.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.16)),
        boxShadow: _cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ColorsManger.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: ColorsManger.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final bool badge;
  final bool compact;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.badge = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // On very narrow widths, switch to a vertical layout to avoid overflow.
        final isVeryNarrow = c.maxWidth < 140;

        Widget badgeChip() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.22)),
          ),
          child: const Text(
            'Pending',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.orange,
            ),
          ),
        );

        final iconBox = Container(
          width: compact ? 40 : 44,
          height: compact ? 40 : 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor),
        );

        return Container(
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.16)),
            boxShadow: compact ? null : _cardShadow(),
          ),
          child: isVeryNarrow
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        iconBox,
                        if (badge) ...[const Spacer(), badgeChip()],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    iconBox,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.black.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              if (badge) ...[
                                const SizedBox(width: 8),
                                badgeChip(),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorsManger.primary.withValues(alpha: 0.14)),
        boxShadow: _cardShadow(),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ColorsManger.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: ColorsManger.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
