import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'motion_choreography.dart';
import 'rig_geometry.dart';

/// Local, non-destructive preview of the saved character layers.
/// Motion is applied to each selected layer around its saved normalized pivot.
class CharacterMotionPreview extends StatefulWidget {
  const CharacterMotionPreview({
    super.key,
    required this.folder,
    required this.partIds,
    required this.imageWidth,
    required this.imageHeight,
  });

  final Directory folder;
  final List<String> partIds;
  final int imageWidth;
  final int imageHeight;

  @override
  State<CharacterMotionPreview> createState() => _CharacterMotionPreviewState();
}

class _CharacterMotionPreviewState extends State<CharacterMotionPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  final Map<String, Offset> _pivots = {};
  String _motion = 'wave';
  bool _playing = true;
  bool _loading = true;
  String? _loadError;


  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..addListener(() {
        if (mounted) setState(() {});
      });
    _loadPivots();
  }

  Future<void> _loadPivots() async {
    // Validate the saved rig before rendering. Missing layers must not silently
    // look like a successful animation with body parts disappearing.
    try {
      final requiredFiles = <String>[
        'base.png',
        ...widget.partIds.map((id) => '$id.png'),
      ];
      for (final name in requiredFiles) {
        final file = File('${widget.folder.path}/$name');
        if (!await file.exists() || await file.length() == 0) {
          if (mounted) {
            setState(() {
              _loadError = 'ملف الشخصية مفقود أو فارغ: $name';
              _loading = false;
            });
          }
          return;
        }

        // Non-empty files may still be corrupt or use a mismatched canvas.
        ui.Codec? codec;
        try {
          codec = await ui.instantiateImageCodec(await file.readAsBytes());
          final frame = await codec.getNextFrame();
          final width = frame.image.width;
          final height = frame.image.height;
          frame.image.dispose();
          if (width != widget.imageWidth || height != widget.imageHeight) {
            if (mounted) {
              setState(() {
                _loadError = 'أبعاد الملف $name لا تطابق أبعاد الرسمة الأصلية (${widget.imageWidth}×${widget.imageHeight}).';
                _loading = false;
              });
            }
            return;
          }
        } catch (_) {
          if (mounted) {
            setState(() {
              _loadError = 'تعذّر قراءة صورة الشخصية: $name';
              _loading = false;
            });
          }
          return;
        } finally {
          codec?.dispose();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadError = 'تعذّر التحقق من ملفات الشخصية المحفوظة.';
          _loading = false;
        });
      }
      return;
    }

    for (final id in widget.partIds) {
      _pivots[id] = _defaultPivot(id);
    }
    try {
      final file = File('${widget.folder.path}/joints.json');
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final raw = json['pivots'] as Map<String, dynamic>? ?? {};
        for (final entry in raw.entries) {
          final value = entry.value;
          if (_pivots.containsKey(entry.key) && value is List && value.length == 2) {
            _pivots[entry.key] = Offset(
              (value[0] as num).toDouble().clamp(0.0, 1.0),
              (value[1] as num).toDouble().clamp(0.0, 1.0),
            );
          }
        }
      }
    } catch (_) {
      // Default pivots keep old/partially saved rigs previewable.
    }
    if (mounted) {
      setState(() => _loading = false);
      _clock.repeat();
    }
  }

  Offset _defaultPivot(String id) => RigGeometry.defaultPivot(id);



  Widget _applyPartTransform(
    String id,
    double phase,
    Size size,
    Widget child,
  ) {
    final pivot = _pivots[id] ?? _defaultPivot(id);
    return Transform.translate(
      offset: MotionChoreography.offsetFor(_motion, id, phase, size),
      child: Transform.rotate(
        angle: MotionChoreography.angleFor(_motion, id, phase),
        alignment: Alignment(pivot.dx * 2 - 1, pivot.dy * 2 - 1),
        child: child,
      ),
    );
  }

  Widget _buildArticulatedLayer(String id, double phase, Size size) {
    Widget layer = Image.file(
      File('${widget.folder.path}/$id.png'),
      fit: BoxFit.fill,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );

    // Build from the selected segment outward through every ancestor. The
    // torso's sway/bounce now propagates to shoulders, hips, head, elbows and
    // knees rather than leaving the extremities behind in image space.
    layer = _applyPartTransform(id, phase, size, layer);
    for (final ancestor in RigGeometry.ancestorsOf(id)) {
      layer = _applyPartTransform(ancestor, phase, size, layer);
    }
    return layer;
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('معاينة حركة الشخصية')),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.broken_image_outlined, size: 48),
                            const SizedBox(height: 12),
                            Text(_loadError!, textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            const Text(
                              'ارجع إلى تجهيز أجزاء الشخصية وأعد حفظها قبل تجربة الحركة.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'جرّب حركة الأجزاء حول نقاط الارتكاز المحفوظة. إذا ظهر فراغ عند مفصل، ارجع إلى إعداد الأجزاء واضبط حدود التحديد ونقطة المفصل.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('تلويح'),
                          selected: _motion == 'wave',
                          onSelected: (_) => setState(() => _motion = 'wave'),
                        ),
                        ChoiceChip(
                          label: const Text('مشي'),
                          selected: _motion == 'walk',
                          onSelected: (_) => setState(() => _motion = 'walk'),
                        ),
                        ChoiceChip(
                          label: const Text('إيماء الرأس'),
                          selected: _motion == 'nod',
                          onSelected: (_) => setState(() => _motion = 'nod'),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final scale = math.min(
                              constraints.maxWidth / widget.imageWidth,
                              constraints.maxHeight / widget.imageHeight,
                            );
                            final w = widget.imageWidth * scale;
                            final h = widget.imageHeight * scale;
                            final rect = Rect.fromLTWH(
                              (constraints.maxWidth - w) / 2,
                              (constraints.maxHeight - h) / 2,
                              w,
                              h,
                            );
                            final phase = _clock.value;
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                const ColoredBox(color: Color(0xFFF1F2F6)),
                                Positioned.fromRect(
                                  rect: rect,
                                  child: Image.file(
                                    File('${widget.folder.path}/base.png'),
                                    fit: BoxFit.fill,
                                    gaplessPlayback: true,
                                  ),
                                ),
                                for (final id in MotionChoreography.orderParts(widget.partIds))
                                  Positioned.fromRect(
                                    rect: rect,
                                    child: _buildArticulatedLayer(
                                      id,
                                      phase,
                                      Size(w, h),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                setState(() => _playing = !_playing);
                                if (_playing) {
                                  _clock.repeat();
                                } else {
                                  _clock.stop();
                                }
                              },
                              icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                              label: Text(_playing ? 'إيقاف مؤقت' : 'تشغيل'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => setState(() {
                              _clock.value = 0;
                              if (_playing) _clock.repeat();
                            }),
                            icon: const Icon(Icons.restart_alt),
                            label: const Text('إعادة'),
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
