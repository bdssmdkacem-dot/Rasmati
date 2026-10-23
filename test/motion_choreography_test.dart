import 'dart:ui' show Offset, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:rasmati/motion_choreography.dart';

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

    test('walk coordinates opposite limb swings with body bounce', () {
      final torso = MotionChoreography.offsetFor('walk', 'torso', 0.125, size);
      final head = MotionChoreography.offsetFor('walk', 'head', 0.125, size);
      expect(torso.dy, lessThan(0));
      expect(head.dy, lessThan(0));
      expect(
        MotionChoreography.angleFor('walk', 'left_arm', 0.25),
        closeTo(-MotionChoreography.angleFor('walk', 'right_arm', 0.25), 0.0001),
      );
      expect(
        MotionChoreography.angleFor('walk', 'left_leg', 0.25),
        closeTo(-MotionChoreography.angleFor('walk', 'right_leg', 0.25), 0.0001),
      );
    });

    test('wave raises the arm, oscillates during the hold, and returns to rest', () {
      expect(MotionChoreography.angleFor('wave', 'right_arm', 0), 0);
      expect(MotionChoreography.angleFor('wave', 'right_arm', 0.45), lessThan(-0.5));
      expect(MotionChoreography.angleFor('wave', 'right_arm', 0.99), 0);
      expect(MotionChoreography.angleFor('wave', 'torso', 0.25), 0);
      expect(MotionChoreography.offsetFor('wave', 'torso', 0.25, size).dx, greaterThan(0));
    });

    test('nod is a bounded gesture and unknown motion remains neutral', () {
      final nod = MotionChoreography.angleFor('nod', 'head', 0.25);
      expect(nod, greaterThan(0));
      expect(nod, lessThanOrEqualTo(0.16));
      expect(MotionChoreography.angleFor('nod', 'left_arm', 0.25), 0);
      expect(MotionChoreography.angleFor('unknown', 'head', 0.25), 0);
      expect(MotionChoreography.offsetFor('unknown', 'head', 0.25, size), Offset.zero);
    });

    test('all motion curves remain finite at cycle boundaries', () {
      for (final motion in ['wave', 'walk', 'nod', 'unknown']) {
        for (final phase in [0.0, 0.25, 0.5, 0.75, 1.0]) {
          for (final part in [
            'head', 'torso', 'left_arm', 'right_arm', 'left_leg', 'right_leg',
          ]) {
            expect(MotionChoreography.angleFor(motion, part, phase).isFinite, isTrue);
            final offset = MotionChoreography.offsetFor(motion, part, phase, size);
            expect(offset.dx.isFinite && offset.dy.isFinite, isTrue);
          }
        }
      }
    });
  });
}
