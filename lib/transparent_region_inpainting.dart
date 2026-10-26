import 'package:image/image.dart' as img;

/// Lightweight local inpainting for pixels removed by rig segmentation.
///
/// This propagates nearby visible colors inward in small frontiers. It avoids
/// restoring the original limb pixels, but cannot invent hidden anatomy or
/// recover exact line art; complex drawings still need a reviewed clone patch.
class TransparentRegionInpainting {
  TransparentRegionInpainting._();

  static img.Image fillRemovedPixels({
    required img.Image base,
    required List<bool> removed,
    int maxIterations = 48,
  }) {
    final width = base.width;
    final height = base.height;
    if (removed.length != width * height) {
      throw ArgumentError('removed mask must match image dimensions');
    }
    if (maxIterations < 1) throw ArgumentError.value(maxIterations, 'maxIterations');

    final result = img.Image.from(base);
    final known = List<bool>.generate(width * height, (i) {
      final p = result.getPixel(i % width, i ~/ width);
      return !removed[i] && p.a > 0;
    });
    final targets = List<bool>.generate(width * height, (i) => removed[i]);
    const neighbors = <(int, int)>[(0, -1), (-1, 0), (1, 0), (0, 1),
      (-1, -1), (1, -1), (-1, 1), (1, 1)];

    for (var iteration = 0; iteration < maxIterations; iteration++) {
      final updates = <(int index, int r, int g, int b)>[];
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final index = y * width + x;
          if (!targets[index] || known[index]) continue;
          var r = 0.0, g = 0.0, b = 0.0, weightSum = 0.0;
          for (final (dx, dy) in neighbors) {
            final nx = x + dx, ny = y + dy;
            if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;
            final ni = ny * width + nx;
            if (!known[ni]) continue;
            final p = result.getPixel(nx, ny);
            final weight = dx == 0 || dy == 0 ? 1.0 : 0.70710678;
            r += p.r * weight;
            g += p.g * weight;
            b += p.b * weight;
            weightSum += weight;
          }
          if (weightSum > 0) {
            updates.add((index, (r / weightSum).round(), (g / weightSum).round(),
              (b / weightSum).round()));
          }
        }
      }
      if (updates.isEmpty) break;
      for (final update in updates) {
        final x = update.$1 % width, y = update.$1 ~/ width;
        result.setPixelRgba(x, y, update.$2, update.$3, update.$4, 255);
        known[update.$1] = true;
      }
    }
    return result;
  }
}
