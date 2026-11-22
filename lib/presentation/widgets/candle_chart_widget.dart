import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../app/theme/terminal_theme.dart';
import '../../core/formatters/number_formatter.dart';
import '../../domain/entities/candle_point.dart';

enum ChartDisplayMode { candles, area }

/// Interactive TradingView-style OHLC Candlestick & Area Chart with crosshair.
class CandleChartWidget extends StatefulWidget {
  const CandleChartWidget({
    super.key,
    required this.candles,
    this.mode = ChartDisplayMode.candles,
    this.height = 240,
    this.averageLineValue,
  });

  final List<CandlePoint> candles;
  final ChartDisplayMode mode;
  final double height;
  final double? averageLineValue;

  @override
  State<CandleChartWidget> createState() => _CandleChartWidgetState();
}

class _CandleChartWidgetState extends State<CandleChartWidget> {
  int? _selectedIndex;

  void _updateTouch(Offset localPos, double chartWidth) {
    if (widget.candles.isEmpty || chartWidth <= 0) return;
    final ratio = (localPos.dx / chartWidth).clamp(0.0, 1.0);
    final idx = (ratio * (widget.candles.length - 1)).round();
    if (idx != _selectedIndex) {
      setState(() => _selectedIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = TerminalTheme.of(context);
    if (widget.candles.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.border),
        ),
        alignment: Alignment.center,
        child: Text(
          'Недостаточно исторических данных для графика',
          style: TextStyle(color: palette.textSecondary, fontSize: 13),
        ),
      );
    }

    final activeCandle = _selectedIndex != null &&
            _selectedIndex! >= 0 &&
            _selectedIndex! < widget.candles.length
        ? widget.candles[_selectedIndex!]
        : widget.candles.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OhlcCrosshairBar(
          candle: activeCandle,
          isInspecting: _selectedIndex != null,
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            const axisWidth = 68.0;
            final plotWidth =
                math.max(100.0, constraints.maxWidth - axisWidth);

            return GestureDetector(
              onTapDown: (d) => _updateTouch(d.localPosition, plotWidth),
              onHorizontalDragStart: (d) =>
                  _updateTouch(d.localPosition, plotWidth),
              onHorizontalDragUpdate: (d) =>
                  _updateTouch(d.localPosition, plotWidth),
              onTapUp: (_) => setState(() => _selectedIndex = null),
              onHorizontalDragEnd: (_) => setState(() => _selectedIndex = null),
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.border),
                ),
                padding: const EdgeInsets.fromLTRB(10, 12, 8, 10),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, widget.height - 22),
                  painter: _CandleChartPainter(
                    candles: widget.candles,
                    mode: widget.mode,
                    palette: palette,
                    selectedIndex: _selectedIndex,
                    averageLineValue: widget.averageLineValue,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _OhlcCrosshairBar extends StatelessWidget {
  const _OhlcCrosshairBar({
    required this.candle,
    required this.isInspecting,
  });

  final CandlePoint candle;
  final bool isInspecting;

  @override
  Widget build(BuildContext context) {
    final palette = TerminalTheme.of(context);
    final bullColor = candle.isBullish ? palette.bull : palette.bear;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Text(
            MarketNumberFormatter.formatDateShort(candle.timestamp),
            style: TerminalTheme.tabular(
              context,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isInspecting ? palette.accent : palette.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 2,
              children: [
                _ohlcTag(context, 'O', candle.open, palette.textSecondary),
                _ohlcTag(context, 'H', candle.high, palette.bull),
                _ohlcTag(context, 'L', candle.low, palette.bear),
                _ohlcTag(context, 'C', candle.close, bullColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ohlcTag(
    BuildContext context,
    String label,
    double value,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: TerminalTheme.of(context).textSecondary,
          ),
        ),
        Text(
          MarketNumberFormatter.formatPrice(value),
          style: TerminalTheme.tabular(
            context,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CandleChartPainter extends CustomPainter {
  _CandleChartPainter({
    required this.candles,
    required this.mode,
    required this.palette,
    required this.selectedIndex,
    this.averageLineValue,
  });

  final List<CandlePoint> candles;
  final ChartDisplayMode mode;
  final TerminalPalette palette;
  final int? selectedIndex;
  final double? averageLineValue;

  @override
  void paint(Canvas canvas, Size size) {
    const rightAxisWidth = 64.0;
    const bottomAxisHeight = 20.0;
    final plotW = math.max(40.0, size.width - rightAxisWidth);
    final plotH = math.max(40.0, size.height - bottomAxisHeight);

    var minY = candles.first.low;
    var maxY = candles.first.high;
    for (final c in candles) {
      if (c.low < minY) minY = c.low;
      if (c.high > maxY) maxY = c.high;
    }
    if (averageLineValue != null) {
      if (averageLineValue! < minY) minY = averageLineValue!;
      if (averageLineValue! > maxY) maxY = averageLineValue!;
    }

    var span = maxY - minY;
    if (span.abs() < 1e-9) {
      final pad = minY == 0 ? 1.0 : minY.abs() * 0.02;
      minY -= pad;
      maxY += pad;
      span = maxY - minY;
    } else {
      minY -= span * 0.08;
      maxY += span * 0.08;
      span = maxY - minY;
    }

    double toY(double price) {
      final norm = (price - minY) / span;
      return plotH - (norm * plotH);
    }

    // Grid lines & right price labels (4 levels).
    final gridPaint = Paint()
      ..color = palette.gridLine
      ..strokeWidth = 1;

    for (var i = 0; i <= 3; i++) {
      final frac = i / 3.0;
      final y = plotH * frac;
      canvas.drawLine(Offset(0, y), Offset(plotW, y), gridPaint);

      final priceAtLine = maxY - frac * span;
      _drawLabel(
        canvas,
        MarketNumberFormatter.formatPrice(priceAtLine),
        Offset(plotW + 6, y - 7),
        palette.textSecondary,
        fontSize: 10,
      );
    }

    // Optional dashed average reference line.
    if (averageLineValue != null) {
      final avgY = toY(averageLineValue!);
      final avgPaint = Paint()
        ..color = palette.accent.withValues(alpha: 0.75)
        ..strokeWidth = 1.2;
      const dashW = 5.0;
      const gap = 4.0;
      var x = 0.0;
      while (x < plotW) {
        canvas.drawLine(
          Offset(x, avgY),
          Offset(math.min(x + dashW, plotW), avgY),
          avgPaint,
        );
        x += dashW + gap;
      }
    }

    final count = candles.length;
    final stepX = count == 1 ? plotW : plotW / count;

    if (mode == ChartDisplayMode.area) {
      final isOverallUp = candles.last.close >= candles.first.close;
      final lineColor = isOverallUp ? palette.bull : palette.bear;
      final linePath = Path();
      final fillPath = Path();

      for (var i = 0; i < count; i++) {
        final x = count == 1 ? plotW / 2 : (i / (count - 1)) * plotW;
        final y = toY(candles[i].close);
        if (i == 0) {
          linePath.moveTo(x, y);
          fillPath.moveTo(x, plotH);
          fillPath.lineTo(x, y);
        } else {
          linePath.lineTo(x, y);
          fillPath.lineTo(x, y);
        }
      }

      fillPath.lineTo(plotW, plotH);
      fillPath.close();

      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lineColor.withValues(alpha: 0.30),
              lineColor.withValues(alpha: 0.02),
            ],
          ).createShader(Rect.fromLTWH(0, 0, plotW, plotH)),
      );

      canvas.drawPath(
        linePath,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    } else {
      final bodyW = (stepX * 0.56).clamp(3.0, 14.0);
      for (var i = 0; i < count; i++) {
        final c = candles[i];
        final cx = count == 1 ? plotW / 2 : (i + 0.5) * stepX;
        final color = c.isBullish ? palette.bull : palette.bear;

        final yHigh = toY(c.high);
        final yLow = toY(c.low);
        final yOpen = toY(c.open);
        final yClose = toY(c.close);

        canvas.drawLine(
          Offset(cx, yHigh),
          Offset(cx, yLow),
          Paint()
            ..color = color
            ..strokeWidth = 1.4,
        );

        final top = math.min(yOpen, yClose);
        final bottom = math.max(yOpen, yClose);
        final rectH = math.max(2.0, bottom - top);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - bodyW / 2, top, bodyW, rectH),
            const Radius.circular(1.5),
          ),
          Paint()..color = color,
        );
      }
    }

    // Bottom date ticks (start, middle, end).
    final dateIndices = <int>{0, count ~/ 2, count - 1};
    for (final idx in dateIndices) {
      final cx = count == 1
          ? plotW / 2
          : mode == ChartDisplayMode.area
              ? (idx / (count - 1)) * plotW
              : (idx + 0.5) * stepX;
      final label = MarketNumberFormatter.formatDateShort(candles[idx].timestamp);
      final clampedX = cx.clamp(0.0, math.max(0.0, plotW - 32)).toDouble();
      _drawLabel(
        canvas,
        label,
        Offset(clampedX, plotH + 5),
        palette.textSecondary,
        fontSize: 10,
      );
    }

    // Crosshair inspection overlay.
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < count) {
      final idx = selectedIndex!;
      final cx = count == 1
          ? plotW / 2
          : mode == ChartDisplayMode.area
              ? (idx / (count - 1)) * plotW
              : (idx + 0.5) * stepX;
      final cy = toY(candles[idx].close);

      final crossPaint = Paint()
        ..color = palette.accent.withValues(alpha: 0.7)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(cx, 0), Offset(cx, plotH), crossPaint);
      canvas.drawLine(Offset(0, cy), Offset(plotW, cy), crossPaint);
      canvas.drawCircle(
        Offset(cx, cy),
        4.5,
        Paint()..color = palette.accent,
      );
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset offset,
    Color color, {
    double fontSize = 10,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _CandleChartPainter oldDelegate) {
    return oldDelegate.candles != candles ||
        oldDelegate.mode != mode ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.averageLineValue != averageLineValue ||
        oldDelegate.palette != palette;
  }
}
