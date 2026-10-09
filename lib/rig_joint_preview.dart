import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class RigJointPreview extends StatefulWidget {
  const RigJointPreview({super.key, required this.folder, required this.partIds, required this.imageWidth, required this.imageHeight});
  final Directory folder;
  final List<String> partIds;
  final int imageWidth;
  final int imageHeight;
  @override
  State<RigJointPreview> createState() => _RigJointPreviewState();
}

class _RigJointPreviewState extends State<RigJointPreview> {
  late String selected;
  final Map<String, Offset> pivots = {};
  double angle = 0;
  bool saving = false;
  static const labels = {
    'head': 'الرأس', 'torso': 'الجذع', 'left_arm': 'الذراع الأيسر',
    'right_arm': 'الذراع الأيمن', 'left_leg': 'الساق اليسرى', 'right_leg': 'الساق اليمنى',
  };

  @override
  void initState() {
    super.initState();
    selected = widget.partIds.first;
    for (final id in widget.partIds) { pivots[id] = _defaultPivot(id); }
    _loadPivots();
  }

  Offset _defaultPivot(String id) {
    switch (id) {
      case 'head': return const Offset(.5, .82);
      case 'left_arm': return const Offset(.24, .28);
      case 'right_arm': return const Offset(.76, .28);
      case 'left_leg': return const Offset(.42, .18);
      case 'right_leg': return const Offset(.58, .18);
      default: return const Offset(.5, .5);
    }
  }

  Future<void> _loadPivots() async {
    try {
      final file = File('${widget.folder.path}/joints.json');
      if (!await file.exists()) return;
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final raw = data['pivots'] as Map<String, dynamic>? ?? {};
      if (!mounted) return;
      setState(() {
        for (final e in raw.entries) {
          final v = e.value;
          if (v is List && v.length == 2 && pivots.containsKey(e.key)) {
            pivots[e.key] = Offset((v[0] as num).toDouble().clamp(0.0, 1.0), (v[1] as num).toDouble().clamp(0.0, 1.0));
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await File('${widget.folder.path}/joints.json').writeAsString(jsonEncode({
        'version': 1,
        'coordinateSpace': 'full_canvas_normalized',
        'pivots': pivots.map((k, v) => MapEntry(k, [v.dx, v.dy])),
      }));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ نقاط الارتكاز')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر حفظ نقاط الارتكاز')));
    } finally { if (mounted) setState(() => saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final pivot = pivots[selected] ?? const Offset(.5, .5);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('المرحلة 2: المفاصل')),
        body: SafeArea(child: Column(children: [
          const Padding(padding: EdgeInsets.all(12), child: Text('اختر جزءًا واضبط نقطة ارتكازه ثم حرّكه بزاوية صغيرة. اسحب النقطة الحمراء إلى موضع المفصل الصحيح.', textAlign: TextAlign.center)),
          Wrap(alignment: WrapAlignment.center, spacing: 5, children: widget.partIds.map((id) => ChoiceChip(
            label: Text(labels[id] ?? id), selected: selected == id,
            onSelected: (_) => setState(() { selected = id; angle = 0; }),
          )).toList()),
          Expanded(child: Padding(padding: const EdgeInsets.all(12), child: LayoutBuilder(builder: (context, constraints) {
            final scale = math.min(constraints.maxWidth / widget.imageWidth, constraints.maxHeight / widget.imageHeight);
            final w = widget.imageWidth * scale, h = widget.imageHeight * scale;
            final rect = Rect.fromLTWH((constraints.maxWidth-w)/2, (constraints.maxHeight-h)/2, w, h);
            return Stack(fit: StackFit.expand, children: [
              const ColoredBox(color: Color(0xFFF1F2F6)),
              Positioned.fromRect(rect: rect, child: Image.file(File('${widget.folder.path}/base.png'), fit: BoxFit.fill)),
              for (final id in widget.partIds)
                Positioned.fromRect(rect: rect, child: Transform.rotate(
                  angle: id == selected ? angle * math.pi / 180 : 0,
                  alignment: Alignment((pivots[id] ?? _defaultPivot(id)).dx*2-1, (pivots[id] ?? _defaultPivot(id)).dy*2-1),
                  child: Image.file(File('${widget.folder.path}/$id.png'), fit: BoxFit.fill, gaplessPlayback: true),
                )),
              Positioned(left: rect.left+pivot.dx*rect.width-14, top: rect.top+pivot.dy*rect.height-14,
                child: GestureDetector(onPanUpdate: (d) => setState(() => pivots[selected] = Offset(
                  (pivot.dx+d.delta.dx/rect.width).clamp(0.0,1.0), (pivot.dy+d.delta.dy/rect.height).clamp(0.0,1.0))),
                  child: Container(width: 28,height: 28,decoration: BoxDecoration(color: const Color(0xFFFC4F6D),shape: BoxShape.circle,border: Border.all(color: Colors.white,width: 3),boxShadow: const [BoxShadow(color: Color(0x55000000),blurRadius: 6)]))),
              ),
            ]);
          }))),
          Padding(padding: const EdgeInsets.fromLTRB(16,0,16,12), child: Column(children: [
            Row(children: [const Text('زاوية الدوران'), Expanded(child: Slider(min: -80,max: 80,divisions: 80,value: angle,label: '${angle.round()}°',onChanged: (v)=>setState(()=>angle=v))), IconButton(onPressed: ()=>setState(()=>angle=0),icon: const Icon(Icons.restart_alt))]),
            Row(children: [const Text('أفقي'),Expanded(child: Slider(value:pivot.dx,label:'${(pivot.dx*100).round()}%',onChanged:(v)=>setState(()=>pivots[selected]=Offset(v,pivot.dy)))),const Text('عمودي'),Expanded(child:Slider(value:pivot.dy,label:'${(pivot.dy*100).round()}%',onChanged:(v)=>setState(()=>pivots[selected]=Offset(pivot.dx,v))))]),
            SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:saving?null:_save,icon:const Icon(Icons.save),label:Text(saving?'جارٍ الحفظ…':'حفظ نقاط المفاصل'))),
          ])),
        ])),
      ),
    );
  }
}
