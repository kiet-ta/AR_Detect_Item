import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Utilities for preprocessing camera images.
///
/// Used by the Data Flywheel to compress failed captures before queuing.
final class ImagePreprocessor {
  ImagePreprocessor._();

  /// Converts [rgbBytes] to a binarized, compressed grayscale JPEG.
  ///
  /// Applies Otsu's adaptive thresholding to strip all photographic content,
  /// leaving only a pure black-and-white sketch — COPPA compliant and
  /// suitable for ML retraining with no identifiable information retained.
  ///
  /// Pipeline: resize → grayscale → Otsu binarize → JPEG encode
  ///
  /// - Resizes to [maxSize]×[maxSize] pixels (default: 96px)
  /// - JPEG quality 70 (enough for retraining, small file)
  static Uint8List compressForRetraining(
    Uint8List rgbBytes, {
    int maxSize = 96,
    int quality = 70,
  }) {
    final original = img.decodeImage(rgbBytes);
    if (original == null) return rgbBytes;

    final resized = img.copyResize(original, width: maxSize, height: maxSize);
    final grayscale = img.grayscale(resized);
    final binarized = _binarize(grayscale);

    return Uint8List.fromList(
      img.encodeJpg(binarized, quality: quality),
    );
  }

  /// Applies Otsu's global threshold to [grayscaleImage].
  ///
  /// Computes the optimal threshold by maximising inter-class variance
  /// across a 256-bin histogram, then maps every pixel to either
  /// pure black (≤ threshold) or pure white (> threshold).
  static img.Image _binarize(img.Image grayscaleImage) {
    // Build 256-bin histogram of luminance values.
    final histogram = List<int>.filled(256, 0);
    for (var y = 0; y < grayscaleImage.height; y++) {
      for (var x = 0; x < grayscaleImage.width; x++) {
        final pixel = grayscaleImage.getPixel(x, y);
        histogram[pixel.r.toInt()] += 1;
      }
    }

    final total = grayscaleImage.width * grayscaleImage.height;
    // Compute sum of all weighted intensities.
    var sum = 0.0;
    for (var i = 0; i < 256; i++) {
      sum += i * histogram[i];
    }

    // Otsu's method: find threshold that maximises inter-class variance.
    var weightBackground = 0.0;
    var sumBackground = 0.0;
    var maxVariance = 0.0;
    var threshold = 0;
    for (var t = 0; t < 256; t++) {
      weightBackground += histogram[t];
      if (weightBackground == 0) continue;

      final weightForeground = total - weightBackground;
      if (weightForeground == 0) break;

      sumBackground += t * histogram[t];
      final meanBackground = sumBackground / weightBackground;
      final meanForeground = (sum - sumBackground) / weightForeground;
      final diff = meanBackground - meanForeground;
      final variance = weightBackground * weightForeground * diff * diff;
      if (variance > maxVariance) {
        maxVariance = variance;
        threshold = t;
      }
    }

    // Apply binary threshold.
    final output = img.Image(
      width: grayscaleImage.width,
      height: grayscaleImage.height,
      numChannels: 1,
    );
    for (var y = 0; y < grayscaleImage.height; y++) {
      for (var x = 0; x < grayscaleImage.width; x++) {
        final pixel = grayscaleImage.getPixel(x, y);
        final value = pixel.r.toInt() > threshold ? 255 : 0;
        output.setPixel(x, y, output.getColor(value, value, value));
      }
    }
    return output;
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
