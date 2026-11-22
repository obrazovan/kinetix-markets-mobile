# Kinetix Markets — Мобильный торговый терминал (Flutter / Dart)

Кроссплатформенное мобильное приложение (Android / iOS-ready) в стиле **TradingView** для отслеживания котировок **акций**, **криптовалют** и **Forex**, интерактивного анализа графиков, сравнения динамики за **7 дней** и **30 дней**, а также кросс-конвертации активов с полноценным оффлайн-кэшированием.

Проект выполнен с нуля на языке **Dart (Flutter 3.50)** по методологии **Spec-Driven Development** (GitHub Spec Kit), **Clean Architecture** и принципам **SOLID** — без переиспользования кода из Лабораторной работы №3 (Python / JavaScript).

---

## Основные возможности

- **Мультирыночный терминал (`Рынок`)**:
  - **Акции (Stocks)**: `AAPL`, `NVDA`, `TSLA`, `MSFT`, `GOOGL`, `AMZN` (Yahoo Finance Chart API v8)
  - **Криптовалюты (Crypto)**: `BTC/USDT`, `ETH/USDT`, `SOL/USDT`, `TON/USDT`, `BNB/USDT`, `XRP/USDT` (Binance Public REST API)
  - **Forex**: `EUR/USD`, `GBP/USD`, `USD/JPY`, `USD/CHF`, `USD/RON` (Frankfurter ECB) + `USD/MDL`, `EUR/MDL`, `RON/MDL`, `RUB/MDL` (официальный XML НБМ с учётом `Nominal` и откатом выходных до 7 дней)
  - Фильтрация по категориям (`Все`, `Акции`, `Крипто`, `Forex`), живой поиск, мини-графики (sparklines) и экран деталей актива с перекрестием OHLC.
- **Экран сравнения за неделю (`Неделя 7Д`)** и **Экран сравнения за месяц (`Месяц 30Д`)**:
  - Кастомный интерактивный `CustomPainter` график (режимы **Свечи** и **Линия**, пунктирная линия среднего значения, touch-перекрестие)
  - Минимум, Максимум и Среднее значение за период
  - Изменение за период в абсолютных единицах и в процентах (`Δ` и `%`)
  - Явный индикатор направления тенденции (**Рост**, **Падение**, **Без изменений**)
  - Контекстное сопоставление недельного и месячного импульса на экране 30Д
- **Мультивалютный конвертер (`Конвертер`)**:
  - Конвертация между фиатом, криптовалютами и акциями через базовую единицу USD
  - Поддержка разделителей `.` и `,`, мгновенная блокировка кнопки при пустом вводе, `0`, отрицательных или нечисловых значениях
  - Детерминированный курс `1.0` для одинаковых активов и кнопка быстрого обмена (`⇄`)
- **Оффлайн-режим и устойчивость**:
  - Автоматическое локальное сохранение снимка котировок и 30-дневной истории (`SharedPreferences`), переживающее перезапуск приложения
  - Явный баннер оффлайн-режима с датой и временем актуальности кэша + кнопка повторного подключения
  - Грациозная обработка таймаутов, ошибок HTTP и повреждённых ответов без аварийного завершения
- **Уникальная тема интерфейса**:
  - *Obsidian Tape* (тёмный биржевой терминал) и *Ivory Ledger* (дневная тема) с табличной моноширинной типографикой (`FontFeature.tabularFigures`).

---

## Архитектура (Clean Architecture + SOLID)

```text
lib/
├── main.dart
├── app/
│   ├── app.dart                         # Корневой виджет и темы Material 3
│   ├── di/service_locator.dart          # Composition Root (Dependency Inversion)
│   └── theme/terminal_theme.dart        # Палитры Obsidian Tape & Ivory Ledger
├── core/
│   ├── errors/failures.dart             # Иерархия доменных и сетевых ошибок
│   ├── formatters/number_formatter.dart # Адаптивное форматирование цен и дат
│   └── utils/input_validator.dart       # Валидация пользовательского ввода
├── domain/
│   ├── entities/                        # Иммутабельные модели (MarketAsset, CandlePoint, PeriodAnalytics, ...)
│   ├── repositories/                    # Абстрактные контракты (MarketRepository, SnapshotCacheStore)
│   └── usecases/                        # CalculatePeriodAnalytics, ConvertAssets, LoadMarketSnapshot
├── data/
│   ├── parsers/                         # Изолированные парсеры (Binance, Yahoo, Frankfurter, BNM XML)
│   ├── datasources/                     # Провайдеры MarketDataProvider (OCP / LSP / ISP)
│   ├── cache/                           # LocalSnapshotCacheStore (персистентность)
│   └── repositories/                    # MarketRepositoryImpl (агрегация и fallback)
└── presentation/
    ├── controllers/                     # MarketTerminalController, ConverterController
    ├── screens/                         # Markets, AssetDetail, PeriodComparison (7D/30D), Converter
    └── widgets/                         # CandleChartWidget (CustomPainter), Sparkline, OfflineBanner
```

---

## Быстрый старт и запуск тестов

### Требования
- Flutter SDK `3.50+` (Dart `3.10+`)
- JDK `17` и Android SDK (для сборки APK и запуска на эмуляторе/устройстве)

### 1. Установка зависимостей

```powershell
flutter pub get
```

### 2. Запуск всех unit- и widget-тестов одной командой

```powershell
flutter test
```

### 3. Статический анализ кода

```powershell
flutter analyze
```

### 4. Сборка Android APK и запуск на эмуляторе/устройстве

```powershell
flutter build apk --debug
flutter run
```
