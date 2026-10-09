import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

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

  Offset _defaultPivot(String id) {
    switch (id) {
      case 'head':
        return const Offset(.5, .82);
      case 'left_arm':
        return const Offset(.24, .28);
      case 'right_arm':
        return const Offset(.76, .28);
      case 'left_leg':
        return const Offset(.42, .18);
      case 'right_leg':
        return const Offset(.58, .18);
      default:
        return const Offset(.5, .5);
    }
  }

  double _angleFor(String id, double phase) {
    final wave = math.sin(phase * 2 * math.pi);
    switch (_motion) {
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
                                for (final id in widget.partIds)
                                  Positioned.fromRect(
                                    rect: rect,
                                    child: Transform.rotate(
                                      angle: _angleFor(id, phase),
                                      alignment: Alignment(
                                        (_pivots[id] ?? _defaultPivot(id)).dx * 2 - 1,
                                        (_pivots[id] ?? _defaultPivot(id)).dy * 2 - 1,
                                      ),
                                      child: Image.file(
                                        File('${widget.folder.path}/$id.png'),
                                        fit: BoxFit.fill,
                                        gaplessPlayback: true,
                                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                      ),
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
