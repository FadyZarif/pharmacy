import 'dart:typed_data';
import 'dart:io';

/// IO implementation for mobile/desktop
Future<Uint8List> readFileBytes(String path) async {
  return await File(path).readAsBytes();
}
