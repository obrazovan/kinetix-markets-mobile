import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/errors/failures.dart';
import '../../domain/entities/market_asset.dart';
import '../parsers/binance_parser.dart';
import 'market_data_provider.dart';

class _CryptoSpec {
  const _CryptoSpec(this.symbol, this.name);
  final String symbol;
  final String name;
}

/// Fetches live quotes and 30D daily OHLCV candles from Binance Public REST API.
class BinanceMarketProvider implements MarketDataProvider {
  BinanceMarketProvider({
    required http.Client client,
    BinanceParser? parser,
    this.timeout = const Duration(seconds: 8),
  })  : _client = client,
        _parser = parser ?? const BinanceParser();

  static const _specs = <_CryptoSpec>[
    _CryptoSpec('BTC', 'Bitcoin'),
    _CryptoSpec('ETH', 'Ethereum'),
    _CryptoSpec('SOL', 'Solana'),
    _CryptoSpec('TON', 'Toncoin'),
    _CryptoSpec('BNB', 'BNB'),
    _CryptoSpec('XRP', 'XRP'),
  ];

  final http.Client _client;
  final BinanceParser _parser;
  final Duration timeout;

  @override
  String get providerName => 'Binance';

  @override
  AssetCategory get category => AssetCategory.crypto;

  @override
  Future<List<MarketAsset>> fetchAssetsWithHistory({int days = 30}) async {
    final pairs = _specs.map((s) => '${s.symbol}USDT').toList(growable: false);
    final tickerUri = Uri.https('api.binance.com', '/api/v3/ticker/24hr', {
      'symbols': jsonEncode(pairs),
    });

    Map<String, ({double price, double changePercent})> tickers = const {};
    try {
      final tickerResp = await _client.get(tickerUri).timeout(timeout);
      if (tickerResp.statusCode == 200) {
        tickers = _parser.parseTickers24h(tickerResp.body);
      }
    } catch (_) {
      // Non-fatal: fallback to latest kline close if 24hr ticker throttles.
    }

    final limit = (days + 1).clamp(7, 60).toString();
    final futures = _specs.map((spec) async {
      final pair = '${spec.symbol}USDT';
      final klineUri = Uri.https('api.binance.com', '/api/v3/klines', {
        'symbol': pair,
        'interval': '1d',
        'limit': limit,
      });
      final resp = await _client.get(klineUri).timeout(timeout);
      if (resp.statusCode != 200) {
        throw NetworkFailure(
          'Binance HTTP ${resp.statusCode} для $pair',
        );
      }
      final candles = _parser.parseKlines(resp.body);
      if (candles.isEmpty) {
        throw ParseFailure('Пустые свечи Binance для $pair');
      }

      final ticker = tickers[pair];
      final currentPrice = ticker?.price ?? candles.last.close;
      final prevClose =
          candles.length >= 2 ? candles[candles.length - 2].close : currentPrice;
      final changePct = ticker?.changePercent ??
          (prevClose > 0 ? ((currentPrice - prevClose) / prevClose) * 100 : 0.0);

      return MarketAsset(
        symbol: spec.symbol,
        displayPair: '${spec.symbol}/USDT',
        name: spec.name,
        category: AssetCategory.crypto,
        quoteCurrency: 'USDT',
        currentPrice: currentPrice,
        usdEquivalentPrice: currentPrice,
        change24hPercent: changePct,
        source: providerName,
        updatedAt: DateTime.now(),
        candles: candles,
      );
    });

    final results = await Future.wait(futures);
    return results;
  }
}
