import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_markets/core/errors/failures.dart';
import 'package:kinetix_markets/data/parsers/binance_parser.dart';
import 'package:kinetix_markets/data/parsers/bnm_xml_parser.dart';
import 'package:kinetix_markets/data/parsers/frankfurter_parser.dart';
import 'package:kinetix_markets/data/parsers/yahoo_parser.dart';

void main() {
  group('BinanceParser', () {
    const parser = BinanceParser();

    test('parses valid klines and skips malformed rows', () {
      const payload = '''
      [
        [1700000000000, "36000.0", "37500.5", "35500.0", "37000.25", "1234.5"],
        ["bad"],
        [1700086400000, "37000.25", "38000.0", "36800.0", "37850.0", "980.0"]
      ]
      ''';
      final candles = parser.parseKlines(payload);
      expect(candles, hasLength(2));
      expect(candles.first.open, 36000.0);
      expect(candles.last.close, 37850.0);
      expect(candles.first.isBullish, isTrue);
    });

    test('parses 24hr tickers and rejects invalid JSON', () {
      const tickersPayload =
          '[{"symbol":"BTCUSDT","lastPrice":"94500.12","priceChangePercent":"3.45"}]';
      final map = parser.parseTickers24h(tickersPayload);
      expect(map['BTCUSDT']?.price, 94500.12);
      expect(map['BTCUSDT']?.changePercent, 3.45);

      expect(
        () => parser.parseKlines('{not-json'),
        throwsA(isA<ParseFailure>()),
      );
    });
  });

  group('YahooParser', () {
    const parser = YahooParser();

    test('parses chart candles and safely skips null trading intervals', () {
      const payload = '''
      {
        "chart": {
          "result": [
            {
              "meta": {"regularMarketPrice": 229.5},
              "timestamp": [1700000000, 1700086400, 1700172800],
              "indicators": {
                "quote": [
                  {
                    "open": [224.0, null, 227.0],
                    "high": [226.5, null, 230.0],
                    "low": [223.5, null, 226.0],
                    "close": [225.0, null, 229.5],
                    "volume": [1000, null, 1500]
                  }
                ]
              }
            }
          ]
        }
      }
      ''';
      final parsed = parser.parseChart(payload);
      expect(parsed.candles, hasLength(2));
      expect(parsed.currentPrice, 229.5);
      expect(parsed.changePercent, closeTo(2.0, 0.001));
    });

    test('throws ParseFailure on empty chart results', () {
      expect(
        () => parser.parseChart('{"chart":{"result":[]}}'),
        throwsA(isA<ParseFailure>()),
      );
    });
  });

  group('FrankfurterParser', () {
    const parser = FrankfurterParser();

    test('sorts dates chronologically and inverts EUR/GBP pairs', () {
      const payload = '''
      {
        "base": "USD",
        "rates": {
          "2026-11-20": {"EUR": 0.90, "JPY": 154.0},
          "2026-11-19": {"EUR": 0.92, "JPY": 152.0}
        }
      }
      ''';
      final series = parser.parseTimeSeries(payload, invertPairs: {'EUR'});
      expect(series['EUR']?.length, 2);
      expect(series['EUR']?.first.close, closeTo(1 / 0.92, 1e-6));
      expect(series['EUR']?.last.close, closeTo(1 / 0.90, 1e-6));
      expect(series['JPY']?.last.close, 154.0);
    });
  });

  group('BnmXmlParser', () {
    const parser = BnmXmlParser();

    test('parses BNM XML including non-unit Nominal scaling', () {
      const xml = '''
      <?xml version="1.0" encoding="UTF-8"?>
      <ValCurs Date="20.11.2026" name="Official exchange rates">
        <Valute ID="44">
          <CharCode>USD</CharCode>
          <Nominal>1</Nominal>
          <Name>US Dollar</Name>
          <Value>17.9200</Value>
        </Valute>
        <Valute ID="36">
          <CharCode>RUB</CharCode>
          <Nominal>100</Nominal>
          <Name>Russian Ruble</Name>
          <Value>21,9700</Value>
        </Valute>
      </ValCurs>
      ''';

      final parsed = parser.parseXml(xml);
      expect(parsed.dateLabel, '20.11.2026');
      expect(parsed.ratesByCode['USD']?.ratePerUnitMdl, closeTo(17.92, 1e-6));
      expect(parsed.ratesByCode['RUB']?.ratePerUnitMdl, closeTo(0.2197, 1e-6));
    });

    test('returns empty rates map on weekend/holiday empty ValCurs', () {
      const emptyWeekendXml = '<ValCurs Date="22.11.2026"></ValCurs>';
      final parsed = parser.parseXml(emptyWeekendXml);
      expect(parsed.isEmpty, isTrue);
    });

    test('throws ParseFailure on invalid XML', () {
      expect(
        () => parser.parseXml('<broken'),
        throwsA(isA<ParseFailure>()),
      );
    });
  });
}
