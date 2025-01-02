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

  factory Sura.fromJson(Map<String, dynamic> json) {
    return Sura(
      number: json['number'],
      name: json['name'],
      transliteration: json['transliteration'],
      englishName: json['englishName'],
      type: json['type'],
      startPage: json['startPage'],
    );
  }
}
