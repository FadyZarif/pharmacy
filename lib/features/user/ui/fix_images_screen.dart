// filepath: e:\github\pharmacy\lib\features\user\ui\fix_images_screen.dart
import 'package:flutter/material.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/core/utils/fix_existing_images_metadata.dart';

/// شاشة إصلاح صور المستخدمين
/// هذه الشاشة يمكن الوصول إليها من قبل الـ Admin فقط
class FixImagesScreen extends StatefulWidget {
  const FixImagesScreen({super.key});

  @override
  State<FixImagesScreen> createState() => _FixImagesScreenState();
}

class _FixImagesScreenState extends State<FixImagesScreen> {
  bool _isProcessing = false;
  Map<String, dynamic>? _lastResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManger.primaryBackground,
      appBar: AppBar(
        title: const Text(
          'إصلاح صور المستخدمين',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: ColorsManger.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // معلومات توضيحية
            _buildInfoCard(),

            const SizedBox(height: 20),

            // زر إصلاح جميع الصور
            _buildFixAllButton(),

            const SizedBox(height: 15),

            // زر إصلاح صور البروفايل فقط
            _buildFixProfileOnlyButton(),

            const SizedBox(height: 30),

            // عرض النتائج
            if (_lastResult != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 10),
                Text(
                  'ما هو هذا؟',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'هذه الأداة تقوم بإصلاح صور المستخدمين القديمة التي تم رفعها بدون contentType صحيح.\n\n'
              'المشكلة: الصور القديمة قد لا تظهر بشكل صحيح في المتصفح.\n\n'
              'الحل: تحديث metadata الصور لتحتوي على contentType صحيح (image/jpeg).',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'ملاحظة: هذه العملية قد تستغرق بعض الوقت حسب عدد المستخدمين.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixAllButton() {
    return ElevatedButton(
      onPressed: _isProcessing ? null : _fixAllImages,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorsManger.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isProcessing
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'جاري المعالجة...',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_search, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'إصلاح جميع صور المستخدمين',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFixProfileOnlyButton() {
    return OutlinedButton(
      onPressed: _isProcessing ? null : _fixProfileImagesOnly,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: ColorsManger.primary, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_special, color: ColorsManger.primary),
          const SizedBox(width: 10),
          Text(
            'إصلاح صور البروفايل فقط',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorsManger.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _lastResult!;
    final total = result['total'] ?? 0;
    final success = result['success'] ?? 0;
    final failed = result['failed'] ?? 0;
    final skipped = result['skipped'] ?? 0;

    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700]),
                const SizedBox(width: 10),
                Text(
                  'نتائج العملية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildResultRow('إجمالي', total, Icons.people, Colors.blue),
            _buildResultRow('نجح', success, Icons.check_circle, Colors.green),
            if (failed > 0)
              _buildResultRow('فشل', failed, Icons.error, Colors.red),
            if (skipped > 0)
              _buildResultRow('تم التخطي', skipped, Icons.skip_next, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, int value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 10),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fixAllImages() async {
    setState(() {
      _isProcessing = true;
      _lastResult = null;
    });

    try {
      final result = await ImageMetadataFixer.fixAllUserImages();

      if (mounted) {
        setState(() {
          _lastResult = result;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إصلاح ${result['success']} من ${result['total']} صورة بنجاح! ✅',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _fixProfileImagesOnly() async {
    setState(() {
      _isProcessing = true;
      _lastResult = null;
    });

    try {
      final result = await ImageMetadataFixer.fixProfileImagesOnly();

      if (mounted) {
        setState(() {
          _lastResult = result;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إصلاح ${result['success']} من ${result['total']} ملف بنجاح! ✅',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

