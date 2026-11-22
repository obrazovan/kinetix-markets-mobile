# Feature Specification: Kinetix Markets — Mobile Trading Terminal & Analytics

**Feature Branch**: `001-trading-terminal-specs`
**Created**: 2026-11-22
**Status**: Approved
**Input**: User request: "TradingView-inspired cross-platform mobile application for Stocks, Crypto, and Forex quotes, multi-asset conversion, 7-day and 30-day comparison analytics, offline persistence, SOLID & Clean Code in Dart/Flutter."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Multi-Asset Market Terminal & Watchlist (Priority: P1)

A user opens **Kinetix Markets** on Android and sees a live TradingView-style market terminal organized by asset classes (**All**, **Stocks**, **Crypto**, **Forex**) with search filtering, real-time/latest quotes, 24h change badges, sparkline previews, and tap-to-inspect asset details with interactive candlestick/area charts.

**Why this priority**: Establishes the core trading terminal identity unifying Stocks (`AAPL`, `NVDA`, `TSLA`, `MSFT`, `GOOGL`, `AMZN`), Crypto (`BTC/USDT`, `ETH/USDT`, `SOL/USDT`, `TON/USDT`, `BNB/USDT`, `XRP/USDT`), and Forex (`EUR/USD`, `GBP/USD`, `USD/MDL`, `EUR/MDL`, `USD/JPY`, `USD/CHF`, `USD/RON`).

**Independent Test**: Launch app, switch tabs between All / Stocks / Crypto / Forex, search `BTC` or `AAPL`, tap an asset to inspect interactive OHLC candlestick chart and crosshairs.

**Acceptance Scenarios**:
1. **Given** live or cached quotes are loaded, **When** user selects the `Stocks` filter, **Then** only equities render with price, currency, change %, and mini sparkline.
2. **Given** user taps an asset (e.g., `BTC/USDT` or `EUR/USD`), **When** the Asset Detail / Chart sheet opens, **Then** an interactive candlestick/area chart renders with touch-drag crosshair inspecting Date, Open, High, Low, Close.

---

### User Story 2 - Mandatory 7-Day (Weekly) & 30-Day (Monthly) Comparison Analytics (Priority: P1)

A user navigates to the dedicated **Неделя (7D)** comparison screen or **Месяц (30D)** comparison screen (via bottom navigation or directly from an asset) to analyze performance dynamics over the last 7 days or 30 days.

**Why this priority**: Core mandatory requirement of Lab 4 Part 3 & Acceptance Criteria 5–6.

**Independent Test**: Open `Неделя (7D)` screen and `Месяц (30D)` screen for any asset (`BTC`, `AAPL`, `EUR/USD`, `USD/MDL`); verify chart, Minimum, Maximum, Average, Absolute Change, Percentage Change, and Trend Direction (`Рост` / `Падение` / `Без изменений`) are all displayed accurately.

**Acceptance Scenarios**:
1. **Given** 7 daily points exist for an asset, **When** `Неделя (7D)` screen renders, **Then** it displays: (a) 7-day price chart, (b) Period Min, (c) Period Max, (d) Period Average, (e) Absolute change (`+Δ` / `-Δ`), (f) Percentage change (`%`), and (g) Explicit Trend Direction (`Рост`, `Падение`, or `Без изменений`).
2. **Given** 30 daily points exist for an asset, **When** `Месяц (30D)` screen renders, **Then** it displays the 30-day price chart and all five mandatory statistical metrics plus period volatility/range context.
3. **Given** start and end prices are equal (delta `0.0`), **When** analytics compute, **Then** Trend Direction explicitly reads `Без изменений`.

---

### User Story 3 - Multi-Asset Converter & Strict Input Validation (Priority: P2)

A user opens the **Конвертер** tab to convert any positive amount across Forex, Crypto, and Stocks (e.g., `100 USD -> MDL`, `0.25 BTC -> EUR`, `2 AAPL -> USD`) with instant validation.

**Why this priority**: Preserves and expands Lab 3's converter capability into a multi-asset exchange desk on mobile without reusing Lab 3 code.

**Independent Test**: Enter `100,50` and convert `USD -> MDL`; then enter `0`, `-10`, empty string, or `abc` and verify the Convert button disables and displays a Russian validation error. Select `USD -> USD` and verify rate `1.0`.

**Acceptance Scenarios**:
1. **Given** user enters `125,5` (comma decimal), **When** parsed, **Then** it normalizes to `125.5` and computes accurate cross-rate and inverse rate.
2. **Given** input is empty, `0`, `-5`, or `abc`, **When** edited, **Then** Convert button is disabled and inline error explains why.
3. **Given** source and target assets match, **When** converted, **Then** rate equals `1.0` and output equals input.

---

### User Story 4 - Offline Resilience, Persistent Cache & Error Handling (Priority: P2)

When airplane mode is enabled or upstream APIs are unreachable/malformed, the app never crashes: it loads the last persisted snapshot from device storage (surviving app restarts), displays the exact cache timestamp banner, and handles missing cold-start cache gracefully.

**Why this priority**: Core mandatory requirement of Lab 4 Part 4 & Acceptance Criterion 7.

**Independent Test**: Load live data, enable Airplane Mode, force-close and relaunch the app; verify all markets, 7D/30D analytics, and converter still function using cached data and display `Офлайн-режим • Данные от ...`.

**Acceptance Scenarios**:
1. **Given** prior cached snapshots exist in persistent storage, **When** app launches with no network, **Then** cached quotes and 7D/30D series load immediately with an explicit offline banner showing snapshot date/time and a Retry button.
2. **Given** upstream returns HTTP 500 or malformed JSON/XML, **When** provider parses response, **Then** failure is caught cleanly, logged, and surfaced as a user-friendly status banner without crashing.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Application MUST be built in **Dart / Flutter** (zero Python/JS code reuse from Lab 3) targeting Android mobile devices.
- **FR-002**: Application MUST track multi-asset quotes and 7D/30D history across three markets:
  - **Crypto**: Binance Public Klines & 24hr Ticker API (`BTC`, `ETH`, `SOL`, `TON`, `BNB`, `XRP` quoted in `USDT`).
  - **Stocks**: Yahoo Finance Chart API (`AAPL`, `NVDA`, `TSLA`, `MSFT`, `GOOGL`, `AMZN`).
  - **Forex**: Frankfurter Historical API (`EUR/USD`, `GBP/USD`, `USD/JPY`, `USD/CHF`, `USD/RON`) + National Bank of Moldova XML gateway (`USD/MDL`, `EUR/MDL`, `RON/MDL`, `RUB/MDL` with `Nominal` scaling and weekend rollback up to 7 days).
- **FR-003**: Application MUST include dedicated **7-Day Comparison (`Неделя 7D`)** and **30-Day Comparison (`Месяц 30D`)** screens with interactive chart, Min, Max, Average, Absolute Change, Percentage Change, and explicit Trend Direction (`Рост`, `Падение`, `Без изменений`).
- **FR-004**: Application MUST persist latest quotes and historical 7D/30D series locally across app restarts and display explicit cached timestamp (`Данные актуальны на ...`) when offline.
- **FR-005**: Application MUST validate converter inputs in real time (accepting `.` and `,`, blocking empty/`0`/negative/non-numeric) and handle same-asset `1.0` conversion.
- **FR-006**: Application MUST provide comprehensive automated unit & widget tests runnable via `flutter test`.
