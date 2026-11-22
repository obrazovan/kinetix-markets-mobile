import 'package:http/http.dart' as http;

import '../../core/errors/failures.dart';
import '../../domain/entities/market_asset.dart';
import '../parsers/frankfurter_parser.dart';
import 'market_data_provider.dart';

class _ForexSpec {
  const _ForexSpec({
    required this.code,
    required this.symbol,
    required this.displayPair,
    required this.name,
    required this.quoteCurrency,
    required this.invertedFromUsd,
  });

  final String code;
  final String symbol;
  final String displayPair;
  final String name;
  final String quoteCurrency;
  final bool invertedFromUsd;
}

/// Fetches major Forex historical series from Frankfurter (ECB reference rates).
class FrankfurterForexProvider implements MarketDataProvider {
  FrankfurterForexProvider({
    required http.Client client,
    FrankfurterParser? parser,
    this.timeout = const Duration(seconds: 8),
  })  : _client = client,
        _parser = parser ?? const FrankfurterParser();

  static const _specs = <_ForexSpec>[
    _ForexSpec(
      code: 'EUR',
      symbol: 'EUR/USD',
      displayPair: 'EUR/USD',
      name: 'Euro / US Dollar',
      quoteCurrency: 'USD',
      invertedFromUsd: true,
    ),
    _ForexSpec(
      code: 'GBP',
      symbol: 'GBP/USD',
      displayPair: 'GBP/USD',
      name: 'British Pound / US Dollar',
      quoteCurrency: 'USD',
      invertedFromUsd: true,
    ),
    _ForexSpec(
      code: 'JPY',
      symbol: 'USD/JPY',
      displayPair: 'USD/JPY',
      name: 'US Dollar / Japanese Yen',
      quoteCurrency: 'JPY',
      invertedFromUsd: false,
    ),
    _ForexSpec(
      code: 'CHF',
      symbol: 'USD/CHF',
      displayPair: 'USD/CHF',
      name: 'US Dollar / Swiss Franc',
      quoteCurrency: 'CHF',
      invertedFromUsd: false,
    ),
    _ForexSpec(
      code: 'RON',
      symbol: 'USD/RON',
      displayPair: 'USD/RON',
      name: 'US Dollar / Romanian Leu',
      quoteCurrency: 'RON',
      invertedFromUsd: false,
    ),
  ];

  final http.Client _client;
  final FrankfurterParser _parser;
  final Duration timeout;

  @override
  String get providerName => 'Frankfurter ECB';

  @override
  AssetCategory get category => AssetCategory.forex;

  @override
  Future<List<MarketAsset>> fetchAssetsWithHistory({int days = 30}) async {
    final now = DateTime.now().toUtc();
    final start = now.subtract(Duration(days: days + 7));
    final startStr = _fmtDate(start);
    final endStr = _fmtDate(now);

    final uri = Uri.https(
      'api.frankfurter.app',
      '/$startStr..$endStr',
      {'from': 'USD', 'to': 'EUR,GBP,JPY,CHF,RON'},
    );

    final resp = await _client.get(uri).timeout(timeout);
    if (resp.statusCode != 200) {
      throw NetworkFailure('Frankfurter HTTP ${resp.statusCode}');
    }

    final invertedCodes =
        _specs.where((s) => s.invertedFromUsd).map((s) => s.code).toSet();
    final seriesMap = _parser.parseTimeSeries(
      resp.body,
      invertPairs: invertedCodes,
    );

    final assets = <MarketAsset>[];
    for (final spec in _specs) {
      final candles = seriesMap[spec.code];
      if (candles == null || candles.isEmpty) continue;

      final current = candles.last.close;
      final prev =
          candles.length >= 2 ? candles[candles.length - 2].close : current;
      final changePct = prev > 0 ? ((current - prev) / prev) * 100.0 : 0.0;
      final usdEq = spec.invertedFromUsd ? current : (1.0 / current);

      assets.add(
        MarketAsset(
          symbol: spec.symbol,
          displayPair: spec.displayPair,
          name: spec.name,
          category: AssetCategory.forex,
          quoteCurrency: spec.quoteCurrency,
          currentPrice: current,
          usdEquivalentPrice: usdEq,
          change24hPercent: changePct,
          source: providerName,
          updatedAt: DateTime.now(),
          candles: candles,
        ),
      );
    }

    if (assets.isEmpty) {
      throw const ParseFailure('Frankfurter не вернул валютных котировок');
    }
    return assets;
  }

  static String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
