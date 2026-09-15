import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Consistent "Powered by cowdlly" branding with logo.
class PoweredByCowdlly extends StatelessWidget {
  final bool compact;
  final EdgeInsetsGeometry padding;

  const PoweredByCowdlly({
    super.key,
    this.compact = false,
    this.padding = EdgeInsets.zero,
  });

  static const assetPath = 'assets/images/cowdlly_logo.png';

  // Brand accents from the cowdlly mark (cyan → violet).
  static const _cyan = Color(0xFF2EC5FF);
  static const _violet = Color(0xFF7B4DFF);
  static const _surface = Color(0xFF0B0B10);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SizedBox(
        width: double.infinity,
        child: Center(
          child: compact ? _buildCompact() : _buildFull(),
        ),
      ),
    );
  }

  Widget _buildFull() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'POWERED BY',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.4,
            color: Colors.black.withValues(alpha: 0.42),
          ),
        ),
        const SizedBox(height: 10),
        _LogoBadge(
          height: 56,
          horizontalPadding: 22,
          verticalPadding: 10,
          radius: 18,
        ),
      ],
    );
  }

  Widget _buildCompact() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Powered by',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
            color: Colors.black.withValues(alpha: 0.48),
          ),
        ),
        const SizedBox(width: 10),
        _LogoBadge(
          height: 30,
          horizontalPadding: 12,
          verticalPadding: 5,
          radius: 11,
        ),
      ],
    );
  }
}

class _LogoBadge extends StatelessWidget {
  final double height;
  final double horizontalPadding;
  final double verticalPadding;
  final double radius;

  const _LogoBadge({
    required this.height,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            PoweredByCowdlly._cyan,
            PoweredByCowdlly._violet,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: PoweredByCowdlly._violet.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.4),
      child: Container(
        decoration: BoxDecoration(
          color: PoweredByCowdlly._surface,
          borderRadius: BorderRadius.circular(radius - 1),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Image.asset(
          PoweredByCowdlly.assetPath,
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
        ),
      ),
    );
  }
}
