import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';

/// يتحقق من إجبار التحديث: إذا كان إصدار التطبيق الحالي أقل من الحد الأدنى المخزن في Firestore.
///
/// إعداد Firestore (`app_config` / `version`):
/// - `minimum_build_number` (int): الحد الأدنى لأندرويد (و Web)
/// - `minimum_build_number_ios` (int): الحد الأدنى لـ iOS
///
/// عند رفع تحديث جديد:
/// - Android: ضع `minimum_build_number` = رقم البناء (مثلاً 19 من `1.2.5+19`)
/// - iOS: ضع `minimum_build_number_ios` = رقم البناء (CFBundleVersion)
class ForceUpdateService {
  static const String _configPath = 'app_config';
  static const String _docId = 'version';
  static const String _fieldMinBuildAndroid = 'minimum_build_number';
  static const String _fieldMinBuildIos = 'minimum_build_number_ios';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static bool get _isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static String get _minBuildField =>
      _isIos ? _fieldMinBuildIos : _fieldMinBuildAndroid;

  /// ينشئ مستند الإصدار في Firestore إذا كان غير موجود، بقيمة 0 (لا إجبار تحديث).
  /// لو المستند موجود بدون حقل iOS، يضيف `minimum_build_number_ios: 0`.
  static Future<void> createVersionDocumentIfMissing() async {
    try {
      final ref = _firestore.collection(_configPath).doc(_docId);
      final doc = await ref.get();
      if (!doc.exists) {
        await ref.set({
          _fieldMinBuildAndroid: 0,
          _fieldMinBuildIos: 0,
        });
        return;
      }

      final data = doc.data() ?? {};
      if (!data.containsKey(_fieldMinBuildIos)) {
        await ref.set({_fieldMinBuildIos: 0}, SetOptions(merge: true));
      }
    } catch (_) {
      // تجاهل الأخطاء (مثلاً عدم الصلاحيات)
    }
  }

  /// يرجع true إذا كان يجب منع استخدام التطبيق وإظهار شاشة "يجب التحديث".
  static Future<bool> isUpdateRequired() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      final doc = await _firestore.collection(_configPath).doc(_docId).get();
      if (!doc.exists || doc.data() == null) return false;

      final data = doc.data()!;
      final minBuild = data[_minBuildField];
      if (minBuild == null) return false;

      final minimumBuild =
          minBuild is int ? minBuild : int.tryParse(minBuild.toString()) ?? 0;
      return currentBuild < minimumBuild;
    } catch (_) {
      return false;
    }
  }
}
