import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

/// Deterministic, eased motion curves shared by the preview and unit tests.
/// Phase is normalized to [0, 1]. Angles are radians.
class MotionChoreography {
  const MotionChoreography._();

  static List<String> orderParts(Iterable<String> partIds) {
    const depth = <String>[
      'left_lower_leg', 'right_lower_leg', 'left_leg', 'right_leg',
      'torso', 'left_arm', 'right_arm', 'left_forearm', 'right_forearm', 'head',
    ];
    final ids = List<String>.of(partIds);
    ids.sort((a, b) {
      final ai = depth.indexOf(a);
      final bi = depth.indexOf(b);
      return (ai < 0 ? depth.length : ai).compareTo(bi < 0 ? depth.length : bi);
    });
    return ids;
  }

  static double _unit(double value) => value.clamp(0.0, 1.0);

  static double _smooth(double value) {
    final t = _unit(value);
    return t * t * (3 - 2 * t);
  }

  static double _window(double phase, double start, double end, double fade) {
    if (phase <= start || phase >= end) return 0;
    final rise = _smooth((phase - start) / fade);
    final fall = _smooth((end - phase) / fade);
    return math.min(rise, fall);
  }

  static Offset offsetFor(String motion, String id, double phase, Size size) {
    final p = _unit(phase);
    if (motion == 'walk') {
      // Two-footfall cycle: body bounce is twice the leg swing frequency.
      final stride = math.sin(p * 2 * math.pi);
      final bounce = (1 - math.cos(p * 4 * math.pi)) * 0.5;
      if (id == 'torso') {
        return Offset(stride * size.width * 0.004, -bounce * size.height * 0.009);
      }
      if (id == 'head') {
        return Offset(stride * size.width * 0.002, -bounce * size.height * 0.006);
      }
      if (id == 'left_arm' || id == 'right_arm' ||
          id == 'left_forearm' || id == 'right_forearm') {
        return Offset(0, -bounce * size.height * 0.002);
      }
      if (id == 'left_lower_leg' || id == 'right_lower_leg') {
        return Offset(0, -bounce * size.height * 0.001);
      }
    }
    if (motion == 'wave' && id == 'torso') {
      final settle = math.sin(p * 2 * math.pi);
      return Offset(settle * size.width * 0.004, 0);
    }
    if (motion == 'nod' && id == 'torso') {
      final nod = _window(p, 0.12, 0.82, 0.22);
      return Offset(0, nod * size.height * 0.003);
    }
    return Offset.zero;
  }

  static double angleFor(String motion, String id, double phase) {
    final p = _unit(phase);
    switch (motion) {
      case 'wave':
        // Raise, wave several times, then lower the arm instead of looping
        // a permanently bent arm through an unnatural sine curve.
        if (id == 'right_arm') {
          final raise = _smooth((p - 0.06) / 0.24);
          final lower = 1 - _smooth((p - 0.68) / 0.22);
          final hold = raise * lower;
          final waving = _window(p, 0.25, 0.73, 0.10);
          final oscillation = math.sin((p - 0.25) / 0.48 * 6 * math.pi);
          return -1.02 * hold + 0.22 * oscillation * waving;
        }
        if (id == 'right_forearm') {
          final raise = _smooth((p - 0.06) / 0.24);
          final lower = 1 - _smooth((p - 0.68) / 0.22);
          final hold = raise * lower;
          final waving = _window(p, 0.25, 0.73, 0.10);
          return -0.34 * hold +
              0.10 * math.sin((p - 0.25) / 0.48 * 6 * math.pi) * waving;
        }
        if (id == 'left_arm') return 0.045 * math.sin(p * 2 * math.pi);
        if (id == 'left_forearm') return 0.025 * math.sin(p * 2 * math.pi);
        if (id == 'head') return -0.035 * _window(p, 0.15, 0.75, 0.18);
        if (id == 'torso') return 0.018 * math.sin(p * 2 * math.pi);
        return 0;
      case 'walk':
        final stride = math.sin(p * 2 * math.pi);
        if (id == 'left_arm' || id == 'right_leg') return stride * 0.42;
        if (id == 'right_arm' || id == 'left_leg') return -stride * 0.42;
        if (id == 'left_forearm') return stride * 0.16;
        if (id == 'right_forearm') return -stride * 0.16;
        if (id == 'left_lower_leg') return stride * 0.20;
        if (id == 'right_lower_leg') return -stride * 0.20;
        if (id == 'head') return -stride * 0.018;
        if (id == 'torso') return stride * 0.012;
        return 0;
      case 'nod':
        if (id == 'head') {
          // One clear down-and-up nod with a short neutral pause at either end.
          final nod = _window(p, 0.12, 0.82, 0.22);
          return 0.16 * nod * math.sin(math.pi * _unit((p - 0.12) / 0.70));
        }
        if (id == 'torso') return 0.012 * _window(p, 0.12, 0.82, 0.22);
        return 0;
      default:
        return 0;
    }
  }
}
