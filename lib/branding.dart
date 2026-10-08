import 'package:flutter/material.dart';

/// Shared Rasmati visual identity. Keep product colors and mark consistent.
abstract final class RasmatiColors {
  static const purple = Color(0xFF7558E8);
  static const purpleDark = Color(0xFF4C35B8);
  static const ink = Color(0xFF253047);
  static const paper = Color(0xFFFFFBF4);
  static const coral = Color(0xFFFF7B6B);
  static const mint = Color(0xFF36B8A5);
  static const yellow = Color(0xFFFFC857);
  static const muted = Color(0xFF778095);
  static const lavender = Color(0xFFF0EBFF);
  static const paleMint = Color(0xFFE2F8F3);
  static const paleCoral = Color(0xFFFFF0ED);
  static const paleYellow = Color(0xFFFFF5D9);
}

/// Flutter-native version of assets/branding/rasmati_mark.svg.
class RasmatiMark extends StatelessWidget {
  const RasmatiMark({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _RasmatiMarkPainter()),
      );
}

class _RasmatiMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 256;
    canvas.save();
    canvas.scale(scale);
    final bg = Paint()..color = RasmatiColors.purple;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(12, 12, 232, 232), const Radius.circular(58)),
      bg,
    );
    final paper = Paint()..color = RasmatiColors.paper;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(58, 52, 114, 153), const Radius.circular(12)),
      paper,
    );
    void line(List<Offset> points, Color color, {double width = 8}) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    line(
      const [Offset(79, 91), Offset(87, 82), Offset(96, 91), Offset(104, 99), Offset(112, 91), Offset(120, 82), Offset(128, 91), Offset(143, 91)],
      RasmatiColors.coral,
    );
    line(
      const [Offset(78, 123), Offset(88, 111), Offset(100, 135), Offset(112, 123), Offset(125, 111), Offset(138, 123), Offset(158, 123)],
      RasmatiColors.mint,
    );
    line(
      const [Offset(79, 155), Offset(91, 143), Offset(103, 155), Offset(115, 167), Offset(127, 155), Offset(147, 155)],
      RasmatiColors.purple,
    );
    final star = Path()
      ..moveTo(174, 137)
      ..lineTo(182, 153)
      ..lineTo(200, 156)
      ..lineTo(187, 168)
      ..lineTo(190, 186)
      ..lineTo(174, 178)
      ..lineTo(158, 186)
      ..lineTo(161, 168)
      ..lineTo(148, 156)
      ..lineTo(166, 153)
      ..close();
    canvas.drawPath(star, Paint()..color = RasmatiColors.yellow);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RasmatiMarkPainter oldDelegate) => false;
}
