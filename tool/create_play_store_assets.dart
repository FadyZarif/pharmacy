import 'dart:io';
import 'package:image/image.dart' as img;

/// Creates Google Play assets from pharmacy logo:
/// - App Icon 512x512
/// - Feature Graphic 1024x500
/// Run from project root: dart run tool/create_play_store_assets.dart
void main() async {
  final projectRoot = Directory.current.path;
  final logoPath = '$projectRoot/assets/images/app_launcher_icon.png';
  final outDir = '$projectRoot/build/play_store';
  final iconPath = '$outDir/app_icon_512.png';
  final bannerPath = '$outDir/feature_graphic_1024x500.png';

  final logoFile = File(logoPath);
  if (!await logoFile.exists()) {
    print('ERROR: Logo not found at $logoPath');
    exit(1);
  }

  final bytes = await logoFile.readAsBytes();
  img.Image? logo = img.decodeImage(bytes);
  if (logo == null) {
    print('ERROR: Could not decode logo image.');
    exit(1);
  }

  await Directory(outDir).create(recursive: true);

  // --- App Icon 512x512 (logo centered on white background) ---
  final icon = img.copyResize(
    logo,
    width: 512,
    height: 512,
    maintainAspect: true,
    backgroundColor: img.ColorRgba8(255, 255, 255, 255),
    interpolation: img.Interpolation.linear,
  );
  await File(iconPath).writeAsBytes(img.encodePng(icon));
  print('Created: $iconPath');

  // --- Feature Graphic 1024x500 (primary color background + centered logo) ---
  const primaryR = 0x00;
  const primaryG = 0xB4;
  const primaryB = 0xD8;
  final banner = img.Image(width: 1024, height: 500)
    ..clear(img.ColorRgba8(primaryR, primaryG, primaryB, 255));

  final logoHeight = 380;
  final logoResized = img.copyResize(
    logo,
    height: logoHeight,
    maintainAspect: true,
    interpolation: img.Interpolation.linear,
  );
  final dx = (1024 - logoResized.width) ~/ 2;
  final dy = (500 - logoResized.height) ~/ 2;
  img.compositeImage(banner, logoResized, dstX: dx, dstY: dy);
  await File(bannerPath).writeAsBytes(img.encodePng(banner));
  print('Created: $bannerPath');

  print('Done. Upload $iconPath and $bannerPath to Google Play Console.');
}
