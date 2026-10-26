import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Patch-based, edge-aware inpainting for rig cutouts.
///
/// Instead of averaging colors, this copies matching intact image patches into
/// the hole. Candidate patches must be fully known; matching uses visible
/// pixels around the target patch, and boundary priority favors continuation
/// of strong local gradients. This is a classical exemplar-based method, not a
/// learned semantic model: it cannot reliably invent hidden anatomy.
class TransparentRegionInpainting {
  TransparentRegionInpainting._();

  static img.Image fillRemovedPixels({
    required img.Image base,
    required List<bool> removed,
    int maxIterations = 500,
    int patchRadius = 3,
    int maxSourceCandidates = 1600,
  }) {
    final width = base.width;
    final height = base.height;
    if (removed.length != width * height) {
      throw ArgumentError('removed mask must match image dimensions');
    }
    if (maxIterations < 1) throw ArgumentError.value(maxIterations, 'maxIterations');
    if (patchRadius < 1) throw ArgumentError.value(patchRadius, 'patchRadius');
    if (maxSourceCandidates < 1) {
      throw ArgumentError.value(maxSourceCandidates, 'maxSourceCandidates');
    }

    final result = img.Image.from(base);
    final known = List<bool>.generate(width * height, (i) {
      final p = result.getPixel(i % width, i ~/ width);
      return !removed[i] && p.a > 0;
    });
    final targets = List<bool>.generate(width * height, (i) => removed[i]);
    final radius = patchRadius;
    final stride = math.max(1, math.sqrt(width * height / maxSourceCandidates).floor());

    bool inBounds(int x, int y) => x >= 0 && y >= 0 && x < width && y < height;
    int idx(int x, int y) => y * width + x;

    // Source patch centers are sampled on a grid and are accepted only if the
    // complete patch comes from intact, opaque pixels.
    final sources = <(int, int)>[];
    for (var y = radius; y < height - radius; y += stride) {
      for (var x = radius; x < width - radius; x += stride) {
        var valid = true;
        for (var py = y - radius; py <= y + radius && valid; py++) {
          for (var px = x - radius; px <= x + radius; px++) {
            if (!known[idx(px, py)]) { valid = false; break; }
          }
        }
        if (valid) sources.add((x, y));
      }
    }
    if (sources.isEmpty) {
      // Tiny images may not fit a full patch; use all valid source pixels.
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          if (known[idx(x, y)]) sources.add((x, y));
        }
      }
    }
    if (sources.isEmpty) return result;

    final frontier = <int>{};
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = idx(x, y);
        if (!targets[i] || known[i]) continue;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            if (inBounds(x + dx, y + dy) && known[idx(x + dx, y + dy)]) {
              frontier.add(i);
            }
          }
        }
      }
    }

    for (var iteration = 0; iteration < maxIterations && frontier.isNotEmpty; iteration++) {
      var bestX = -1, bestY = -1, bestPriority = -1.0;
      // Pick a fill-frontier pixel. A high gradient near the boundary increases
      // priority so line/edge structures get handled before flat regions.
      for (final targetIndex in frontier) {
        if (known[targetIndex]) continue;
        final x = targetIndex % width, y = targetIndex ~/ width;
        var knownNeighbors = 0;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            if ((dx == 0 && dy == 0) || !inBounds(x + dx, y + dy)) continue;
            if (known[idx(x + dx, y + dy)]) knownNeighbors++;
          }
        }
        if (knownNeighbors == 0) continue;
        final left = inBounds(x - 1, y) && known[idx(x - 1, y)]
            ? result.getPixel(x - 1, y).luminance.toDouble() : 0.0;
        final right = inBounds(x + 1, y) && known[idx(x + 1, y)]
            ? result.getPixel(x + 1, y).luminance.toDouble() : left;
        final up = inBounds(x, y - 1) && known[idx(x, y - 1)]
            ? result.getPixel(x, y - 1).luminance.toDouble() : 0.0;
        final down = inBounds(x, y + 1) && known[idx(x, y + 1)]
            ? result.getPixel(x, y + 1).luminance.toDouble() : up;
        final gradient = (right - left).abs() + (down - up).abs();
        final priority = knownNeighbors + gradient / 255.0;
        if (priority > bestPriority) {
          bestPriority = priority;
          bestX = x;
          bestY = y;
        }
      }
      if (bestX < 0) break;

      var sourceX = -1, sourceY = -1, bestCost = double.infinity;
      for (final (cx, cy) in sources) {
        var cost = 0.0, compared = 0;
        for (var dy = -radius; dy <= radius; dy++) {
          for (var dx = -radius; dx <= radius; dx++) {
            final tx = bestX + dx, ty = bestY + dy;
            final sx = cx + dx, sy = cy + dy;
            if (!inBounds(tx, ty) || !inBounds(sx, sy)) continue;
            if (!known[idx(tx, ty)]) continue;
            final a = result.getPixel(tx, ty);
            final b = result.getPixel(sx, sy);
            final dr = a.r.toDouble() - b.r.toDouble();
            final dg = a.g.toDouble() - b.g.toDouble();
            final db = a.b.toDouble() - b.b.toDouble();
            cost += dr * dr + dg * dg + db * db;
            compared++;
          }
        }
        if (compared == 0) continue;
        cost /= compared;
        if (cost < bestCost) {
          bestCost = cost;
          sourceX = cx;
          sourceY = cy;
        }
      }
      if (sourceX < 0) break;

      var filledAny = false;
      final newlyFilled = <int>[];
      for (var dy = -radius; dy <= radius; dy++) {
        for (var dx = -radius; dx <= radius; dx++) {
          final tx = bestX + dx, ty = bestY + dy;
          final sx = sourceX + dx, sy = sourceY + dy;
          if (!inBounds(tx, ty) || !inBounds(sx, sy)) continue;
          final targetIndex = idx(tx, ty);
          if (!targets[targetIndex] || known[targetIndex]) continue;
          final pixel = result.getPixel(sx, sy);
          result.setPixelRgba(tx, ty, pixel.r.toInt(), pixel.g.toInt(),
              pixel.b.toInt(), pixel.a.toInt());
          known[targetIndex] = true;
          newlyFilled.add(targetIndex);
          frontier.remove(targetIndex);
          filledAny = true;
        }
      }
      for (final filledIndex in newlyFilled) {
        final fx = filledIndex % width, fy = filledIndex ~/ width;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            final nx = fx + dx, ny = fy + dy;
            if (!inBounds(nx, ny)) continue;
            final ni = idx(nx, ny);
            if (targets[ni] && !known[ni]) frontier.add(ni);
          }
        }
      }
      // Prevent a malformed mask/source configuration from spinning forever.
      if (!filledAny) {
        final targetIndex = idx(bestX, bestY);
        final fallback = result.getPixel(bestX, bestY);
        result.setPixelRgba(bestX, bestY, fallback.r.toInt(), fallback.g.toInt(),
            fallback.b.toInt(), 255);
        known[targetIndex] = true;
        frontier.remove(targetIndex);
      }
    }
    return result;
  }
}
