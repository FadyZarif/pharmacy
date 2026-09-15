import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final logoHeight = compact ? 24.0 : 36.0;
    final labelSize = compact ? 11.0 : 13.0;

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Powered by',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.50),
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: compact ? 4 : 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 10 : 14),
            child: ColoredBox(
              color: Colors.black,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 14,
                  vertical: compact ? 4 : 6,
                ),
                child: Image.asset(
                  assetPath,
                  height: logoHeight,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
