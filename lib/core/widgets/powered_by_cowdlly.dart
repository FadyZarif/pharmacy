import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Consistent "Powered by cowdlly" branding. Tapping it opens cowdlly.com.
class PoweredByCowdlly extends StatelessWidget {
  final bool compact;
  final EdgeInsetsGeometry padding;

  const PoweredByCowdlly({
    super.key,
    this.compact = false,
    this.padding = EdgeInsets.zero,
  });

  /// Tight crop with a dark wordmark — sized for light backgrounds.
  static const assetPath = 'assets/images/cowdlly_logo_dark.png';
  static final _site = Uri.parse('https://cowdlly.com');

  Future<void> _open() async {
    try {
      await launchUrl(_site, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Nothing sensible to show for a footer link that won't open.
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoHeight = compact ? 22.0 : 34.0;
    final labelStyle = GoogleFonts.inter(
      fontSize: compact ? 11 : 11.5,
      fontWeight: FontWeight.w500,
      letterSpacing: compact ? 0.2 : 1.8,
      color: Colors.black.withValues(alpha: 0.38),
    );

    final logoRow = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          assetPath,
          height: logoHeight,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
        ),
        SizedBox(width: compact ? 5 : 7),
        // Signals the mark is a link before it's tapped.
        Icon(
          Icons.open_in_new_rounded,
          size: compact ? 12 : 14,
          color: Colors.black.withValues(alpha: 0.32),
        ),
      ],
    );

    return Padding(
      padding: padding,
      child: SizedBox(
        width: double.infinity,
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: _open,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 10,
                  vertical: compact ? 4 : 6,
                ),
                child: compact
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Powered by', style: labelStyle),
                          const SizedBox(width: 8),
                          logoRow,
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('POWERED BY', style: labelStyle),
                          const SizedBox(height: 8),
                          logoRow,
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
