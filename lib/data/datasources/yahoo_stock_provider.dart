import 'package:http/http.dart' as http;

import '../../core/errors/failures.dart';
import '../../domain/entities/market_asset.dart';
import '../parsers/yahoo_parser.dart';
import 'market_data_provider.dart';

class _StockSpec {
  const _StockSpec(this.symbol, this.name);
  final String symbol;
  final String name;
}

/// Fetches US equity quotes and 1-month daily OHLCV candles from Yahoo Finance.
class YahooStockProvider implements MarketDataProvider {
  YahooStockProvider({
    required http.Client client,
    YahooParser? parser,
    this.timeout = const Duration(seconds: 8),
  })  : _client = client,
        _parser = parser ?? const YahooParser();

  static const _specs = <_StockSpec>[
    _StockSpec('AAPL', 'Apple Inc.'),
    _StockSpec('NVDA', 'NVIDIA Corp.'),
    _StockSpec('TSLA', 'Tesla Inc.'),
    _StockSpec('MSFT', 'Microsoft Corp.'),
    _StockSpec('GOOGL', 'Alphabet Inc.'),
    _StockSpec('AMZN', 'Amazon.com Inc.'),
  ];

  static const _headers = <String, String>{
    'User-Agent': 'Mozilla/5.0 (Linux; Android 14) KinetixMarkets/1.0',
    'Accept': 'application/json',
  };

  final http.Client _client;
  final YahooParser _parser;
  final Duration timeout;

  @override
  String get providerName => 'Yahoo Finance';

  @override
  AssetCategory get category => AssetCategory.stock;

  @override
  Future<List<MarketAsset>> fetchAssetsWithHistory({int days = 30}) async {
    final range = days > 30 ? '3mo' : '1mo';
    final assets = <MarketAsset>[];

    final settled = await Future.wait(
      _specs.map((spec) async {
        try {
          final uri = Uri.https(
            'query1.finance.yahoo.com',
            '/v8/finance/chart/${spec.symbol}',
            {'range': range, 'interval': '1d'},
          );
          final resp =
              await _client.get(uri, headers: _headers).timeout(timeout);
          if (resp.statusCode != 200) {
            return null;
          }
          final parsed = _parser.parseChart(resp.body);
          if (parsed.candles.isEmpty) return null;

          return MarketAsset(
            symbol: spec.symbol,
            displayPair: spec.symbol,
            name: spec.name,
            category: AssetCategory.stock,
            quoteCurrency: 'USD',
            currentPrice: parsed.currentPrice,
            usdEquivalentPrice: parsed.currentPrice,
            change24hPercent: parsed.changePercent,
            source: providerName,
            updatedAt: DateTime.now(),
            candles: parsed.candles,
          );
        } catch (_) {
          return null;
        }
      }),
    );

    for (final item in settled) {
      if (item != null) assets.add(item);
    }

    if (assets.isEmpty) {
      throw const NetworkFailure('Источник акций Yahoo Finance недоступен');
    }

    return assets;
  }
}
