import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Removes edge-connected paper while retaining enclosed light details.
///
/// A second pass softens one-pixel, near-neutral antialiasing around the cutout
/// to reduce the hard white fringe commonly left by photographed drawings.
/// The source image is never mutated.
img.Image removeEdgeConnectedLightPaper(
  img.Image source, {
  double threshold = 34,
}) {
  final width = source.width;
  final height = source.height;
  final count = width * height;
  if (width == 0 || height == 0) {
    return img.Image(width: width, height: height, numChannels: 4);
  }

  final alpha = Uint8List(count);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      alpha[y * width + x] = source.getPixel(x, y).a.toInt();
    }
  }
  final removed = Uint8List(count);
  final queue = Int32List(count);
  final visited = Uint8List(count);
  var head = 0;
  var tail = 0;

  bool isPaper(int x, int y) {
    final pixel = source.getPixel(x, y);
    final r = pixel.r.toDouble();
    final g = pixel.g.toDouble();
    final b = pixel.b.toDouble();
    final minimum = math.min(r, math.min(g, b));
    final maximum = math.max(r, math.max(g, b));
    final brightness = (r + g + b) / 3;
    final luminanceFloor = 240 - threshold.clamp(0, 55) * 0.76;
    final colorSpreadLimit = 24 + threshold.clamp(0, 55) * 0.55;
    return brightness >= luminanceFloor &&
        maximum - minimum <= colorSpreadLimit;
  }

  void enqueue(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    final index = y * width + x;
    if (visited[index] != 0 || !isPaper(x, y)) return;
    visited[index] = 1;
    queue[tail++] = index;
  }

  for (var x = 0; x < width; x++) {
    enqueue(x, 0);
    if (height > 1) enqueue(x, height - 1);
  }
  for (var y = 1; y < height - 1; y++) {
    enqueue(0, y);
    if (width > 1) enqueue(width - 1, y);
  }

  while (head < tail) {
    final index = queue[head++];
    removed[index] = 1;
    alpha[index] = 0;
    final x = index % width;
    final y = index ~/ width;
    enqueue(x - 1, y);
    enqueue(x + 1, y);
    enqueue(x, y - 1);
    enqueue(x, y + 1);
  }

  // Feather only pixels directly touching the removed region. This keeps
  // the algorithm local to the cutout edge and avoids fading pale details
  // elsewhere in the drawing.
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final index = y * width + x;
      if (removed[index] != 0) continue;
      var touchesRemoved = false;
      if (x > 0 && removed[index - 1] != 0) touchesRemoved = true;
      if (x + 1 < width && removed[index + 1] != 0) touchesRemoved = true;
      if (y > 0 && removed[index - width] != 0) touchesRemoved = true;
      if (y + 1 < height && removed[index + width] != 0) touchesRemoved = true;
      if (!touchesRemoved) continue;

      final pixel = source.getPixel(x, y);
      final r = pixel.r.toDouble();
      final g = pixel.g.toDouble();
      final b = pixel.b.toDouble();
      final brightness = (r + g + b) / 3;
      final spread = math.max(r, math.max(g, b)) -
          math.min(r, math.min(g, b));
      if (brightness <= 150 || spread > 48) continue;
      final opacity = ((255 - brightness) / 105 * 255)
          .round()
          .clamp(0, 255)
          .toInt();
      alpha[index] = math.min(alpha[index], opacity).toInt();
    }
  }

  final output = img.Image(width: width, height: height, numChannels: 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixel = source.getPixel(x, y);
      output.setPixelRgba(
        x,
        y,
        pixel.r.toInt(),
        pixel.g.toInt(),
        pixel.b.toInt(),
        alpha[y * width + x],
      );
    }
  }
  return output;
}


/// Removes a connected region matching a user-sampled background color.
///
/// This mode supports colored paper and simple flat backdrops that the
/// light-paper detector cannot identify. It is deliberately seed-connected:
/// similarly colored details enclosed by a different outline are preserved.
/// The source image is never mutated.
img.Image removeConnectedColorBackground(
  img.Image source, {
  required int seedX,
  required int seedY,
  double tolerance = 38,
}) {
  final width = source.width;
  final height = source.height;
  final count = width * height;
  if (width == 0 || height == 0) {
    return img.Image(width: width, height: height, numChannels: 4);
  }

  final sx = seedX.clamp(0, width - 1).toInt();
  final sy = seedY.clamp(0, height - 1).toInt();
  final seed = source.getPixel(sx, sy);
  final sr = seed.r.toDouble();
  final sg = seed.g.toDouble();
  final sb = seed.b.toDouble();
  final limit = tolerance.clamp(4, 120).toDouble();
  final alpha = Uint8List(count);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      alpha[y * width + x] = source.getPixel(x, y).a.toInt();
    }
  }
  final removed = Uint8List(count);
  final visited = Uint8List(count);
  final queue = Int32List(count);
  var head = 0;
  var tail = 0;

  double distanceAt(int x, int y) {
    final pixel = source.getPixel(x, y);
    final dr = pixel.r.toDouble() - sr;
    final dg = pixel.g.toDouble() - sg;
    final db = pixel.b.toDouble() - sb;
    // Weighted RGB distance is inexpensive and slightly more sensitive to
    // green luminance differences than a plain channel average.
    return math.sqrt(0.30 * dr * dr + 0.59 * dg * dg + 0.11 * db * db);
  }

  void enqueue(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    final index = y * width + x;
    if (visited[index] != 0 || distanceAt(x, y) > limit) return;
    visited[index] = 1;
    queue[tail++] = index;
  }

  enqueue(sx, sy);
  while (head < tail) {
    final index = queue[head++];
    removed[index] = 1;
    alpha[index] = 0;
    final x = index % width;
    final y = index ~/ width;
    enqueue(x - 1, y);
    enqueue(x + 1, y);
    enqueue(x, y - 1);
    enqueue(x, y + 1);
  }

  // Soften only the first pixel ring around the mask. A pixel closer to the
  // sampled background becomes more transparent; saturated/dark ink stays
  // opaque to avoid washing out colored outlines.
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final index = y * width + x;
      if (removed[index] != 0) continue;
      final touchesRemoved =
          (x > 0 && removed[index - 1] != 0) ||
          (x + 1 < width && removed[index + 1] != 0) ||
          (y > 0 && removed[index - width] != 0) ||
          (y + 1 < height && removed[index + width] != 0);
      if (!touchesRemoved) continue;
      final distance = distanceAt(x, y);
      if (distance > limit + 30) continue;
      final opacity = (((distance - limit) / 30) * 255)
          .round()
          .clamp(0, 255)
          .toInt();
      alpha[index] = math.min(alpha[index], opacity).toInt();
    }
  }

  final output = img.Image(width: width, height: height, numChannels: 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixel = source.getPixel(x, y);
      output.setPixelRgba(
        x, y, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(),
        alpha[y * width + x],
      );
    }
  }
  return output;
}
