import 'package:flutter/material.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// شاشة إجبار التحديث: لا يمكن استخدام التطبيق حتى يتم التحديث من المتجر.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.emadfawzy.pharmacies';

  Future<void> _openPlayStore(BuildContext context) async {
    final uri = Uri.parse(_playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManger.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                'نسخة التطبيق الحالية قديمة. يرجى التحديث من متجر Google Play لاستمرار الاستخدام.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _openPlayStore(context),
                icon: const Icon(Icons.open_in_new),
                label: const Text('فتح متجر Google Play'),
                style: FilledButton.styleFrom(
                  backgroundColor: ColorsManger.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
