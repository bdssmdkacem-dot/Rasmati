import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

/// Deterministic motion curves shared by the preview and unit tests.
/// Phase is normalized to [0, 1].
class MotionChoreography {
  const MotionChoreography._();

  static List<String> orderParts(Iterable<String> partIds) {
    const depth = <String>[
      'left_leg', 'right_leg', 'torso', 'left_arm', 'right_arm', 'head',
    ];
    final ids = List<String>.of(partIds);
    ids.sort((a, b) {
      final ai = depth.indexOf(a);
      final bi = depth.indexOf(b);
      return (ai < 0 ? depth.length : ai).compareTo(bi < 0 ? depth.length : bi);
    });
    return ids;
  }

  static Offset offsetFor(String motion, String id, double phase, Size size) {
    if (motion == 'walk') {
      final bounce = math.sin(phase * 4 * math.pi) * size.height * 0.012;
      if (id == 'left_leg' || id == 'right_leg') {
        return Offset(0, -bounce * 0.35);
      }
      if (id == 'torso' || id == 'head' || id == 'left_arm' || id == 'right_arm') {
        return Offset(0, bounce);
      }
    }
    if (motion == 'wave' && id == 'torso') {
      return Offset(math.sin(phase * 2 * math.pi) * size.width * 0.003, 0);
    }
    return Offset.zero;
  }

  static double angleFor(String motion, String id, double phase) {
    final wave = math.sin(phase * 2 * math.pi);
    switch (motion) {
      case 'wave':
        if (id == 'right_arm') return -0.48 + wave * 0.48;
        if (id == 'left_arm') return wave * 0.08;
        if (id == 'head') return math.sin(phase * 4 * math.pi) * 0.035;
        return 0;
      case 'walk':
        if (id == 'left_arm' || id == 'right_leg') return wave * 0.32;
        if (id == 'right_arm' || id == 'left_leg') return -wave * 0.32;
        if (id == 'head') return math.sin(phase * 4 * math.pi) * 0.025;
        if (id == 'torso') return math.sin(phase * 4 * math.pi) * 0.018;
        return 0;
      case 'nod':
        if (id == 'head') return math.sin(phase * 2 * math.pi) * 0.12;
        if (id == 'torso') return math.sin(phase * 2 * math.pi) * 0.018;
        return 0;
      default:
        return 0;
    }
  }
}
