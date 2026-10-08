import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Local-only paper/background cleanup with a manual erase/restore brush.
class BackgroundEditor extends StatefulWidget {
  const BackgroundEditor({super.key, required this.imageFile});

  final File imageFile;

  @override
  State<BackgroundEditor> createState() => _BackgroundEditorState();
}

enum BrushMode { erase, restore }

class _BrushStroke {
  const _BrushStroke(this.points, this.mode, this.radius);
  final List<Offset> points;
  final BrushMode mode;
  final double radius;
}

class _BackgroundEditorState extends State<BackgroundEditor> {
  static const _purple = Color(0xFF7558E8);
  final List<_BrushStroke> _strokes = [];
  final List<_BrushStroke> _redo = [];
  BrushMode _mode = BrushMode.erase;
  double _threshold = 34;
  bool _autoRemove = true;
  bool _busy = false;
  Size? _canvasSize;
  Size? _imageSize;
  Offset? _lastPoint;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    try {
      final decoded = img.decodeImage(await widget.imageFile.readAsBytes());
      if (mounted && decoded != null) {
        setState(() => _imageSize = Size(decoded.width.toDouble(), decoded.height.toDouble()));
      }
    } catch (_) {
      // The apply action reports a readable error if the image cannot decode.
    }
  }

  Rect _imageRect(Size size) {
    final imageSize = _imageSize;
    if (imageSize == null || imageSize.width == 0 || imageSize.height == 0) {
      return Offset.zero & size;
    }
    final scale = math.min(size.width / imageSize.width, size.height / imageSize.height);
    final width = imageSize.width * scale;
    final height = imageSize.height * scale;
    return Rect.fromLTWH((size.width - width) / 2, (size.height - height) / 2, width, height);
  }

  void _beginStroke(Offset point) {
    setState(() {
      _redo.clear();
      _strokes.add(_BrushStroke([point], _mode, 0.025));
      _lastPoint = point;
    });
  }

  void _extendStroke(Offset point) {
    if (_lastPoint == null || _strokes.isEmpty) return;
    final previous = _lastPoint!;
    if ((point - previous).distance < 0.002) return;
    setState(() {
      _strokes.last.points.add(point);
      _lastPoint = point;
    });
  }

  void _endStroke() => _lastPoint = null;

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _redo.add(_strokes.removeLast()));
  }

  void _redoStroke() {
    if (_redo.isEmpty) return;
    setState(() => _strokes.add(_redo.removeLast()));
  }

  Future<File?> _apply() async {
    if (_busy) return null;
    setState(() => _busy = true);
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw const FormatException('Unsupported image');
      final source = img.bakeOrientation(decoded);
      final width = source.width;
      final height = source.height;
      final count = width * height;
      final alpha = Uint8List(count);
      for (var i = 0; i < count; i++) {
        alpha[i] = 255;
      }

      // Flood-fill only paper-like pixels connected to the image edges. This
      // avoids deleting enclosed white details inside a drawing.
      if (_autoRemove) {
        final queue = Int32List(count);
        var head = 0;
        var tail = 0;
        final visited = Uint8List(count);
        bool paper(int x, int y) {
          final p = source.getPixel(x, y);
          final r = p.r.toDouble();
          final g = p.g.toDouble();
          final b = p.b.toDouble();
          final minChannel = math.min(r, math.min(g, b));
          final maxChannel = math.max(r, math.max(g, b));
          final brightness = (r + g + b) / 3;
          return brightness >= 224 - _threshold &&
              maxChannel - minChannel <= 54 + _threshold;
        }

        void enqueue(int x, int y) {
          if (x < 0 || y < 0 || x >= width || y >= height) return;
          final index = y * width + x;
          if (visited[index] != 0 || !paper(x, y)) return;
          visited[index] = 1;
          queue[tail++] = index;
        }

        for (var x = 0; x < width; x++) {
          enqueue(x, 0);
          if (height > 1) enqueue(x, height - 1);
        }
        for (var y = 1; y < height - 1; y++) {
          enqueue(0, y);
          if (width > 1) enqueue(width - 1, y);
        }
        while (head < tail) {
          final index = queue[head++];
          alpha[index] = 0;
          final x = index % width;
          final y = index ~/ width;
          enqueue(x - 1, y);
          enqueue(x + 1, y);
          enqueue(x, y - 1);
          enqueue(x, y + 1);
        }
      }

      // Strokes are normalized to the image area, so edits scale to any image.
      final canvas = _canvasSize;
      if (canvas != null && canvas.width > 0 && canvas.height > 0) {
        for (final stroke in _strokes) {
          final radiusX = math.max(1, (stroke.radius * width).round()).toInt();
          final radiusY = math.max(1, (stroke.radius * height).round()).toInt();
          for (final point in stroke.points) {
            final cx = (point.dx * width).round().clamp(0, width - 1).toInt();
            final cy = (point.dy * height).round().clamp(0, height - 1).toInt();
            final rx = radiusX;
            final ry = radiusY;
            for (var y = math.max(0, cy - ry).toInt(); y <= math.min(height - 1, cy + ry).toInt(); y++) {
              for (var x = math.max(0, cx - rx).toInt(); x <= math.min(width - 1, cx + rx).toInt(); x++) {
                final dx = (x - cx) / rx;
                final dy = (y - cy) / ry;
                if (dx * dx + dy * dy > 1) continue;
                alpha[y * width + x] = stroke.mode == BrushMode.erase ? 0 : 255;
              }
            }
          }
        }
      }

      final output = img.Image(width: width, height: height, numChannels: 4);
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final p = source.getPixel(x, y);
          output.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), alpha[y * width + x]);
        }
      }
      final directory = await getTemporaryDirectory();
      final outFile = File('${directory.path}/rasmati_clean_${DateTime.now().microsecondsSinceEpoch}.png');
      await outFile.writeAsBytes(img.encodePng(output), flush: true);
      if (!mounted) return outFile;
      Navigator.of(context).pop(outFile);
      return outFile;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر معالجة الصورة. جرّب صورة أخرى.')),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تنظيف خلفية الرسمة', style: TextStyle(fontWeight: FontWeight.w900)),
          actions: [
            IconButton(onPressed: _strokes.isEmpty ? null : _undo, tooltip: 'تراجع', icon: const Icon(Icons.undo_rounded)),
            IconButton(onPressed: _redo.isEmpty ? null : _redoStroke, tooltip: 'إعادة', icon: const Icon(Icons.redo_rounded)),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 4, 18, 12),
                child: Text('أزل لون الورقة تلقائيًا، ثم صحّح النتيجة بفرشاة المسح أو الاستعادة. تتم المعالجة على الجهاز.', style: TextStyle(color: Color(0xFF778095), height: 1.5)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(builder: (context, constraints) {
                    _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const _Checkerboard(),
                          Image.file(widget.imageFile, fit: BoxFit.contain),
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onPanStart: (details) {
                              final point = _normalized(details.localPosition);
                              if (point != null) _beginStroke(point);
                            },
                            onPanUpdate: (details) {
                              final point = _normalized(details.localPosition);
                              if (point != null) _extendStroke(point);
                            },
                            onPanEnd: (_) => _endStroke(),
                            child: CustomPaint(painter: _StrokePainter(_strokes, _imageRect(_canvasSize ?? Size.zero)),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _autoRemove,
                      onChanged: (value) => setState(() => _autoRemove = value),
                      title: const Text('إزالة الورقة الفاتحة تلقائيًا', style: TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: const Text('تبدأ من الحواف لتقليل حذف التفاصيل البيضاء داخل الرسم.'),
                    ),
                    Row(children: [
                      const Text('حساسية الإزالة', style: TextStyle(fontWeight: FontWeight.w800)),
                      Expanded(child: Slider(value: _threshold, min: 0, max: 55, divisions: 11, label: _threshold.round().toString(), onChanged: (value) => setState(() => _threshold = value))),
                    ]),
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(onPressed: () => setState(() => _mode = BrushMode.erase), icon: const Icon(Icons.brush_rounded), label: const Text('مسح'), style: OutlinedButton.styleFrom(foregroundColor: _mode == BrushMode.erase ? _purple : const Color(0xFF253047), side: BorderSide(color: _mode == BrushMode.erase ? _purple : const Color(0xFFE3DFEB))))),
                      const SizedBox(width: 10),
                      Expanded(child: OutlinedButton.icon(onPressed: () => setState(() => _mode = BrushMode.restore), icon: const Icon(Icons.restore_rounded), label: const Text('استعادة'), style: OutlinedButton.styleFrom(foregroundColor: _mode == BrushMode.restore ? _purple : const Color(0xFF253047), side: BorderSide(color: _mode == BrushMode.restore ? _purple : const Color(0xFFE3DFEB))))),
                    ]),
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _busy ? null : _apply, icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_rounded), label: Text(_busy ? 'جارٍ تجهيز الصورة…' : 'تطبيق الخلفية والانتقال للحركة'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: _purple, textStyle: const TextStyle(fontWeight: FontWeight.w900)))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Offset? _normalized(Offset point) {
    final rect = _imageRect(_canvasSize ?? Size.zero);
    if (!rect.contains(point) || rect.width == 0 || rect.height == 0) return null;
    return Offset(((point.dx - rect.left) / rect.width).clamp(0.0, 1.0).toDouble(), ((point.dy - rect.top) / rect.height).clamp(0.0, 1.0).toDouble());
  }
}

class _StrokePainter extends CustomPainter {
  const _StrokePainter(this.strokes, this.imageRect);
  final List<_BrushStroke> strokes;
  final Rect imageRect;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.mode == BrushMode.erase ? const Color(0x667558E8) : const Color(0x6671C99B)
        ..strokeWidth = math.max(18, imageRect.shortestSide * stroke.radius * 2).toDouble()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (stroke.points.length == 1) {
        canvas.drawCircle(Offset(imageRect.left + stroke.points.first.dx * imageRect.width, imageRect.top + stroke.points.first.dy * imageRect.height), paint.strokeWidth / 2, paint..style = PaintingStyle.fill);
      } else {
        final path = Path()..moveTo(imageRect.left + stroke.points.first.dx * imageRect.width, imageRect.top + stroke.points.first.dy * imageRect.height);
        for (final point in stroke.points.skip(1)) {
          path.lineTo(imageRect.left + point.dx * imageRect.width, imageRect.top + point.dy * imageRect.height);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) => true;
}

class _Checkerboard extends StatelessWidget {
  const _Checkerboard();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _CheckerboardPainter());
}

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tile = 18.0;
    final light = Paint()..color = const Color(0xFFF6F4FA);
    final dark = Paint()..color = const Color(0xFFE8E4F0);
    for (var y = 0; y < size.height / tile; y++) {
      for (var x = 0; x < size.width / tile; x++) {
        canvas.drawRect(Rect.fromLTWH(x * tile, y * tile, tile, tile), (x + y).isEven ? light : dark);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerboardPainter oldDelegate) => false;
}
