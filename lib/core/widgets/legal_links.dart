import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Privacy policy / terms links.
///
/// App Store Review 5.1.1(i) requires the privacy policy to be reachable from
/// inside the app, not only from the App Store listing — so this sits on the
/// login screen, where a reviewer finds it without an account.
class LegalLinks extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const LegalLinks({super.key, this.padding = EdgeInsets.zero});

  static const _base = 'https://pharmacy-employee-system-new.web.app';

  Future<void> _open(String path) async {
    try {
      await launchUrl(Uri.parse('$_base$path'),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      // A footer link that won't open has nothing sensible to report.
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: Colors.black.withValues(alpha: 0.45),
    );

    Widget link(String label, String path) => InkWell(
          onTap: () => _open(path),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(label, style: style),
          ),
        );

    return Padding(
      padding: padding,
      child: Material(
        type: MaterialType.transparency,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            link('سياسة الخصوصية', '/privacy'),
            Text('·', style: style),
            link('شروط الاستخدام', '/terms'),
          ],
        ),
      ),
    );
  }
}
