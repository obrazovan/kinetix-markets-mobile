import 'package:material_ui/material_ui.dart';

import '../../domain/entities/candle_point.dart';

/// Compact watchlist sparkline with gradient fill beneath the price curve.
class SparklineChart extends StatelessWidget {
  const SparklineChart({
    super.key,
    required this.candles,
    required this.color,
    this.width = 68,
    this.height = 28,
  });

  final List<CandlePoint> candles;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(candles: candles, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.candles, required this.color});

  final List<CandlePoint> candles;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final values = candles.map((c) => c.close).toList(growable: false);
    if (values.length == 1) {
      final y = size.height / 2;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = color
          ..strokeWidth = 1.6,
      );
      return;
    }

    var minVal = values.first;
    var maxVal = values.first;
    for (final v in values) {
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
    }

    final span = (maxVal - minVal).abs();
    final effectiveSpan = span < 1e-9 ? 1.0 : span;
    final padY = size.height * 0.12;
    final drawH = size.height - padY * 2;

    final linePath = Path();
    final fillPath = Path();

    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final normalized =
          span < 1e-9 ? 0.5 : (values[i] - minVal) / effectiveSpan;
      final y = padY + (1.0 - normalized) * drawH;
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.28),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.candles != candles || oldDelegate.color != color;
  }
}
