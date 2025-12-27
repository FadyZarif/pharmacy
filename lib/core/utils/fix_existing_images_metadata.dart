// filepath: e:\github\pharmacy\lib\core\utils\fix_existing_images_metadata.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// هذا الملف يحتوي على دوال لإصلاح metadata الصور الموجودة في Firebase Storage
///
/// الاستخدام:
/// 1. استدعِ الدالة من أي مكان في التطبيق (مثلاً من زر في صفحة الإعدادات)
/// 2. أو نفذها مرة واحدة عند فتح التطبيق للمرة الأولى بعد التحديث

class ImageMetadataFixer {
  /// إصلاح metadata لصورة واحدة
  static Future<bool> fixImageMetadata(String imageUrl) async {
    try {
      // استخراج مسار الملف من URL
      final uri = Uri.parse(imageUrl);

      // تحقق من أن URL من Firebase Storage
      if (!uri.host.contains('firebasestorage.googleapis.com')) {
        print('⚠️ URL is not from Firebase Storage: $imageUrl');
        return false;
      }

      // استخراج المسار
      final pathSegments = uri.pathSegments;
      if (pathSegments.length < 3) {
        print('⚠️ Invalid Firebase Storage URL: $imageUrl');
        return false;
      }

      // المسار يبدأ من بعد "v0/b/bucket-name/o/"
      final path = pathSegments.skip(3).join('/').split('?').first;
      final decodedPath = Uri.decodeComponent(path);

      print('🔄 Fixing metadata for: $decodedPath');

      final ref = FirebaseStorage.instance.ref().child(decodedPath);

      // الحصول على metadata الحالية
      final currentMetadata = await ref.getMetadata();
      print('📋 Current contentType: ${currentMetadata.contentType}');

      // إذا كان contentType صحيح بالفعل، لا حاجة للتحديث
      if (currentMetadata.contentType == 'image/jpeg' ||
          currentMetadata.contentType == 'image/png') {
        print('✅ ContentType is already correct');
        return true;
      }

      // تحديد contentType الصحيح بناءً على امتداد الملف
      String contentType;
      if (decodedPath.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (decodedPath.toLowerCase().endsWith('.jpg') ||
          decodedPath.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      } else if (decodedPath.toLowerCase().endsWith('.gif')) {
        contentType = 'image/gif';
      } else if (decodedPath.toLowerCase().endsWith('.webp')) {
        contentType = 'image/webp';
      } else {
        // افتراضياً نستخدم jpeg
        contentType = 'image/jpeg';
      }

      // تحديث Metadata
      await ref.updateMetadata(
        SettableMetadata(contentType: contentType),
      );

      print('✅ Metadata updated successfully! New contentType: $contentType');
      return true;
    } catch (e) {
      print('❌ Failed to update metadata: $e');
      return false;
    }
  }

  /// إصلاح metadata لجميع صور المستخدمين
  static Future<Map<String, dynamic>> fixAllUserImages() async {
    int total = 0;
    int success = 0;
    int failed = 0;
    int skipped = 0;

    try {
      print('🚀 Starting to fix all user images metadata...\n');

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      total = usersSnapshot.docs.length;
      print('📊 Found $total users\n');

      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        final photoUrl = userData['photoUrl'];
        final userName = userData['name'] ?? 'Unknown';

        if (photoUrl == null || photoUrl.toString().isEmpty) {
          print('⏭️  Skipping $userName (no photo)');
          skipped++;
          continue;
        }

        print('\n👤 Processing: $userName');
        final result = await fixImageMetadata(photoUrl.toString());

        if (result) {
          success++;
        } else {
          failed++;
        }

        // انتظر قليلاً لتجنب Rate Limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }

      print('\n' + '=' * 50);
      print('📊 Final Report:');
      print('   Total users: $total');
      print('   ✅ Successfully fixed: $success');
      print('   ❌ Failed: $failed');
      print('   ⏭️  Skipped (no photo): $skipped');
      print('=' * 50);

      return {
        'total': total,
        'success': success,
        'failed': failed,
        'skipped': skipped,
      };
    } catch (e) {
      print('❌ Error during batch processing: $e');
      return {
        'total': total,
        'success': success,
        'failed': failed,
        'skipped': skipped,
        'error': e.toString(),
      };
    }
  }

  /// إصلاح metadata لصورة مستخدم محدد
  static Future<bool> fixUserImageByUid(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        print('❌ User not found: $uid');
        return false;
      }

      final userData = userDoc.data();
      final photoUrl = userData?['photoUrl'];

      if (photoUrl == null || photoUrl.toString().isEmpty) {
        print('⚠️ User has no photo');
        return false;
      }

      return await fixImageMetadata(photoUrl.toString());
    } catch (e) {
      print('❌ Failed to fix user image: $e');
      return false;
    }
  }

  /// إصلاح metadata لصور البروفايل فقط (في مجلد profile)
  static Future<Map<String, dynamic>> fixProfileImagesOnly() async {
    int total = 0;
    int success = 0;
    int failed = 0;

    try {
      print('🚀 Starting to fix profile images metadata...\n');

      // الحصول على جميع الملفات في مجلد profile
      final listResult = await FirebaseStorage.instance
          .ref()
          .child('profile')
          .listAll();

      total = listResult.items.length;
      print('📊 Found $total files in profile folder\n');

      for (var item in listResult.items) {
        print('🔄 Processing: ${item.name}');

        try {
          // الحصول على metadata الحالية
          final currentMetadata = await item.getMetadata();
          print('   Current contentType: ${currentMetadata.contentType}');

          // إذا كان contentType صحيح بالفعل، تخطي
          if (currentMetadata.contentType == 'image/jpeg' ||
              currentMetadata.contentType == 'image/png') {
            print('   ✅ Already correct, skipping');
            success++;
            continue;
          }

          // تحديث Metadata
          await item.updateMetadata(
            SettableMetadata(contentType: 'image/jpeg'),
          );

          print('   ✅ Updated successfully!');
          success++;
        } catch (e) {
          print('   ❌ Failed: $e');
          failed++;
        }

        // انتظر قليلاً
        await Future.delayed(const Duration(milliseconds: 300));
      }

      print('\n' + '=' * 50);
      print('📊 Final Report:');
      print('   Total files: $total');
      print('   ✅ Successfully fixed: $success');
      print('   ❌ Failed: $failed');
      print('=' * 50);

      return {
        'total': total,
        'success': success,
        'failed': failed,
      };
    } catch (e) {
      print('❌ Error during batch processing: $e');
      return {
        'total': total,
        'success': success,
        'failed': failed,
        'error': e.toString(),
      };
    }
  }
}

/// مثال على كيفية الاستخدام في التطبيق:
///
/// ```dart
/// // في صفحة الإعدادات أو أي مكان مناسب
/// ElevatedButton(
///   onPressed: () async {
///     showDialog(
///       context: context,
///       barrierDismissible: false,
///       builder: (context) => const Center(
///         child: CircularProgressIndicator(),
///       ),
///     );
///
///     final result = await ImageMetadataFixer.fixAllUserImages();
///
///     if (mounted) {
///       Navigator.pop(context);
///       showDialog(
///         context: context,
///         builder: (context) => AlertDialog(
///           title: const Text('إصلاح الصور'),
///           content: Text(
///             'تم إصلاح ${result['success']} من ${result['total']} صورة\n'
///             'فشل: ${result['failed']}\n'
///             'تم تخطيها: ${result['skipped']}'
///           ),
///           actions: [
///             TextButton(
///               onPressed: () => Navigator.pop(context),
///               child: const Text('حسناً'),
///             ),
///           ],
///         ),
///       );
///     }
///   },
///   child: const Text('إصلاح جميع صور المستخدمين'),
/// )
/// ```

