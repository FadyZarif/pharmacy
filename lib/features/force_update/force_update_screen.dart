import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/core/widgets/powered_by_cowdlly.dart';
import 'package:url_launcher/url_launcher.dart';

/// شاشة إجبار التحديث: لا يمكن استخدام التطبيق حتى يتم التحديث من المتجر.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  /// ضع App Store ID هنا بعد النشر (الرقم من رابط التطبيق على App Store).
  /// مثال: لو الرابط apps.apple.com/app/id1234567890 → ضع '1234567890'
  static const String _appStoreId = '';

  static String get _appStoreUrl {
    if (_appStoreId.isNotEmpty) {
      return 'https://apps.apple.com/app/id$_appStoreId';
    }
    // Fallback حتى يتم ضبط الـ ID
    return 'https://apps.apple.com/search?term=Emad%20Fawzy%20Pharmacy';
  }

  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.emadfawzy.pharmacies';

  static bool get _isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _openStore(BuildContext context) async {
    final uri = Uri.parse(_isIos ? _appStoreUrl : _playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeName = _isIos ? 'App Store' : 'Google Play';

    return Scaffold(
      backgroundColor: ColorsManger.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                Icons.system_update,
                size: 80,
                color: ColorsManger.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'تحديث مطلوب',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'نسخة التطبيق الحالية قديمة. يرجى التحديث من $storeName لاستمرار الاستخدام.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _openStore(context),
                icon: const Icon(Icons.open_in_new),
                label: Text('فتح $storeName'),
                style: FilledButton.styleFrom(
                  backgroundColor: ColorsManger.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              const PoweredByCowdlly(compact: true),
            ],
          ),
        ),
      ),
    );
  }
}
