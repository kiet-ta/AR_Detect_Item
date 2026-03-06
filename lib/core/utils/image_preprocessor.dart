import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Utilities for preprocessing camera images.
///
/// Used by the Data Flywheel to compress failed captures before queuing.
final class ImagePreprocessor {
  ImagePreprocessor._();

  /// Converts [rgbBytes] to a tiny compressed grayscale JPEG.
  ///
  /// Output is stored in the failed-drawings queue and eventually
  /// uploaded to Firebase Storage for ML retraining.
  ///
  /// - Resizes to [maxSize]x[maxSize] pixels (default: 96px)
  /// - Converts to grayscale
  /// - JPEG quality 70 (enough for retraining, small file)
  static Uint8List compressForRetraining(
    Uint8List rgbBytes, {
    int maxSize = 96,
    int quality = 70,
  }) {
    final original = img.decodeImage(rgbBytes);
    if (original == null) return rgbBytes;

    final resized =
        img.copyResize(original, width: maxSize, height: maxSize);
    final grayscale = img.grayscale(resized);

    return Uint8List.fromList(
      img.encodeJpg(grayscale, quality: quality),
    );
  }

  /// Checks if [rgbBytes] is mostly white — likely an empty frame,
  /// not worth storing in the retraining queue.
  static bool isBlankFrame(Uint8List rgbBytes, {double threshold = 0.95}) {
    final image = img.decodeImage(rgbBytes);
    if (image == null) return true;

    var brightPixels = 0;
    final total = image.width * image.height;
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance =
            (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b) / 255.0;
        if (luminance > 0.9) brightPixels++;
      }
    }
    return brightPixels / total > threshold;
  }
}
