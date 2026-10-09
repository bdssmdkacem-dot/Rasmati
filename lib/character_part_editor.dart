import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class CharacterPartEditor extends StatefulWidget {
  const CharacterPartEditor({super.key, required this.imageFile});


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

class _CharacterPartEditorState extends State<CharacterPartEditor> {
  static const _parts = <_RigPart>[
    _RigPart('head', 'الرأس', Color(0xFFE85D75)),
    _RigPart('torso', 'الجذع', Color(0xFF6D5CE8)),
    _RigPart('left_arm', 'الذراع الأيسر', Color(0xFF2D9CDB)),
    _RigPart('right_arm', 'الذراع الأيمن', Color(0xFF20A477)),
    _RigPart('left_leg', 'الساق اليسرى', Color(0xFFE89A32)),
    _RigPart('right_leg', 'الساق اليمنى', Color(0xFF9B59B6)),
  ];

  final List<_RigStroke> _strokes = [];
  final List<_RigStroke> _redo = [];
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

  void _startStroke(DragStartDetails details, Size size) {
    final point = _normalisedPoint(details.localPosition, size);
    if (point == null) return;
    setState(() {
      _activePoints = [point];
      _redo.clear();
    });
  }

  void _extendStroke(DragUpdateDetails details, Size size) {
    final point = _normalisedPoint(details.localPosition, size);
    if (point == null || _activePoints == null) return;
    setState(() => _activePoints!.add(point));
  }

  void _finishStroke(DragEndDetails details) {
    final points = _activePoints;
    if (points == null || points.isEmpty) return;
    setState(() {
      _strokes.add(_RigStroke(_selectedPart, List.of(points), _brushRadius));
      _activePoints = null;
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _redo.add(_strokes.removeLast()));
  }

  void _redoStroke() {
    if (_redo.isEmpty) return;
    setState(() => _strokes.add(_redo.removeLast()));
  }

  Future<void> _saveRig() async {
    final source = _decoded;
    if (source == null || _strokes.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final width = source.width;
      final height = source.height;
      final pixelCount = width * height;
      final ownership = List<String?>.filled(pixelCount, null);
      final radii = <String, int>{};
      final masks = <String, img.Image>{};
      for (final part in _parts) {
        masks[part.id] = img.Image(width: width, height: height, numChannels: 4);
      }

      for (final stroke in _strokes) {
        final mask = masks[stroke.partId]!;
        final radius = math.max(1, (stroke.radius * math.min(width, height)).round());
        radii[stroke.partId] = radius;
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

      // Deterministic ownership: a pixel belongs to the first part in the
      // manifest order whose painted mask covers it. All layers keep the
      // source canvas dimensions so their pixels remain perfectly aligned.
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
        for (var y = 0; y < height; y++) {
          for (var x = 0; x < width; x++) {
            final index = y * width + x;
            if (ownership[index] == part.id) {
              final pixel = source.getPixel(x, y);
              layer.setPixelRgba(x, y, pixel.r.toInt(), pixel.g.toInt(),
                  pixel.b.toInt(), pixel.a.toInt());
              base.setPixelRgba(x, y, pixel.r.toInt(), pixel.g.toInt(),
                  pixel.b.toInt(), 0);
              hasPixels = true;
            }
          }
        }
        if (hasPixels) savedParts.add(part.id);
        masks[part.id] = layer;
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
        'coordinateSpace': 'full_canvas_normalized',
      };
      await File('${folder.path}/manifest.json').writeAsString(jsonEncode(manifest));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('حُفظت الأجزاء محليًا (${savedParts.length}) — جاهزة لمرحلة المفاصل.'),
        behavior: SnackBarBehavior.floating,
      ));
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
                            'لوّن فوق الجزء الذي تريد تحريكه. استخدم أجزاء منفصلة ولا تمرّر الفرشاة على الخلفية.',
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
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: LayoutBuilder(builder: (context, constraints) {
                              final size = Size(constraints.maxWidth, constraints.maxHeight);
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
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
                                    strokes: _strokes,
                                    activePart: _selectedPart,
                                    activePoints: _activePoints,
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
                                  onPressed: _strokes.isEmpty || _saving ? null : _saveRig,
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
    required this.activePart,
    required this.activePoints,
    required this.brushRadius,
  });

  final int imageWidth;
  final int imageHeight;
  final List<_RigPart> parts;
  final List<_RigStroke> strokes;
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
    for (final stroke in strokes) {
      drawStroke(stroke.partId, stroke.points, stroke.radius);
    }
    final points = activePoints;
    if (points != null) drawStroke(activePart, points, brushRadius, active: true);
  }

  @override
  bool shouldRepaint(covariant _RigCanvasPainter oldDelegate) =>
      oldDelegate.strokes != strokes ||
      oldDelegate.activePoints != activePoints ||
      oldDelegate.activePart != activePart ||
      oldDelegate.brushRadius != brushRadius;
}
