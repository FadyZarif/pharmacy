import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// يتحقق من إجبار التحديث: إذا كان إصدار التطبيق الحالي أقل من الحد الأدنى المخزن في Firestore.
///
/// إعداد Firestore:
/// 1. أنشئ مجموعة (collection) باسم: app_config
/// 2. أنشئ مستنداً (document) بمعرف: version
/// 3. أضف حقلاً (field): minimum_build_number (رقم صحيح)
/// 4. عند رفع تحديث جديد على Play Store، ضع قيمة minimum_build_number = رقم البناء (build number) الجديد
///    مثال: لو النسخة 1.1.1+11 فضع 11. كل من لديه build أقل من 11 سيرى شاشة "تحديث مطلوب".
class ForceUpdateService {
  static const String _configPath = 'app_config';
  static const String _docId = 'version';
  static const String _fieldMinBuildNumber = 'minimum_build_number';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ينشئ مستند الإصدار في Firestore إذا كان غير موجود، بقيمة 0 (لا إجبار تحديث).
  /// بعد نزول التحديث على Play Store غيّر في Firebase Console قيمة minimum_build_number إلى رقم البناء (مثلاً 11).
  static Future<void> createVersionDocumentIfMissing() async {
    try {
      final ref = _firestore.collection(_configPath).doc(_docId);
      final doc = await ref.get();
      if (!doc.exists) {
        await ref.set({_fieldMinBuildNumber: 0});
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

      final minBuild = doc.data()![_fieldMinBuildNumber];
      if (minBuild == null) return false;

      final minimumBuild = minBuild is int ? minBuild : int.tryParse(minBuild.toString()) ?? 0;
      return currentBuild < minimumBuild;
    } catch (_) {
      return false;
    }
  }
}
