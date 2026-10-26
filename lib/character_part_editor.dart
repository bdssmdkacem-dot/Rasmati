import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'rig_joint_preview.dart';

class CharacterPartEditor extends StatefulWidget {
  const CharacterPartEditor({super.key, required this.imageFile});

  final File imageFile;

  @override
  State<CharacterPartEditor> createState() => _CharacterPartEditorState();
}

class _RigPart {
  const _RigPart(this.id, this.label, this.color);

  final String id;
  final String label;
  final Color color;
}

class _RigStroke {
  _RigStroke(this.partId, this.points, this.radius);

  final String partId;
  final List<Offset> points;
  final double radius;
}

class _RigPolygon {
  _RigPolygon(this.partId, this.points);

  final String partId;
  final List<Offset> points;
}

class _CharacterPartEditorState extends State<CharacterPartEditor> {
  static const _parts = <_RigPart>[
    _RigPart('head', 'الرأس', Color(0xFFE85D75)),
    _RigPart('torso', 'الجذع', Color(0xFF6D5CE8)),
    _RigPart('left_arm', 'العضد الأيسر', Color(0xFF2D9CDB)),
    _RigPart('right_arm', 'العضد الأيمن', Color(0xFF20A477)),
    _RigPart('left_forearm', 'الساعد الأيسر', Color(0xFF56B4E9)),
    _RigPart('right_forearm', 'الساعد الأيمن', Color(0xFF63C7A3)),
    _RigPart('left_leg', 'الفخذ الأيسر', Color(0xFFE89A32)),
    _RigPart('right_leg', 'الفخذ الأيمن', Color(0xFF9B59B6)),
    _RigPart('left_lower_leg', 'الساق السفلى اليسرى', Color(0xFFF0B65C)),
    _RigPart('right_lower_leg', 'الساق السفلى اليمنى', Color(0xFFB887D0)),
  ];

  final List<_RigStroke> _strokes = [];
  final List<_RigStroke> _redo = [];
  final List<_RigPolygon> _polygons = [];
  final List<_RigPolygon> _redoPolygons = [];
  final List<Offset> _polygonDraft = [];
  bool _polygonMode = true;
  String _selectedPart = 'head';
  double _brushRadius = 0.025;
  List<Offset>? _activePoints;
  img.Image? _decoded;
  bool _loading = true;
  bool _saving = false;
  bool _showOriginal = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (!mounted) return;
      setState(() {
        _decoded = decoded;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Rect _imageRect(Size size) {
    final image = _decoded!;
    final scale = math.min(size.width / image.width, size.height / image.height);
    final width = image.width * scale;
    final height = image.height * scale;
    return Rect.fromLTWH(
      (size.width - width) / 2,
      (size.height - height) / 2,
      width,
      height,
    );
  }

  Offset? _normalisedPoint(Offset local, Size size) {
    final rect = _imageRect(size);
    if (!rect.contains(local)) return null;
    return Offset(
      ((local.dx - rect.left) / rect.width).clamp(0.0, 1.0),
      ((local.dy - rect.top) / rect.height).clamp(0.0, 1.0),
    );
  }

  void _addPolygonPoint(TapUpDetails details, Size size) {
    if (!_polygonMode) return;
    final point = _normalisedPoint(details.localPosition, size);
    if (point == null) return;
    setState(() {
      _polygonDraft.add(point);
      _redo.clear();
      _redoPolygons.clear();
    });
  }

  void _finishPolygon() {
    if (_polygonDraft.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('أضف ثلاث نقاط على الأقل لإغلاق المنطقة.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() {
      _polygons.add(_RigPolygon(_selectedPart, List.of(_polygonDraft)));
      _polygonDraft.clear();
      _redo.clear();
      _redoPolygons.clear();
    });
  }

  void _startStroke(DragStartDetails details, Size size) {
    if (_polygonMode) return;
    final point = _normalisedPoint(details.localPosition, size);
    if (point == null) return;
    setState(() {
      _activePoints = [point];
      _redo.clear();
    });
  }

  void _extendStroke(DragUpdateDetails details, Size size) {
    if (_polygonMode) return;
    final point = _normalisedPoint(details.localPosition, size);
    if (point == null || _activePoints == null) return;
    setState(() => _activePoints = [..._activePoints!, point]);
  }

  void _finishStroke(DragEndDetails details) {
    if (_polygonMode) return;
    final points = _activePoints;
    if (points == null || points.isEmpty) return;
    setState(() {
      _strokes.add(_RigStroke(_selectedPart, List.of(points), _brushRadius));
      _activePoints = null;
    });
  }

  void _undo() {
    if (_strokes.isEmpty && _polygons.isEmpty && _polygonDraft.isEmpty) return;
    setState(() {
      if (_polygonDraft.isNotEmpty) {
        _polygonDraft.clear();
      } else if (_polygons.isNotEmpty) {
        _redoPolygons.add(_polygons.removeLast());
      } else {
        _redo.add(_strokes.removeLast());
      }
    });
  }

  void _redoStroke() {
    if (_redoPolygons.isNotEmpty) {
      setState(() => _polygons.add(_redoPolygons.removeLast()));
    } else if (_redo.isNotEmpty) {
      setState(() => _strokes.add(_redo.removeLast()));
    }
  }

  Future<void> _saveRig() async {
    final source = _decoded;
    if (source == null || (_strokes.isEmpty && _polygons.isEmpty) || _saving) return;
    setState(() => _saving = true);
    try {
      final width = source.width;
      final height = source.height;
      final pixelCount = width * height;
      final ownership = List<String?>.filled(pixelCount, null);
      final masks = <String, img.Image>{};
      for (final part in _parts) {
        masks[part.id] = img.Image(width: width, height: height, numChannels: 4);
      }

      for (final stroke in _strokes) {
        final mask = masks[stroke.partId]!;
        final radius = math.max(1, (stroke.radius * math.min(width, height)).round());
        final points = stroke.points.map((point) => math.Point<int>(
          (point.dx * (width - 1)).round(),
          (point.dy * (height - 1)).round(),
        )).toList();
        if (points.length == 1) {
          img.fillCircle(mask, x: points.first.x, y: points.first.y,
              radius: radius, color: img.ColorRgba8(255, 255, 255, 255));
        } else {
          for (var i = 1; i < points.length; i++) {
            img.drawLine(mask,
              x1: points[i - 1].x, y1: points[i - 1].y,
              x2: points[i].x, y2: points[i].y,
              thickness: radius * 2,
              color: img.ColorRgba8(255, 255, 255, 255));
          }
        }
      }

      // Rasterize closed polygon regions as filled masks. These masks represent
      // complete body-part areas; strokes remain available for narrow corrections.
      for (final polygon in _polygons) {
        if (polygon.points.length < 3) continue;
        final vertices = polygon.points.map((point) => math.Point<int>(
          (point.dx * (width - 1)).round().clamp(0, width - 1).toInt(),
          (point.dy * (height - 1)).round().clamp(0, height - 1).toInt(),
        )).toList();
        img.fillPolygon(masks[polygon.partId]!, vertices: vertices,
          color: img.ColorRgba8(255, 255, 255, 255));
      }

      // Expand only stroke endpoints that meet another painted part. This
      // creates a small shared pixel bridge at shoulders, elbows, hips and
      // knees without dilating every limb into a visibly oversized silhouette.
      for (final stroke in _strokes) {
        if (stroke.points.length < 2) continue;
        final radius = math.max(1, (stroke.radius * math.min(width, height)).round());
        final jointRadius = math.max(radius + 1, (radius * 1.75).round());
        final searchRadius = radius * 3;
        final endpoints = [stroke.points.first, stroke.points.last];
        for (final endpoint in endpoints) {
          final cx = (endpoint.dx * (width - 1)).round();
          final cy = (endpoint.dy * (height - 1)).round();
          var meetsAnotherPart = false;
          for (final other in _parts) {
            if (other.id == stroke.partId) continue;
            final otherMask = masks[other.id]!;
            final minX = math.max(0, cx - searchRadius);
            final maxX = math.min(width - 1, cx + searchRadius);
            final minY = math.max(0, cy - searchRadius);
            final maxY = math.min(height - 1, cy + searchRadius);
            for (var y = minY; y <= maxY && !meetsAnotherPart; y++) {
              for (var x = minX; x <= maxX; x++) {
                final dx = x - cx;
                final dy = y - cy;
                if (dx * dx + dy * dy <= searchRadius * searchRadius &&
                    otherMask.getPixel(x, y).a > 0) {
                  meetsAnotherPart = true;
                  break;
                }
              }
            }
            if (meetsAnotherPart) break;
          }
          if (meetsAnotherPart) {
            img.fillCircle(
              masks[stroke.partId]!,
              x: cx,
              y: cy,
              radius: jointRadius,
              color: img.ColorRgba8(255, 255, 255, 255),
            );
          }
        }
      }

      // Keep a deterministic owner for removing pixels from the base image,
      // but preserve painted overlap in every part layer. Shared pixels at
      // shoulders, elbows, hips and knees help prevent transparent cracks
      // when two independently animated layers rotate away from each other.
      for (var i = 0; i < pixelCount; i++) {
        for (final part in _parts) {
          if (masks[part.id]!.getPixel(i % width, i ~/ width).a > 0) {
            ownership[i] = part.id;
            break;
          }
        }
      }

      final base = img.Image.from(source);
      final savedParts = <String>[];
      for (final part in _parts) {
        final layer = img.Image(width: width, height: height, numChannels: 4);
        var hasPixels = false;
        final partMask = masks[part.id]!;
        for (var y = 0; y < height; y++) {
          for (var x = 0; x < width; x++) {
            final index = y * width + x;
            if (partMask.getPixel(x, y).a == 0) continue;
            final pixel = source.getPixel(x, y);
            if (pixel.a.toInt() == 0) continue;
            // Unlike exclusive ownership, each painted part receives its
            // own copy of overlap pixels. The original is removed only once.
            layer.setPixelRgba(x, y, pixel.r.toInt(), pixel.g.toInt(),
                pixel.b.toInt(), pixel.a.toInt());
            if (ownership[index] == part.id) {
              base.setPixelRgba(x, y, pixel.r.toInt(), pixel.g.toInt(),
                  pixel.b.toInt(), 0);
            }
            hasPixels = true;
          }
        }
        if (hasPixels) savedParts.add(part.id);
        masks[part.id] = layer;
      }

      // A rig with only one non-empty layer cannot articulate independently.
      // Stop here instead of opening the joint editor with a misleading rig.
      if (savedParts.length < 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('حدّد جزأين مختلفين على الأقل قبل حفظ الشخصية.'),
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      final docs = await getApplicationDocumentsDirectory();
      final folder = Directory('${docs.path}/character_rig_${DateTime.now().millisecondsSinceEpoch}');
      await folder.create(recursive: true);
      await File('${folder.path}/base.png').writeAsBytes(img.encodePng(base));
      for (final partId in savedParts) {
        await File('${folder.path}/$partId.png').writeAsBytes(img.encodePng(masks[partId]!));
      }
      final manifest = {
        'version': 1,
        'sourceWidth': width,
        'sourceHeight': height,
        'parts': savedParts,
        'strokes': _strokes.length,
        'polygons': _polygons.length,
        'maskStrategy': 'filled_polygon_plus_brush_corrections',
        'sourcePreserved': true,
        'coordinateSpace': 'full_canvas_normalized',
      };
      await File('${folder.path}/manifest.json').writeAsString(jsonEncode(manifest));
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RigJointPreview(
            folder: folder,
            partIds: savedParts,
            imageWidth: width,
            imageHeight: height,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تعذّر حفظ الأجزاء. حاول مرة أخرى.'),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تجهيز أجزاء الشخصية', style: TextStyle(fontWeight: FontWeight.w900)),
          actions: [
            IconButton(tooltip: 'تراجع', onPressed: _strokes.isEmpty ? null : _undo,
                icon: const Icon(Icons.undo_rounded)),
            IconButton(tooltip: 'إعادة', onPressed: _redo.isEmpty ? null : _redoStroke,
                icon: const Icon(Icons.redo_rounded)),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _decoded == null
                ? const Center(child: Text('تعذّر قراءة الصورة.'))
                : SafeArea(
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(18, 4, 18, 10),
                          child: Text(
                            'حدّد كل قطعة على حدة: الرأس، الجذع، العضد والساعد لكل ذراع، والفخذ والساق السفلى لكل رجل. اجعل التحديدات تلتقي قليلًا عند الكوع والركبة، وتجنّب الخلفية.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF697286), height: 1.5),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            alignment: WrapAlignment.center,
                            children: _parts.map((part) {
                              final selected = _selectedPart == part.id;
                              return ChoiceChip(
                                selected: selected,
                                label: Text(part.label),
                                avatar: CircleAvatar(backgroundColor: part.color, radius: 7),
                                onSelected: (_) => setState(() => _selectedPart = part.id),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
                            ChoiceChip(label: const Text('منطقة كاملة'), selected: _polygonMode,
                              onSelected: (_) => setState(() { _polygonMode = true; _activePoints = null; })),
                            ChoiceChip(label: const Text('فرشاة تصحيح'), selected: !_polygonMode,
                              onSelected: (_) => setState(() { _polygonMode = false; _polygonDraft.clear(); })),
                            if (_polygonMode) ActionChip(label: Text('إغلاق المنطقة (${_polygonDraft.length})'),
                              avatar: const Icon(Icons.check_circle_outline, size: 18),
                              onPressed: _finishPolygon),
                          ]),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: LayoutBuilder(builder: (context, constraints) {
                              final size = Size(constraints.maxWidth, constraints.maxHeight);
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapUp: (d) => _addPolygonPoint(d, size),
                                onPanStart: (d) => _startStroke(d, size),
                                onPanUpdate: (d) => _extendStroke(d, size),
                                onPanEnd: _finishStroke,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (_showOriginal)
                                      Image.file(widget.imageFile, fit: BoxFit.contain)
                                    else
                                      const ColoredBox(color: Color(0xFFF4F1FA)),
                                    CustomPaint(
                                  painter: _RigCanvasPainter(
                                    imageWidth: _decoded!.width,
                                    imageHeight: _decoded!.height,
                                    parts: _parts,
                                    strokes: List.of(_strokes),
                                    polygons: List.of(_polygons),
                                    polygonDraft: List.of(_polygonDraft),
                                    polygonMode: _polygonMode,
                                    activePart: _selectedPart,
                                    activePoints: _activePoints == null ? null : List.of(_activePoints!),
                                    brushRadius: _brushRadius,
                                  ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Text('حجم الفرشاة'),
                                  Expanded(
                                    child: Slider(
                                      value: _brushRadius,
                                      min: 0.006,
                                      max: 0.065,
                                      divisions: 10,
                                      label: '${(_brushRadius * 100).round()}%',
                                      onChanged: (value) => setState(() => _brushRadius = value),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: _showOriginal ? 'إخفاء الرسم' : 'إظهار الرسم',
                                    onPressed: () => setState(() => _showOriginal = !_showOriginal),
                                    icon: Icon(_showOriginal ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: (_strokes.isEmpty && _polygons.isEmpty) || _saving ? null : _saveRig,
                                  icon: _saving
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.save_alt_rounded),
                                  label: Text(_saving ? 'جارٍ حفظ الأجزاء…' : 'حفظ الأجزاء للمرحلة التالية'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _RigCanvasPainter extends CustomPainter {
  _RigCanvasPainter({
    required this.imageWidth,
    required this.imageHeight,
    required this.parts,
    required this.strokes,
    required this.polygons,
    required this.polygonDraft,
    required this.polygonMode,
    required this.activePart,
    required this.activePoints,
    required this.brushRadius,
  });

  final int imageWidth;
  final int imageHeight;
  final List<_RigPart> parts;
  final List<_RigStroke> strokes;
  final List<_RigPolygon> polygons;
  final List<Offset> polygonDraft;
  final bool polygonMode;
  final String activePart;
  final List<Offset>? activePoints;
  final double brushRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / imageWidth, size.height / imageHeight);
    final rect = Rect.fromLTWH((size.width - imageWidth * scale) / 2,
        (size.height - imageHeight * scale) / 2, imageWidth * scale, imageHeight * scale);
    void drawStroke(String partId, List<Offset> points, double radius, {bool active = false}) {
      final part = parts.firstWhere((p) => p.id == partId);
      final p = Paint()
        ..color = part.color.withValues(alpha: active ? 0.78 : 0.56)
        ..strokeWidth = radius * math.min(imageWidth, imageHeight) * scale * 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final mapped = points.map((v) => Offset(rect.left + v.dx * rect.width, rect.top + v.dy * rect.height)).toList();
      if (mapped.length == 1) {
        canvas.drawCircle(mapped.first, p.strokeWidth / 2, Paint()..color = p.color);
      } else {
        final path = Path()..moveTo(mapped.first.dx, mapped.first.dy);
        for (final point in mapped.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, p);
      }
    }
    for (final polygon in polygons) {
      final part = parts.firstWhere((p) => p.id == polygon.partId);
      final mapped = polygon.points.map((v) => Offset(rect.left + v.dx * rect.width, rect.top + v.dy * rect.height)).toList();
      if (mapped.length >= 3) {
        final path = Path()..moveTo(mapped.first.dx, mapped.first.dy);
        for (final point in mapped.skip(1)) { path.lineTo(point.dx, point.dy); }
        path.close();
        canvas.drawPath(path, Paint()..color = part.color.withValues(alpha: 0.30)..style = PaintingStyle.fill);
        canvas.drawPath(path, Paint()..color = part.color.withValues(alpha: 0.95)..style = PaintingStyle.stroke..strokeWidth = 2);
      }
    }
    if (polygonMode && polygonDraft.isNotEmpty) {
      final mapped = polygonDraft.map((v) => Offset(rect.left + v.dx * rect.width, rect.top + v.dy * rect.height)).toList();
      final path = Path()..moveTo(mapped.first.dx, mapped.first.dy);
      for (final point in mapped.skip(1)) { path.lineTo(point.dx, point.dy); }
      canvas.drawPath(path, Paint()..color = parts.firstWhere((p) => p.id == activePart).color.withValues(alpha: 0.95)..style = PaintingStyle.stroke..strokeWidth = 3);
      for (final point in mapped) { canvas.drawCircle(point, 4, Paint()..color = parts.firstWhere((p) => p.id == activePart).color); }
    }
    for (final stroke in strokes) {
      drawStroke(stroke.partId, stroke.points, stroke.radius);
    }
    final points = activePoints;
    if (points != null) drawStroke(activePart, points, brushRadius, active: true);
  }

  @override
  bool shouldRepaint(covariant _RigCanvasPainter oldDelegate) =>
      oldDelegate.strokes != strokes ||
      oldDelegate.polygons != polygons ||
      oldDelegate.polygonDraft != polygonDraft ||
      oldDelegate.polygonMode != polygonMode ||
      oldDelegate.activePoints != activePoints ||
      oldDelegate.activePart != activePart ||
      oldDelegate.brushRadius != brushRadius;
}
