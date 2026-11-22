/// Locale-independent financial number, percentage, and date formatting.
abstract final class MarketNumberFormatter {
  /// Formats price with adaptive decimal precision based on asset magnitude.
  static String formatPrice(double value) {
    if (value.isNaN || value.isInfinite) return '—';
    final abs = value.abs();
    final int decimals;
    if (abs == 0) {
      decimals = 2;
    } else if (abs < 0.01) {
      decimals = 6;
    } else if (abs < 10) {
      decimals = 4;
    } else {
      decimals = 2;
    }
    return _formatWithGrouping(value, decimals);
  }

  /// Formats converted amount cleanly without scientific notation clutter.
  static String formatConvertedAmount(double value) {
    if (value.isNaN || value.isInfinite) return '—';
    final abs = value.abs();
    final int decimals;
    if (abs == 0) {
      decimals = 2;
    } else if (abs < 0.0001) {
      decimals = 8;
    } else if (abs < 1) {
      decimals = 6;
    } else if (abs < 100) {
      decimals = 4;
    } else {
      decimals = 2;
    }
    return _formatWithGrouping(value, decimals);
  }

  static String formatSignedDelta(double delta) {
    if (delta.isNaN || delta.isInfinite) return '0.00';
    final prefix = delta > 0 ? '+' : '';
    return '$prefix${formatPrice(delta)}';
  }

  static String formatPercent(double percent, {bool includeSign = true}) {
    if (percent.isNaN || percent.isInfinite) return '0.00%';
    final prefix = includeSign && percent > 0 ? '+' : '';
    return '$prefix${percent.toStringAsFixed(2)}%';
  }

  static String formatDateShort(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m';
  }

  static String formatTimestamp(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d.$m.$y $hh:$mm';
  }

  static String _formatWithGrouping(double value, int decimals) {
    final isNeg = value < 0;
    final fixed = value.abs().toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      final posFromEnd = intPart.length - i;
      buffer.write(intPart[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buffer.write(' ');
      }
    }
    final frac = parts.length > 1 ? '.${parts[1]}' : '';
    return '${isNeg ? '-' : ''}$buffer$frac';
  }
}
