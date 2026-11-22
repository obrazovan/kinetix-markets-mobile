import 'package:http/http.dart' as http;

import '../../core/errors/failures.dart';
import '../../domain/entities/candle_point.dart';
import '../../domain/entities/market_asset.dart';
import '../parsers/bnm_xml_parser.dart';
import 'market_data_provider.dart';

class _BnmPairSpec {
  const _BnmPairSpec(this.charCode, this.symbol, this.name);
  final String charCode;
  final String symbol;
  final String name;
}

/// Fetches official Moldovan Leu (MDL) rates & 30D history from BNM XML gateway.
class BnmXmlProvider implements MarketDataProvider {
  BnmXmlProvider({
    required http.Client client,
    BnmXmlParser? parser,
    this.timeout = const Duration(seconds: 8),
  })  : _client = client,
        _parser = parser ?? const BnmXmlParser();

  static const _specs = <_BnmPairSpec>[
    _BnmPairSpec('USD', 'USD/MDL', 'US Dollar / Moldovan Leu'),
    _BnmPairSpec('EUR', 'EUR/MDL', 'Euro / Moldovan Leu'),
    _BnmPairSpec('RON', 'RON/MDL', 'Romanian Leu / Moldovan Leu'),
    _BnmPairSpec('RUB', 'RUB/MDL', 'Russian Ruble / Moldovan Leu'),
  ];

  final http.Client _client;
  final BnmXmlParser _parser;
  final Duration timeout;

  @override
  String get providerName => 'BNM XML';

  @override
  AssetCategory get category => AssetCategory.forex;

  @override
  Future<List<MarketAsset>> fetchAssetsWithHistory({int days = 30}) async {
    final today = DateTime.now();
    final latestDay = await _fetchWithRollback(today);
    if (latestDay == null || latestDay.isEmpty) {
      throw const NetworkFailure('НБМ XML не вернул актуальных курсов');
    }

    final usdRateLatest = latestDay.ratesByCode['USD']?.ratePerUnitMdl;
    if (usdRateLatest == null || usdRateLatest <= 0) {
      throw const ParseFailure('В ответе НБМ отсутствует курс USD/MDL');
    }

    // Collect business days over the past [days] calendar days in parallel batches.
    final businessDates = <DateTime>[];
    for (var offset = days; offset >= 0; offset--) {
      final candidate = today.subtract(Duration(days: offset));
      if (candidate.weekday == DateTime.saturday ||
          candidate.weekday == DateTime.sunday) {
        continue;
      }
      businessDates.add(candidate);
    }

    final historyByDate = <DateTime, BnmDayRates>{};
    const batchSize = 6;
    for (var i = 0; i < businessDates.length; i += batchSize) {
      final slice = businessDates.skip(i).take(batchSize);
      final batchResults = await Future.wait(
        slice.map((d) async {
          final parsed = await _fetchSingleDay(d);
          return (date: d, dayRates: parsed);
        }),
      );
      for (final item in batchResults) {
        if (item.dayRates != null && !item.dayRates!.isEmpty) {
          historyByDate[DateTime.utc(
            item.date.year,
            item.date.month,
            item.date.day,
          )] = item.dayRates!;
        }
      }
    }

    final sortedHistoryDates = historyByDate.keys.toList()..sort();
    final assets = <MarketAsset>[];

    for (final spec in _specs) {
      final latestEntry = latestDay.ratesByCode[spec.charCode];
      if (latestEntry == null) continue;

      final candles = <CandlePoint>[];
      for (final dt in sortedHistoryDates) {
        final entry = historyByDate[dt]?.ratesByCode[spec.charCode];
        if (entry == null) continue;
        final val = entry.ratePerUnitMdl;
        candles.add(
          CandlePoint(
            timestamp: dt,
            open: val,
            high: val,
            low: val,
            close: val,
          ),
        );
      }

      final current = latestEntry.ratePerUnitMdl;
      if (candles.isEmpty) {
        candles.add(
          CandlePoint(
            timestamp: DateTime.utc(today.year, today.month, today.day),
            open: current,
            high: current,
            low: current,
            close: current,
          ),
        );
      }

      final prev =
          candles.length >= 2 ? candles[candles.length - 2].close : current;
      final changePct = prev > 0 ? ((current - prev) / prev) * 100.0 : 0.0;
      final usdEq = current / usdRateLatest;

      assets.add(
        MarketAsset(
          symbol: spec.symbol,
          displayPair: spec.symbol,
          name: spec.name,
          category: AssetCategory.forex,
          quoteCurrency: 'MDL',
          currentPrice: current,
          usdEquivalentPrice: usdEq,
          change24hPercent: changePct,
          source: providerName,
          updatedAt: DateTime.now(),
          candles: candles,
        ),
      );
    }

    return assets;
  }

  Future<BnmDayRates?> _fetchWithRollback(DateTime startDate) async {
    for (var rollback = 0; rollback <= 7; rollback++) {
      final candidate = startDate.subtract(Duration(days: rollback));
      final parsed = await _fetchSingleDay(candidate);
      if (parsed != null && !parsed.isEmpty) {
        return parsed;
      }
    }
    return null;
  }

  Future<BnmDayRates?> _fetchSingleDay(DateTime date) async {
    final dateParam = '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
    final uri = Uri.https('www.bnm.md', '/en/official_exchange_rates', {
      'get_xml': '1',
      'date': dateParam,
    });

    try {
      final resp = await _client.get(uri).timeout(timeout);
      if (resp.statusCode != 200) return null;
      return _parser.parseXml(resp.body);
    } catch (_) {
      return null;
    }
  }
}
