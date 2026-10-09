import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:rasmati/background_removal.dart';

img.Image _whiteCanvas(int width, int height) {
  final image = img.Image(width: width, height: height, numChannels: 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgba(x, y, 255, 255, 255, 255);
    }
  }
  return image;
}

void main() {
  test('removes light paper connected to the edges but preserves dark drawing', () {
    final source = _whiteCanvas(5, 5);
    source.setPixelRgba(2, 2, 20, 30, 40, 255);

    final result = removeEdgeConnectedLightPaper(source);

    expect(result.getPixel(0, 0).a, 0);
    expect(result.getPixel(2, 2).a, 255);
    expect(result.getPixel(2, 2).r, 20);
    // The source is immutable.
    expect(source.getPixel(0, 0).a, 255);
  });

  test('preserves enclosed white details inside a dark outline', () {
    final source = _whiteCanvas(7, 7);
    for (var x = 2; x <= 4; x++) {
      source.setPixelRgba(x, 2, 0, 0, 0, 255);
      source.setPixelRgba(x, 4, 0, 0, 0, 255);
    }
    source.setPixelRgba(2, 3, 0, 0, 0, 255);
    source.setPixelRgba(4, 3, 0, 0, 0, 255);

    final result = removeEdgeConnectedLightPaper(source);

    expect(result.getPixel(0, 0).a, 0);
    expect(result.getPixel(3, 2).a, 255);
    expect(result.getPixel(3, 3).a, 255);
    expect(result.getPixel(3, 3).r, 255);
  });

  test('threshold allows lighter paper tones to be removed', () {
    final source = _whiteCanvas(3, 3);
    for (var y = 0; y < 3; y++) {
      for (var x = 0; x < 3; x++) {
        source.setPixelRgba(x, y, 220, 220, 220, 255);
      }
    }

    final conservative = removeEdgeConnectedLightPaper(source, threshold: 0);
    final tolerant = removeEdgeConnectedLightPaper(source, threshold: 40);

    expect(conservative.getPixel(1, 1).a, 255);
    expect(tolerant.getPixel(1, 1).a, 0);
  });

  test('softens a pale antialiased pixel touching the removed paper', () {
    final source = _whiteCanvas(3, 3);
    source.setPixelRgba(1, 1, 15, 20, 25, 255);
    source.setPixelRgba(1, 2, 200, 200, 200, 255);

    final result = removeEdgeConnectedLightPaper(source);

    expect(result.getPixel(0, 0).a, 0);
    expect(result.getPixel(1, 1).a, 255);
    expect(result.getPixel(1, 2).a, greaterThan(0));
    expect(result.getPixel(1, 2).a, lessThan(255));
  });

  test('removes a sampled colored background but preserves enclosed matching color', () {
    final source = img.Image(width: 7, height: 7, numChannels: 4);
    for (var y = 0; y < 7; y++) {
      for (var x = 0; x < 7; x++) {
        source.setPixelRgba(x, y, 150, 80, 180, 255);
      }
    }
    // A dark closed outline isolates a same-colored detail from the backdrop.
    for (var x = 2; x <= 4; x++) {
      source.setPixelRgba(x, 2, 15, 15, 20, 255);
      source.setPixelRgba(x, 4, 15, 15, 20, 255);
    }
    source.setPixelRgba(2, 3, 15, 15, 20, 255);
    source.setPixelRgba(4, 3, 15, 15, 20, 255);

    final result = removeConnectedColorBackground(
      source,
      seedX: 0,
      seedY: 0,
      tolerance: 12,
    );

    expect(result.getPixel(0, 0).a, 0);
    expect(result.getPixel(3, 3).a, 255);
    expect(result.getPixel(3, 3).r, 150);
    expect(source.getPixel(0, 0).a, 255);
  });

  test('preserves existing transparency in enclosed details', () {
    final source = _whiteCanvas(7, 7);
    for (var x = 2; x <= 4; x++) {
      source.setPixelRgba(x, 2, 0, 0, 0, 255);
      source.setPixelRgba(x, 4, 0, 0, 0, 255);
    }
    source.setPixelRgba(2, 3, 0, 0, 0, 255);
    source.setPixelRgba(4, 3, 0, 0, 0, 255);
    source.setPixelRgba(3, 3, 255, 255, 255, 0);

    final paperResult = removeEdgeConnectedLightPaper(source);
    expect(paperResult.getPixel(3, 3).a, 0);

    final colorSource = img.Image(width: 7, height: 7, numChannels: 4);
    for (var y = 0; y < 7; y++) {
      for (var x = 0; x < 7; x++) {
        colorSource.setPixelRgba(x, y, 150, 80, 180, 255);
      }
    }
    for (var x = 2; x <= 4; x++) {
      colorSource.setPixelRgba(x, 2, 15, 15, 20, 255);
      colorSource.setPixelRgba(x, 4, 15, 15, 20, 255);
    }
    colorSource.setPixelRgba(2, 3, 15, 15, 20, 255);
    colorSource.setPixelRgba(4, 3, 15, 15, 20, 255);
    colorSource.setPixelRgba(3, 3, 150, 80, 180, 0);

    final colorResult = removeConnectedColorBackground(
      colorSource, seedX: 0, seedY: 0, tolerance: 12,
    );
    expect(colorResult.getPixel(3, 3).a, 0);
  });

  test('sampled color removal respects tolerance', () {
    final source = _whiteCanvas(3, 3);
    for (var y = 0; y < 3; y++) {
      for (var x = 0; x < 3; x++) {
        source.setPixelRgba(x, y, 180, 90, 150, 255);
      }
    }
    source.setPixelRgba(2, 2, 225, 135, 195, 255);

    final strict = removeConnectedColorBackground(
      source, seedX: 0, seedY: 0, tolerance: 10,
    );
    final tolerant = removeConnectedColorBackground(
      source, seedX: 0, seedY: 0, tolerance: 80,
    );

    expect(strict.getPixel(2, 2).a, 255);
    expect(tolerant.getPixel(2, 2).a, 0);
  });

}
