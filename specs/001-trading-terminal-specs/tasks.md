# Tasks: Kinetix Markets Mobile Terminal

## Phase 1: Spec Kit & Planning (`001-trading-terminal-specs`)
- [x] T001 Initialize repository and GitHub Spec Kit (`specify init`)
- [x] T002 Author Constitution, Feature Spec, Implementation Plan, Research, Data Model, Contracts, and Quickstart

## Phase 2: Domain, Data Providers & Offline Persistence (`feature/domain-and-providers`)
- [x] T003 Scaffold Flutter project (`pubspec.yaml`, Android manifest with INTERNET permission, strict `analysis_options.yaml`)
- [x] T004 Implement core failures, Russian/international numeric formatters, and input validator (`core/`)
- [x] T005 Implement domain entities (`MarketAsset`, `CandlePoint`, `PeriodAnalytics`, `MarketSnapshot`, `ConversionResult`) and repository interfaces (`domain/`)
- [x] T006 Implement `CalculatePeriodAnalytics` (7D/30D min, max, average, absolute & % change, trend direction, empty-set safety) and `ConvertAssets` use cases
- [x] T007 Implement dedicated response parsers (`BinanceParser`, `YahooParser`, `FrankfurterParser`, `BnmXmlParser` with Nominal scaling)
- [x] T008 Implement resilient providers (`BinanceMarketProvider`, `YahooStockProvider`, `FrankfurterForexProvider`, `BnmXmlProvider` with weekend rollback)
- [x] T009 Implement `LocalSnapshotCacheStore` (persistent JSON snapshot surviving restarts) and `MarketRepositoryImpl` (live + partial failure + offline fallback)

## Phase 3: TradingView-Style UI & Analytics Screens (`feature/tradingview-ui-and-analytics`)
- [x] T010 Implement bespoke *Obsidian Tape* (dark) and *Ivory Ledger* (light) Material 3 theme with tabular numerals
- [x] T011 Implement custom `CandleChartWidget` (`CustomPainter` candlestick & area modes, gridlines, min/max markers, touch crosshair OHLC inspector) and `SparklinePainter`
- [x] T012 Implement `MarketsTerminalScreen` (category chips All/Stocks/Crypto/Forex, live search, watchlist cards, offline banner with cache timestamp & retry)
- [x] T013 Implement `AssetDetailScreen` (interactive chart with 1W/1M switch, OHLC bar, quick stats summary)
- [x] T014 Implement dedicated `PeriodComparisonScreen` serving **Сравнение за неделю (7D)** and **Сравнение за месяц (30D)** tabs with chart, min, max, average, Δ, %, trend badge, and asset selector
- [x] T015 Implement `ConverterScreen` (multi-asset converter across Forex/Crypto/Stocks, `.`/`,` support, disabled button guard, swap, same-asset `1.0` identity)

## Phase 4: Verification Pyramid (`test/comprehensive-unit-and-widget-tests`)
- [x] T016 Unit tests for Binance, Yahoo, Frankfurter, and BNM XML parsers (including malformed payloads & non-unit Nominals)
- [x] T017 Unit tests for `CalculatePeriodAnalytics` (up, down, flat trends, 7D/30D slicing, empty dataset behavior)
- [x] T018 Unit tests for `InputValidator`, `ConvertAssets`, and `LocalSnapshotCacheStore` offline persistence across restarts
- [x] T019 Widget tests verifying Weekly (7D) screen, Monthly (30D) screen, converter disabled-submit validation, and offline banner rendering

## Phase 5: Documentation & Lab Report (`docs/report-and-readme`)
- [x] T020 Author comprehensive `README.md` with single-command test instructions and APK run guide
- [x] T021 Author detailed `REPORT.md` covering all 6 mandatory sections (including data source trade-offs and AI-in-new-language reflection)
- [x] T022 Verify `flutter analyze`, `flutter test`, and `flutter build apk --debug` pass cleanly
