# Market Data & Architecture Research

**Feature**: `001-trading-terminal-specs` | **Date**: 2026-11-22

## Historical Data Sources Selection & Limitations

### 1. Crypto Market: Binance Public REST API
- **Endpoints**:
  - `GET https://api.binance.com/api/v3/klines?symbol={SYMBOL}USDT&interval=1d&limit=31`
  - `GET https://api.binance.com/api/v3/ticker/24hr?symbols=[...]`
- **Strengths**: Free, no API key required, returns full OHLCV daily candles (`open`, `high`, `low`, `close`, `volume`, `openTime`), sub-second latency, 30+ days immediately available on cold start.
- **Limitations**: Spot pairs quoted in `USDT`; regional/ISP blocks or rate limits (`429`) require graceful timeout and cache fallback.

### 2. Equities Market: Yahoo Finance Chart API v8
- **Endpoint**:
  - `GET https://query1.finance.yahoo.com/v8/finance/chart/{TICKER}?range=1mo&interval=1d`
- **Strengths**: Returns 1 month of daily OHLCV candles (`AAPL`, `NVDA`, `TSLA`, `MSFT`, `GOOGL`, `AMZN`) without an API key.
- **Limitations**: Unofficial public endpoint subject to `User-Agent` header filtering, market-closed weekend gaps (non-trading days omitted), and occasional HTTP `429` throttling. Handled via browser-like `User-Agent`, null-candle filtering, and persistent local fallback.

### 3. Major Forex Pairs: Frankfurter ECB API
- **Endpoint**:
  - `GET https://api.frankfurter.app/{YYYY-MM-DD}..{YYYY-MM-DD}?from=USD&to=EUR,GBP,JPY,CHF,RON`
- **Strengths**: Open-source ECB-backed historical daily time series over arbitrary date ranges (`35` calendar days to ensure `>= 22–30` trading points despite weekends), zero API keys.
- **Limitations**: Publishes daily ECB reference rates only on European business days (weekends/holidays omitted, close-only without intraday high/low wicks). Close values are cleanly mapped into synthetic flat-wick `CandlePoint` entries so charts and 7D/30D analytics work seamlessly.

### 4. Local Fiat Anchor (MDL): National Bank of Moldova (BNM) XML Gateway
- **Endpoint**:
  - `GET https://www.bnm.md/en/official_exchange_rates?get_xml=1&date=DD.MM.YYYY`
- **Strengths**: Official central bank rates (`USD/MDL`, `EUR/MDL`, `RON/MDL`, `RUB/MDL`) with explicit `<Nominal>` scaling.
- **Limitations**: Does not offer a single multi-day range endpoint; requires date-by-date requests for historical series (sampled for 7D/30D windows with concurrency cap + 7-day weekend/holiday rollback) and caches aggressively to minimize network round-trips.

## Why Historical API Fetching Over Local-Only Accumulation?

If historical points were only recorded locally from app installation time, a newly installed device would lack 7-day and 30-day charts during evaluation/defense. Combining **upstream 30-day historical APIs** with **persistent local JSON snapshot caching** solves both cold-start completeness and airplane-mode resilience.
