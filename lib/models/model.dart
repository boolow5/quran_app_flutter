// Model class for verses
class Verse {
  final String text;
  final int number;
  final int suraNumber;
  final String? bismillah;

  Verse({
    required this.text,
    required this.number,
    required this.suraNumber,
    this.bismillah,
  });

  factory Verse.fromJson(int suraNumber, Map<String, dynamic> json) {
    return Verse(
      text: json['text'] as String,
      number: json['index'] as int,
      suraNumber: suraNumber,
      bismillah: json['bismillah'] as String?,
    );
  }
}

class Sura {
  final int number;
  final String name;
  final String transliteratedName;
  final String englishName;
  final String type;

  Sura({
    required this.number,
    required this.name,
    required this.transliteratedName,
    required this.englishName,
    required this.type,
  });

  factory Sura.fromJson(int number, Map<String, dynamic> json) {
    return Sura(
      number: number,
      name: json['name'] as String,
      transliteratedName: json['tname'] as String,
      englishName: json['ename'] as String,
      type: json['type'] as String,
    );
  }
}
