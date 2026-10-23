import 'package:flutter_test/flutter_test.dart';
import 'package:rasmati/rig_geometry.dart';

void main() {
  group('RigGeometry.parentPart', () {
    test('connects each forearm to its upper arm and each lower leg to its thigh', () {
      expect(RigGeometry.parentPart('left_forearm'), 'left_arm');
      expect(RigGeometry.parentPart('right_forearm'), 'right_arm');
      expect(RigGeometry.parentPart('left_lower_leg'), 'left_leg');
      expect(RigGeometry.parentPart('right_lower_leg'), 'right_leg');
      expect(RigGeometry.parentPart('head'), isNull);
      expect(RigGeometry.parentPart('torso'), isNull);
    });
  });

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
        'head', 'torso', 'left_arm', 'right_arm', 'left_forearm', 'right_forearm',
        'left_leg', 'right_leg', 'left_lower_leg', 'right_lower_leg',
      ]) {
        expect(RigGeometry.isNormalized(RigGeometry.defaultPivot(id)), isTrue,
            reason: '$id pivot should be normalized');
      }
      expect(RigGeometry.defaultPivot('torso'), const Offset(.5, .48));
      expect(RigGeometry.defaultPivot('left_forearm'), const Offset(.28, .45));
      expect(RigGeometry.defaultPivot('right_lower_leg'), const Offset(.57, .80));
    });
  });
}
