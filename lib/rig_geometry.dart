import 'dart:ui' show Offset;

/// Shared default joint positions in normalized full-canvas coordinates.
/// The origin is the image's top-left corner, so y increases downward.
class RigGeometry {
  const RigGeometry._();

  static Offset defaultPivot(String id) {
    switch (id) {
      case 'head':
        return const Offset(.5, .27);
      case 'left_arm':
        return const Offset(.30, .37);
      case 'right_arm':
        return const Offset(.70, .37);
      case 'left_forearm':
        return const Offset(.28, .45);
      case 'right_forearm':
        return const Offset(.72, .45);
      case 'left_leg':
        return const Offset(.43, .68);
      case 'right_leg':
        return const Offset(.57, .68);
      case 'left_lower_leg':
        return const Offset(.43, .80);
      case 'right_lower_leg':
        return const Offset(.57, .80);
      default:
        return const Offset(.5, .48);
    }
  }

  static bool isNormalized(Offset point) =>
      point.dx >= 0 && point.dx <= 1 && point.dy >= 0 && point.dy <= 1;
}
