import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Makes light, paper-like pixels transparent only when connected to an image
/// edge. Enclosed white details remain intact. The input image is not mutated.
img.Image removeEdgeConnectedLightPaper(
  img.Image source, {
  double threshold = 34,
}) {
  final width = source.width;
  final height = source.height;
  final count = width * height;
  final alpha = Uint8List(count)..fillRange(0, count, 255);
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
    return (r + g + b) / 3 >= 224 - threshold &&
        maximum - minimum <= 54 + threshold;
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
    alpha[index] = 0;
    final x = index % width;
    final y = index ~/ width;
    enqueue(x - 1, y);
    enqueue(x + 1, y);
    enqueue(x, y - 1);
    enqueue(x, y + 1);
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
