# Implementation Plan: Kinetix Markets Mobile Terminal

**Branch**: `001-trading-terminal-specs` | **Date**: 2026-11-22 | **Spec**: [spec.md](./spec.md)

## Summary

Build **Kinetix Markets**, a production-grade Flutter/Dart cross-platform mobile trading terminal (Android primary target) following Clean Architecture + SOLID principles. The app aggregates live and 30-day historical market data across Stocks (Yahoo Finance), Crypto (Binance Public API), and Forex (Frankfurter + BNM XML with weekend fallback), renders interactive custom-painted candlestick & area charts, provides mandatory **7-Day (Weekly)** and **30-Day (Monthly)** statistical comparison screens, includes a multi-asset converter with strict validation, and persists full market snapshots locally for seamless offline survival across restarts.

## Technical Context

- **Language / Framework**: Dart 3.x / Flutter 3.x (Material 3, zero external chart bloat — custom `CustomPainter` OHLC & area canvas)
- **Architecture**: Clean Architecture (`core/`, `domain/`, `data/`, `presentation/`) + Constructor Dependency Injection + `ChangeNotifier` state controllers
- **Networking**: `http` package with explicit timeouts (`8s`) and structured failure mapping (`NetworkFailure`, `ParseFailure`)
- **XML Parsing**: `xml` package for BNM official exchange rates (supporting non-unit `<Nominal>` scaling and 7-day holiday rollback)
- **Local Persistence**: `shared_preferences` / file-backed JSON snapshot store persisting quotes + 30-day candle series + cached timestamp across app restarts
- **Testing**: `flutter_test` (unit tests for all parsers, analytics math, empty-dataset guards, input validation, offline cache recovery; widget tests for 7D/30D screens, converter validation, and offline banner)

## Project Structure

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── di/service_locator.dart
│   └── theme/terminal_theme.dart
├── core/
│   ├── errors/failures.dart
│   ├── formatters/number_formatter.dart
│   └── utils/input_validator.dart
├── domain/
│   ├── entities/
│   │   ├── market_asset.dart
│   │   ├── candle_point.dart
│   │   ├── period_analytics.dart
│   │   ├── conversion_result.dart
│   │   └── market_snapshot.dart
│   ├── repositories/
│   │   ├── market_repository.dart
│   │   └── snapshot_cache_store.dart
│   └── usecases/
│       ├── calculate_period_analytics.dart
│       ├── convert_assets.dart
│       └── load_market_snapshot.dart
├── data/
│   ├── datasources/
│   │   ├── market_data_provider.dart
│   │   ├── binance_market_provider.dart
│   │   ├── yahoo_stock_provider.dart
│   │   ├── frankfurter_forex_provider.dart
│   │   └── bnm_xml_provider.dart
│   ├── parsers/
│   │   ├── binance_parser.dart
│   │   ├── yahoo_parser.dart
│   │   ├── frankfurter_parser.dart
│   │   └── bnm_xml_parser.dart
│   ├── cache/
│   │   └── local_snapshot_cache_store.dart
│   └── repositories/
│       └── market_repository_impl.dart
└── presentation/
    ├── controllers/
    │   ├── market_terminal_controller.dart
    │   └── converter_controller.dart
    ├── screens/
    │   ├── home_shell_screen.dart
    │   ├── markets_terminal_screen.dart
    │   ├── asset_detail_screen.dart
    │   ├── period_comparison_screen.dart
    │   └── converter_screen.dart
    └── widgets/
        ├── candle_chart_widget.dart
        ├── sparkline_painter.dart
        ├── asset_badge.dart
        ├── offline_status_banner.dart
        └── analytics_metric_tile.dart
test/
├── unit/
│   ├── parsers_test.dart
│   ├── period_analytics_test.dart
│   ├── input_validator_test.dart
│   ├── convert_assets_test.dart
│   └── offline_cache_test.dart
└── widget/
    ├── comparison_screens_test.dart
    └── converter_and_offline_test.dart
```

## Complexity Tracking

- Custom `CustomPainter` chosen over third-party chart packages to guarantee crisp TradingView-grade OHLC candlestick + crosshair interaction, zero version incompatibilities, and exact visual polish offline.
- Multi-provider resilient aggregation (`Binance` + `Yahoo` + `Frankfurter` + `BNM`) allows partial failure tolerance: if one upstream API throttles, remaining markets continue updating and fallback series keep the terminal usable.
