import 'package:MeezanSync/utils/utils.dart';

class Sura {
  final int number;
  final String name;
  final String transliteration;
  final String englishName;
  final String type;
  final int startPage;

  Sura({
    required this.number,
    required this.name,
    required this.transliteration,
    required this.englishName,
    required this.type,
    required this.startPage,
  });

  factory Sura.fromJson(int number, Map<String, dynamic> json) {
    try {
      if (number < 1) {
        number = parseField<int>(json, 'index', 0);
      }
      return Sura(
        number: number,
        name: parseField<String>(json, 'name', ''),
        transliteration: parseField<String?>(json, 'tname',
                parseField<String>(json, 'transliteration', '')) ??
            '',
        englishName: parseField<String?>(
                json, 'ename', parseField<String>(json, 'englishName', '')) ??
            '',
        type: parseField<String>(json, 'type', ''),
        startPage: parseField<int>(json, 'startPage', 0),
      );
    } catch (err) {
      print("Error parsing sura: $err");
      print((json));

      return Sura(
        number: 0,
        name: "",
        transliteration: "",
        englishName: "",
        type: "",
        startPage: 0,
      );
    }
  }
}
