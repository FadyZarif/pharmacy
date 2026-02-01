import 'dart:typed_data';

/// Web implementation - uses bytes directly from file picker
Future<Uint8List> readFileBytes(String path) {
  throw UnsupportedError('Cannot read file by path on web. Use file.bytes instead.');
}
