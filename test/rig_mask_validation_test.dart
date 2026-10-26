import 'package:flutter_test/flutter_test.dart';
import 'package:rasmati/rig_mask_validation.dart';

void main() {
  group('RigMaskValidation', () {
    test('rejects empty masks even when another part contains pixels', () {
      final errors = RigMaskValidation.validate(
        expectedPartIds: ['head', 'torso', 'left_arm'],
        opaquePixelCounts: {'head': 120, 'torso': 80, 'left_arm': 0},
      );

      expect(errors, contains('Empty or too-small mask: left_arm'));
      expect(errors, isNotEmpty);
    });

    test('rejects rigs with fewer than two usable parts', () {
      final errors = RigMaskValidation.validate(
        expectedPartIds: ['head', 'torso'],
        opaquePixelCounts: {'head': 10, 'torso': 0},
      );

      expect(errors, contains('Empty or too-small mask: torso'));
      expect(errors, contains('At least two non-empty parts are required'));
    });

    test('rejects unknown ids and invalid pixel counts', () {
      final errors = RigMaskValidation.validate(
        expectedPartIds: ['head', 'torso'],
        opaquePixelCounts: {'head': 10, 'torso': 10, 'wing': 2, 'tail': -1},
      );

      expect(errors, contains('Unknown part id: wing'));
      expect(errors, contains('Negative opaque pixel count: tail'));
    });

    test('accepts valid non-empty parts when threshold is met', () {
      expect(
        RigMaskValidation.validate(
          expectedPartIds: ['head', 'torso'],
          opaquePixelCounts: {'head': 20, 'torso': 15},
          minimumOpaquePixels: 10,
        ),
        isEmpty,
      );
    });
  });
}
