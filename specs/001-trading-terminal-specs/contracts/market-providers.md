# Market Provider Contracts

**Feature**: `001-trading-terminal-specs`

## Abstract Interfaces (SOLID ISP / DIP)

### `MarketDataProvider`
```dart
abstract interface class MarketDataProvider {
  String get providerName;
  AssetCategory get category;
  Future<List<MarketAsset>> fetchAssetsWithHistory({int days = 30});
}
```

### `SnapshotCacheStore`
```dart
abstract interface class SnapshotCacheStore {
  Future<void> saveSnapshot(MarketSnapshot snapshot);
  Future<MarketSnapshot?> loadSnapshot();
  Future<void> clear();
}
```

## Upstream Payload Contracts

1. **Binance Klines (`GET /api/v3/klines`)**:
   - Array of arrays `[openTimeMs, openStr, highStr, lowStr, closeStr, volumeStr, ...]`.
   - Must safely skip malformed elements and parse string decimals via `double.tryParse`.
2. **Yahoo Finance Chart (`GET /v8/finance/chart/{ticker}`)**:
   - JSON `chart.result[0].timestamp` + `indicators.quote[0].{open,high,low,close,volume}`.
   - Arrays may contain `null` elements on non-trading intervals; parser must zip safely and skip nulls.
3. **Frankfurter Range (`GET /{start}..{end}?from=USD&to=EUR,GBP,JPY,CHF,RON`)**:
   - JSON `{ "base": "USD", "rates": { "YYYY-MM-DD": { "EUR": 0.92, ... } } }`.
   - Must sort date keys chronologically and compute inverted pairs (`EUR/USD = 1 / rate`) where appropriate.
4. **BNM XML (`GET /en/official_exchange_rates?get_xml=1&date=DD.MM.YYYY`)**:
   - `<ValCurs Date="DD.MM.YYYY"><Valute><CharCode>USD</CharCode><Nominal>1</Nominal><Value>17.92</Value></Valute>...</ValCurs>`.
   - Empty `<ValCurs>` on weekends/holidays triggers deterministic rollback up to 7 calendar days.
