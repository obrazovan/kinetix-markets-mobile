# Domain Data Model

**Feature**: `001-trading-terminal-specs`

## Core Entities

### 1. `AssetCategory` (enum)
- `stock` (Акции)
- `crypto` (Крипто)
- `forex` (Forex)

### 2. `MarketAsset`
- `symbol`: `String` (e.g., `BTC`, `AAPL`, `EUR/USD`, `USD/MDL`)
- `displayPair`: `String` (e.g., `BTC/USDT`, `AAPL/USD`, `EUR/USD`)
- `name`: `String` (e.g., `Bitcoin`, `Apple Inc.`, `Euro / US Dollar`)
- `category`: `AssetCategory`
- `quoteCurrency`: `String` (`USDT`, `USD`, `MDL`, etc.)
- `currentPrice`: `double`
- `usdEquivalentPrice`: `double` (normalized USD price for unified cross-asset conversion)
- `change24hPercent`: `double`
- `source`: `String` (`Binance`, `Yahoo Finance`, `Frankfurter ECB`, `BNM XML`)
- `updatedAt`: `DateTime`
- `candles`: `List<CandlePoint>` (chronologically sorted up to 31 daily points)

### 3. `CandlePoint`
- `timestamp`: `DateTime`
- `open`: `double`
- `high`: `double`
- `low`: `double`
- `close`: `double`
- `volume`: `double`

### 4. `TrendDirection` (enum)
- `up` (`Рост`) — when `absoluteChange > epsilon`
- `down` (`Падение`) — when `absoluteChange < -epsilon`
- `flat` (`Без изменений`) — when `|absoluteChange| <= epsilon`

### 5. `PeriodAnalytics`
- `timeframe`: `AnalyticsTimeframe` (`week7d` | `month30d`)
- `assetSymbol`: `String`
- `points`: `List<CandlePoint>`
- `startPrice`: `double`
- `endPrice`: `double`
- `minPrice`: `double`
- `maxPrice`: `double`
- `averagePrice`: `double`
- `absoluteChange`: `double` (`endPrice - startPrice`)
- `percentChange`: `double` (`((endPrice - startPrice) / startPrice) * 100`)
- `trend`: `TrendDirection`
- `isEmpty`: `bool`

### 6. `MarketSnapshot`
- `assets`: `List<MarketAsset>`
- `fetchedAt`: `DateTime`
- `isOffline`: `bool`
- `warnings`: `List<String>`

### 7. `ConversionResult`
- `amount`: `double`
- `fromSymbol`: `String`
- `toSymbol`: `String`
- `convertedAmount`: `double`
- `directRate`: `double`
- `inverseRate`: `double`
- `rateTimestamp`: `DateTime`
- `isSameAsset`: `bool`
- `isOffline`: `bool`
