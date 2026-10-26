import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:rasmati/lama_inpainting_engine.dart';

void main() {
  group('LamaInpaintingEngine guards', () {
    late img.Image source;

    setUp(() {
      source = img.Image(width: 3, height: 2);
      source.setPixelRgba(0, 0, 255, 0, 0, 255);
      source.setPixelRgba(1, 0, 0, 255, 0, 255);
      source.setPixelRgba(2, 0, 0, 0, 255, 255);
      source.setPixelRgba(0, 1, 12, 34, 56, 255);
      source.setPixelRgba(1, 1, 78, 90, 123, 255);
      source.setPixelRgba(2, 1, 255, 255, 255, 255);
    });

    test('empty mask returns a copy without loading a model', () async {
      final engine = LamaInpaintingEngine();
      final result = await engine.inpaint(
        base: source,
        removedMask: List<bool>.filled(source.width * source.height, false),
      );

      expect(identical(result, source), isFalse);
      expect(result.width, source.width);
      expect(result.height, source.height);
      for (var y = 0; y < source.height; y++) {
        for (var x = 0; x < source.width; x++) {
          expect(result.getPixel(x, y), source.getPixel(x, y));
        }
      }
      await engine.dispose();
    });

    test('rejects a mask whose dimensions do not match the source', () async {
      final engine = LamaInpaintingEngine();
      await expectLater(
        engine.inpaint(base: source, removedMask: [true]),
        throwsArgumentError,
      );
      await engine.dispose();
    });

    test('requires a loaded local model for a non-empty mask', () async {
      final engine = LamaInpaintingEngine();
      await expectLater(
        engine.inpaint(
          base: source,
          removedMask: [true, false, false, false, false, false],
        ),
        throwsStateError,
      );
      await engine.dispose();
    });

    test('never mutates the original image during no-op processing', () async {
      final before = List.generate(
        source.height,
        (y) => List.generate(source.width, (x) => source.getPixel(x, y).toString()),
      );
      final engine = LamaInpaintingEngine();
      await engine.inpaint(
        base: source,
        removedMask: List<bool>.filled(source.width * source.height, false),
      );
      final after = List.generate(
        source.height,
        (y) => List.generate(source.width, (x) => source.getPixel(x, y).toString()),
      );
      expect(after, before);
      await engine.dispose();
    });
  });
}
