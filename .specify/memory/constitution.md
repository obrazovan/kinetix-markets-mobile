# Kinetix Markets Mobile Terminal Constitution

## Core Principles

### I. Language Separation & Clean-Room Implementation (NON-NEGOTIABLE)
The mobile application MUST be implemented 100% from scratch in **Dart (Flutter)**, strictly distinct from Lab 3's Python and JavaScript/HTML/CSS codebase. Zero code, modules, or verbatim logic from Lab 3 may be copied or automatically translated. All domain entities, parsers, analytics calculators, caching, and UI components MUST be architected natively in idiomatic Dart.

### II. Clean Architecture & SOLID Principles
Codebase MUST follow strict layered Clean Architecture (`core/`, `domain/`, `data/`, `presentation/`) with explicit adherence to SOLID:
- **Single Responsibility (SRP)**: Separate market data providers, response parsers, analytics statistical calculator, conversion engine, offline cache repository, and UI widgets.
- **Open/Closed (OCP)**: Adding a new asset class or market provider requires implementing the abstract `MarketDataProvider` interface without modifying domain use cases or UI state controllers.
- **Liskov Substitution (LSP)**: Every `MarketDataProvider` (`BinanceMarketProvider`, `YahooFinanceProvider`, `FrankfurterForexProvider`, `BnmXmlProvider`) MUST adhere strictly to `MarketQuote` and `CandleSeries` contracts.
- **Interface Segregation (ISP)**: Split narrow abstractions for `QuoteStreamSource`, `HistoricalSeriesSource`, and `LocalSnapshotStore`.
- **Dependency Inversion (DIP)**: Controllers and use cases depend solely on domain repository interfaces injected via constructor DI, enabling deterministic offline/mocked unit testing.

### III. Mandatory Weekly (7D) & Monthly (30D) Analytics
Every tracked asset (Stocks, Crypto, Forex) MUST expose dedicated **7-Day Comparison** and **30-Day Comparison** analytics views containing:
- Interactive time-series price chart (candlestick & area modes with touch crosshair inspection)
- Period Minimum and Maximum values
- Arithmetic Mean (Average) value for the period
- Absolute change (`Δ`) and Percentage change (`%`) across the period
- Explicit Trend Direction indicator: **Growth (Рост)**, **Decline (Падение)**, or **Flat / Unchanged (Без изменений)**

### IV. Offline-First Resilience & Error Safety (NON-NEGOTIABLE)
Network timeouts, HTTP 4xx/5xx errors, DNS failures, airplane mode, or malformed upstream responses MUST NEVER crash the application. Every successful market snapshot and historical series MUST be persisted locally so data survives full app restarts. When operating offline or on cached data, the UI MUST prominently display the cached data freshness timestamp (`Данные из кэша от ...`) and provide a non-blocking Retry control.

### V. Precision & Input Boundary Validation
Financial quotes, cross-asset conversions, and statistical analytics MUST validate all inputs strictly:
- Accept `.` and `,` decimal separators cleanly.
- Reject empty inputs, `0`, negative numbers, `NaN`, `Infinity`, and non-numeric strings at both UI (disabling conversion action with clear message) and domain boundary (`ValidationFailure`).
- Identical asset conversion (`A -> A`) MUST deterministically yield rate `1.0` without error.
- Empty historical datasets MUST never throw range/division-by-zero exceptions.

### VI. Bespoke Trading Terminal UI
The interface MUST deliver a distinct, production-grade *Obsidian Tape / Ivory Ledger* TradingView-inspired mobile aesthetic: custom `CustomPainter` OHLC candlestick and gradient area charts, tabular monospace numerals, crisp market category chips (`All`, `Stocks`, `Crypto`, `Forex`), custom vector asset badges, and full dark/light theme support.

### VII. Spec-Driven Git & Verification Discipline
Specifications MUST be committed on a dedicated branch before implementation code. Each stage (Specs, Domain & Data, UI & Analytics, Tests, Report & Docs) MUST evolve on separate feature branches with meaningful commits and merge into `main` via Pull Requests. All unit and widget tests MUST execute via a single documented `flutter test` command.

## Governance

This constitution supersedes ad-hoc implementation choices. Any deviation MUST be documented in `plan.md` and `REPORT.md`.

**Version**: 1.0.0 | **Ratified**: 2026-11-22
