/// Preflight checks for rasterized character rig masks.
class RigMaskValidation {
  RigMaskValidation._();

  /// Returns actionable errors before a saved rig is allowed into motion preview.
  static List<String> validate({
    required Iterable<String> expectedPartIds,
    required Map<String, int> opaquePixelCounts,
    int minimumOpaquePixels = 1,
  }) {
    final expected = expectedPartIds.toSet();
    final errors = <String>[];

    for (final entry in opaquePixelCounts.entries) {
      if (!expected.contains(entry.key)) {
        errors.add('Unknown part id: ${entry.key}');
      }
      if (entry.value < 0) {
        errors.add('Negative opaque pixel count: ${entry.key}');
      }
    }

    final nonEmpty = <String>{};
    for (final id in expected) {
      final count = opaquePixelCounts[id] ?? 0;
      if (count < minimumOpaquePixels) {
        errors.add('Empty or too-small mask: $id');
      } else {
        nonEmpty.add(id);
      }
    }

    if (nonEmpty.length < 2) {
      errors.add('At least two non-empty parts are required');
    }
    return List.unmodifiable(errors);
  }
}
