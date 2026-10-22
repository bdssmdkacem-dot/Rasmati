import 'package:flutter_test/flutter_test.dart';
import 'package:rasmati/rig_geometry.dart';
import 'dart:ui' show Offset;

void main() {
  group('RigGeometry.defaultPivot', () {
    test('places default head, shoulders, and hips in top-to-bottom order', () {
      final head = RigGeometry.defaultPivot('head');
      final leftShoulder = RigGeometry.defaultPivot('left_arm');
      final rightShoulder = RigGeometry.defaultPivot('right_arm');
      final leftHip = RigGeometry.defaultPivot('left_leg');
      final rightHip = RigGeometry.defaultPivot('right_leg');

      expect(head.dy, lessThan(leftShoulder.dy));
      expect(head.dy, lessThan(rightShoulder.dy));
      expect(leftShoulder.dy, lessThan(leftHip.dy));
      expect(rightShoulder.dy, lessThan(rightHip.dy));
    });

    test('keeps every default pivot inside normalized canvas coordinates', () {
      for (final id in [
        'head', 'torso', 'left_arm', 'right_arm', 'left_leg', 'right_leg',
      ]) {
        expect(RigGeometry.isNormalized(RigGeometry.defaultPivot(id)), isTrue,
            reason: '$id pivot should be normalized');
      }
      expect(RigGeometry.defaultPivot('torso'), const Offset(.5, .48));
    });
  });
}
