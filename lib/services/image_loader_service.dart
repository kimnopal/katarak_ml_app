import 'dart:io';
import 'package:image/image.dart' as img;

/// Decode file -> image package (RGB)
Future<img.Image?> decodeImageFile(File file) async {
  final bytes = await file.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  // pastikan RGB (bukan grayscale/CMYK)
  return img.copyResize(decoded, width: decoded.width, height: decoded.height);
}
