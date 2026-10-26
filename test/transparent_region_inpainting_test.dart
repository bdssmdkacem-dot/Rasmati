import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:rasmati/transparent_region_inpainting.dart';

void main() {
  group('TransparentRegionInpainting', () {
    test('fills a removed pixel from surrounding visible pixels', () {
      final base = img.Image(width: 3, height: 3, numChannels: 4);
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 3; x++) {
          base.setPixelRgba(x, y, 90, 120, 150, 255);
        }
      }
      base.setPixelRgba(1, 1, 0, 0, 0, 0);
      final mask = List<bool>.filled(9, false)..[4] = true;

      final result = TransparentRegionInpainting.fillRemovedPixels(
        base: base,
        removed: mask,
      );

      final center = result.getPixel(1, 1);
      expect(center.a, 255);
      expect(center.r, 90);
      expect(center.g, 120);
      expect(center.b, 150);
      expect(base.getPixel(1, 1).a, 0, reason: 'must not mutate the source base');
    });

    test('continues a simple line through a one-pixel cutout', () {
      final base = img.Image(width: 7, height: 7, numChannels: 4);
      for (var y = 0; y < 7; y++) {
        for (var x = 0; x < 7; x++) {
          final isLine = x == 3;
          base.setPixelRgba(x, y, isLine ? 0 : 245, isLine ? 0 : 245,
              isLine ? 0 : 245, 255);
        }
      }
      base.setPixelRgba(3, 3, 0, 0, 0, 0);
      final removed = List<bool>.filled(49, false)..[3 * 7 + 3] = true;

      final result = TransparentRegionInpainting.fillRemovedPixels(
        base: base,
        removed: removed,
        patchRadius: 1,
      );

      final center = result.getPixel(3, 3);
      expect(center.a, 255);
      expect(center.r, lessThan(80), reason: 'the black line should continue');
    });

    test('preserves unrelated transparent background', () {
      final base = img.Image(width: 3, height: 1, numChannels: 4);
      base.setPixelRgba(0, 0, 0, 0, 0, 0);
      base.setPixelRgba(1, 0, 30, 60, 90, 255);
      base.setPixelRgba(2, 0, 0, 0, 0, 0);

      final result = TransparentRegionInpainting.fillRemovedPixels(
        base: base,
        removed: [false, false, false],
      );

      expect(result.getPixel(0, 0).a, 0);
      expect(result.getPixel(2, 0).a, 0);
    });

    test('rejects masks with a mismatched image size', () {
      final base = img.Image(width: 2, height: 2);
      expect(
        () => TransparentRegionInpainting.fillRemovedPixels(base: base, removed: [true]),
        throwsArgumentError,
      );
    });
  });
}
