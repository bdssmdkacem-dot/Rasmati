import 'package:flutter_test/flutter_test.dart';
import 'package:rasmati/motion_choreography.dart';
import 'dart:ui' show Offset, Size;

void main() {
  group('MotionChoreography.orderParts', () {
    test('puts rear limbs behind torso and head while retaining unknown parts', () {
      expect(
        MotionChoreography.orderParts([
          'head', 'right_arm', 'unknown', 'torso', 'left_leg', 'left_arm', 'right_leg',
        ]),
        ['left_leg', 'right_leg', 'torso', 'left_arm', 'right_arm', 'head', 'unknown'],
      );
    });

    test('does not mutate the caller list', () {
      final source = ['head', 'left_leg'];
      MotionChoreography.orderParts(source);
      expect(source, ['head', 'left_leg']);
    });
  });

  group('MotionChoreography motion curves', () {
    const size = Size(200, 400);

    test('walk offsets torso and limbs in a coordinated cycle', () {
      final torso = MotionChoreography.offsetFor('walk', 'torso', 0.125, size);
      final leg = MotionChoreography.offsetFor('walk', 'left_leg', 0.125, size);
      expect(torso.dy, isNot(0));
      expect(leg.dy, isNot(0));
      expect(torso.dy.sign, -leg.dy.sign);
    });

    test('wave affects the waving arm and keeps unrelated parts stable', () {
      expect(MotionChoreography.angleFor('wave', 'right_arm', 0.0), closeTo(-0.48, 0.0001));
      expect(MotionChoreography.angleFor('wave', 'torso', 0.25), 0);
      expect(MotionChoreography.offsetFor('wave', 'torso', 0.25, size).dx, greaterThan(0));
    });

    test('nod primarily rotates the head and unknown motion is neutral', () {
      expect(MotionChoreography.angleFor('nod', 'head', 0.25), closeTo(0.12, 0.0001));
      expect(MotionChoreography.angleFor('nod', 'left_arm', 0.25), 0);
      expect(MotionChoreography.angleFor('unknown', 'head', 0.25), 0);
      expect(MotionChoreography.offsetFor('unknown', 'head', 0.25, size), Offset.zero);
    });
  });
}
