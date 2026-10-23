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

  /// Parent links for the current articulated 2D skeleton.
  /// Child transforms are applied in local joint space, then inherited from
  /// this parent so elbows and knees follow shoulder/hip rotation.
  static String? parentPart(String id) {
    switch (id) {
      case 'head':
      case 'left_arm':
      case 'right_arm':
      case 'left_leg':
      case 'right_leg':
        return 'torso';
      case 'left_forearm':
        return 'left_arm';
      case 'right_forearm':
        return 'right_arm';
      case 'left_lower_leg':
        return 'left_leg';
      case 'right_lower_leg':
        return 'right_leg';
      default:
        return null;
    }
  }

  /// Returns the ordered ancestors from the immediate parent to the root.
  /// The guard prevents a malformed future rig definition from looping forever.
  static List<String> ancestorsOf(String id) {
    final result = <String>[];
    final visited = <String>{id};
    var parent = parentPart(id);
    while (parent != null && visited.add(parent)) {
      result.add(parent);
      parent = parentPart(parent);
    }
    return result;
  }

  static bool isNormalized(Offset point) =>
      point.dx >= 0 && point.dx <= 1 && point.dy >= 0 && point.dy <= 1;
}
