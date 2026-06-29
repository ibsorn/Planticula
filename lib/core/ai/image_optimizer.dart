import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:planticula/core/utils/logger.dart';

class ImageOptimizer {
  final int maxDimension;
  final int quality;

  const ImageOptimizer({
    this.maxDimension = 1024,
    this.quality = 82,
  });

  Uint8List optimize(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;

      int w = decoded.width;
      int h = decoded.height;

      if (w > maxDimension || h > maxDimension) {
        if (w > h) {
          h = (h * maxDimension ~/ w);
          w = maxDimension;
        } else {
          w = (w * maxDimension ~/ h);
          h = maxDimension;
        }
      }

      final resized = (w != decoded.width || h != decoded.height)
          ? img.copyResize(
              decoded,
              width: w,
              height: h,
              interpolation: img.Interpolation.linear,
            )
          : decoded;

      return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    } catch (e) {
      Logger.w('Image optimization failed, returning original: $e');
      return bytes;
    }
  }
}
