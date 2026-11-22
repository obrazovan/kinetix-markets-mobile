import 'package:xml/xml.dart';

import '../../core/errors/failures.dart';

/// Single currency entry extracted from BNM official XML feed.
class BnmRateEntry {
  const BnmRateEntry({
    required this.charCode,
    required this.nominal,
    required this.name,
    required this.value,
  });

  final String charCode;
  final int nominal;
  final String name;
  final double value;

  /// Rate normalized per 1 unit of [charCode] expressed in MDL.
  double get ratePerUnitMdl => nominal <= 0 ? value : value / nominal;
}

/// Parsed BNM daily XML snapshot.
class BnmDayRates {
  const BnmDayRates({
    required this.dateLabel,
    required this.ratesByCode,
  });

  final String dateLabel;
  final Map<String, BnmRateEntry> ratesByCode;

  bool get isEmpty => ratesByCode.isEmpty;
}

/// Parses National Bank of Moldova `<ValCurs>` XML payloads.
class BnmXmlParser {
  const BnmXmlParser();

  BnmDayRates parseXml(String rawXml) {
    if (rawXml.trim().isEmpty) {
      throw const ParseFailure('Пустой XML-ответ от НБМ');
    }

    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(rawXml);
    } catch (e) {
      throw ParseFailure('Некорректный XML от НБМ', e.toString());
    }

    final root = doc.rootElement;
    if (root.name.local != 'ValCurs') {
      throw const ParseFailure('Отсутствует корневой узел <ValCurs> в XML НБМ');
    }

    final dateLabel = root.getAttribute('Date') ?? '';
    final map = <String, BnmRateEntry>{};

    for (final valute in root.findElements('Valute')) {
      final code = valute.getElement('CharCode')?.innerText.trim() ?? '';
      final nominalRaw = valute.getElement('Nominal')?.innerText.trim() ?? '1';
      final name = valute.getElement('Name')?.innerText.trim() ?? code;
      final valueRaw =
          (valute.getElement('Value')?.innerText.trim() ?? '').replaceAll(',', '.');

      final nominal = int.tryParse(nominalRaw);
      final value = double.tryParse(valueRaw);

      if (code.isEmpty ||
          nominal == null ||
          nominal <= 0 ||
          value == null ||
          value <= 0 ||
          value.isNaN ||
          value.isInfinite) {
        continue;
      }

      map[code.toUpperCase()] = BnmRateEntry(
        charCode: code.toUpperCase(),
        nominal: nominal,
        name: name,
        value: value,
      );
    }

    return BnmDayRates(dateLabel: dateLabel, ratesByCode: map);
  }
}
