import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'background_removal.dart';

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
  double _colorTolerance = 38;
  Offset? _backgroundSeed;
  Color? _sampledColor;
  bool _pickBackgroundMode = false;
  bool _autoRemove = true;
  bool _busy = false;
  bool _previewBusy = false;
  File? _previewFile;
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
        final oriented = img.bakeOrientation(decoded);
        setState(() => _imageSize = Size(oriented.width.toDouble(), oriented.height.toDouble()));
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

  img.Image _removeBackground(img.Image source) {
    final seed = _backgroundSeed;
    if (seed != null) {
      return removeConnectedColorBackground(
        source,
        seedX: (seed.dx * source.width).round().clamp(0, source.width - 1).toInt(),
        seedY: (seed.dy * source.height).round().clamp(0, source.height - 1).toInt(),
        tolerance: _colorTolerance,
      );
    }
    return removeEdgeConnectedLightPaper(source, threshold: _threshold);
  }

  Future<void> _pickBackground(Offset normalized) async {
    try {
      final decoded = img.decodeImage(await widget.imageFile.readAsBytes());
      if (decoded == null || !mounted) return;
      final source = img.bakeOrientation(decoded);
      final x = (normalized.dx * source.width).round().clamp(0, source.width - 1).toInt();
      final y = (normalized.dy * source.height).round().clamp(0, source.height - 1).toInt();
      final pixel = source.getPixel(x, y);
      setState(() {
        _backgroundSeed = normalized;
        _sampledColor = Color.fromARGB(
          255, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(),
        );
        _pickBackgroundMode = false;
        _previewFile = null;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر اختيار اللون من هذه الصورة.')),
        );
      }
    }
  }

  img.Image _applyBrushStrokes(img.Image source, img.Image cleaned) {
    final width = source.width;
    final height = source.height;
    final alpha = Uint8List(width * height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        alpha[y * width + x] = cleaned.getPixel(x, y).a.toInt();
      }
    }

    for (final stroke in _strokes) {
      // Brush radius is measured in source-image pixels, using the
      // shorter image side so the mask matches the circular on-screen brush.
      final radius = math.max(1, (stroke.radius * math.min(width, height)).round()).toInt();
      final radiusX = radius;
      final radiusY = radius;
      void stamp(Offset point) {
        final cx = (point.dx * width).round().clamp(0, width - 1).toInt();
        final cy = (point.dy * height).round().clamp(0, height - 1).toInt();
        for (var y = math.max(0, cy - radiusY).toInt();
            y <= math.min(height - 1, cy + radiusY).toInt(); y++) {
          for (var x = math.max(0, cx - radiusX).toInt();
              x <= math.min(width - 1, cx + radiusX).toInt(); x++) {
            final dx = (x - cx) / radiusX;
            final dy = (y - cy) / radiusY;
            if (dx * dx + dy * dy > 1) continue;
            alpha[y * width + x] = stroke.mode == BrushMode.erase ? 0 : 255;
          }
        }
      }

      if (stroke.points.isEmpty) continue;
      stamp(stroke.points.first);
      // Pointer events can be far apart during a quick drag. Interpolate
      // between them so the exported mask is a continuous stroke, not dots.
      final spacingX = math.max(1, radiusX * 0.45).toDouble();
      final spacingY = math.max(1, radiusY * 0.45).toDouble();
      for (var i = 1; i < stroke.points.length; i++) {
        final from = stroke.points[i - 1];
        final to = stroke.points[i];
        final dxPixels = (to.dx - from.dx) * width;
        final dyPixels = (to.dy - from.dy) * height;
        final steps = math.max(
          1,
          math.max((dxPixels.abs() / spacingX).ceil(),
              (dyPixels.abs() / spacingY).ceil()),
        );
        for (var step = 1; step <= steps; step++) {
          final t = step / steps;
          stamp(Offset(
            from.dx + (to.dx - from.dx) * t,
            from.dy + (to.dy - from.dy) * t,
          ));
        }
      }
    }

    final output = img.Image(width: width, height: height, numChannels: 4);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = source.getPixel(x, y);
        output.setPixelRgba(
          x, y, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(),
          alpha[y * width + x],
        );
      }
    }
    return output;
  }

  Future<void> _previewAutomaticRemoval() async {
    if (_previewBusy) return;
    setState(() => _previewBusy = true);
    try {
      final decoded = img.decodeImage(await widget.imageFile.readAsBytes());
      if (decoded == null) throw const FormatException('Unsupported image');
      final source = img.bakeOrientation(decoded);
      final output = _applyBrushStrokes(
        source, _autoRemove ? _removeBackground(source) : source,
      );
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/rasmati_preview_${DateTime.now().microsecondsSinceEpoch}.png');
      await file.writeAsBytes(img.encodePng(output), flush: true);
      if (mounted) setState(() => _previewFile = file);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر إنشاء المعاينة. حاول تقليل حجم الصورة.')),
        );
      }
    } finally {
      if (mounted) setState(() => _previewBusy = false);
    }
  }

  Future<File?> _apply() async {
    if (_busy) return null;
    setState(() => _busy = true);
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw const FormatException('Unsupported image');
      final source = img.bakeOrientation(decoded);
      final cleaned = _autoRemove ? _removeBackground(source) : source;
      final output = _applyBrushStrokes(source, cleaned);
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
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                child: Text(
                  _pickBackgroundMode
                      ? 'اضغط على لون الخلفية داخل الصورة لاختياره، ثم عاين الإزالة.'
                      : 'أزل الورق الفاتح تلقائيًا، أو اختر لون الخلفية لإزالة مساحة متصلة منه. صحّح النتيجة بالفرشاة. كل المعالجة على الجهاز.',
                  style: const TextStyle(color: Color(0xFF778095), height: 1.5),
                ),
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
                          Image.file(_previewFile ?? widget.imageFile, key: ValueKey(_previewFile?.path ?? widget.imageFile.path), fit: BoxFit.contain),
                          if (_backgroundSeed != null)
                            Positioned(
                              left: _imageRect(_canvasSize ?? Size.zero).left + _backgroundSeed!.dx * _imageRect(_canvasSize ?? Size.zero).width - 12,
                              top: _imageRect(_canvasSize ?? Size.zero).top + _backgroundSeed!.dy * _imageRect(_canvasSize ?? Size.zero).height - 12,
                              child: IgnorePointer(child: Container(width: 24, height: 24, decoration: BoxDecoration(color: _sampledColor ?? Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]))),
                            ),
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTapDown: (details) {
                              if (!_pickBackgroundMode) return;
                              final point = _normalized(details.localPosition);
                              if (point != null) _pickBackground(point);
                            },
                            onPanStart: (details) {
                              if (_pickBackgroundMode) return;
                              final point = _normalized(details.localPosition);
                              if (point != null) _beginStroke(point);
                            },
                            onPanUpdate: (details) {
                              if (_pickBackgroundMode) return;
                              final point = _normalized(details.localPosition);
                              if (point != null) _extendStroke(point);
                            },
                            onPanEnd: (_) => _endStroke(),
                            child: CustomPaint(painter: _StrokePainter(_strokes, _imageRect(_canvasSize ?? Size.zero))),
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
                      title: const Text('الإزالة التلقائية', style: TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: const Text('تُستخدم إزالة الورق الفاتح افتراضيًا، أو لون الخلفية الذي تختاره أدناه.'),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() {
                          _pickBackgroundMode = !_pickBackgroundMode;
                          _previewFile = null;
                        }),
                        icon: Icon(_pickBackgroundMode ? Icons.touch_app_rounded : Icons.colorize_rounded),
                        label: Text(_pickBackgroundMode ? 'اضغط على الخلفية لاختيار اللون…' : 'اختيار لون الخلفية من الصورة'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _pickBackgroundMode ? Colors.white : _purple,
                          backgroundColor: _pickBackgroundMode ? _purple : Colors.transparent,
                        ),
                      ),
                    ),
                    if (_backgroundSeed == null)
                      Row(children: [
                        const Text('حساسية الورق', style: TextStyle(fontWeight: FontWeight.w800)),
                        Expanded(child: Slider(value: _threshold, min: 0, max: 55, divisions: 11, label: _threshold.round().toString(), onChanged: (value) => setState(() { _threshold = value; _previewFile = null; }))),
                      ])
                    else
                      Row(children: [
                        Container(width: 22, height: 22, decoration: BoxDecoration(color: _sampledColor, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD9D5E2)))),
                        const SizedBox(width: 8),
                        const Text('تسامح اللون', style: TextStyle(fontWeight: FontWeight.w800)),
                        Expanded(child: Slider(value: _colorTolerance, min: 4, max: 120, divisions: 29, label: _colorTolerance.round().toString(), onChanged: (value) => setState(() { _colorTolerance = value; _previewFile = null; }))),
                        IconButton(tooltip: 'إلغاء اللون المختار', onPressed: () => setState(() { _backgroundSeed = null; _sampledColor = null; _previewFile = null; }), icon: const Icon(Icons.close_rounded)),
                      ]),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _previewBusy ? null : _previewAutomaticRemoval,
                        icon: _previewBusy
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.visibility_rounded),
                        label: Text(_previewBusy ? 'جارٍ تجهيز المعاينة…' : 'معاينة إزالة الورقة'),
                      ),
                    ),
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
