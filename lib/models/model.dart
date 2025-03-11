// Model class for verses
import 'package:MeezanSync/utils/utils.dart';

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

// class Sura {
//   final int number;
//   final String name;
//   final String transliteratedName;
//   final String englishName;
//   final String type;
//
//   Sura({
//     required this.number,
//     required this.name,
//     required this.transliteratedName,
//     required this.englishName,
//     required this.type,
//   });
//
//   factory Sura.fromJson(int number, Map<String, dynamic> json) {
//     return Sura(
//       number: number,
//       name: json['name'] as String,
//       transliteratedName: json['tname'] as String,
//       englishName: json['ename'] as String,
//       type: json['type'] as String,
//     );
//   }
// }

class RecentPage {
  final int pageNumber;
  final String suraName;
  final DateTime startDate;
  DateTime? endDate;

  RecentPage({
    required this.pageNumber,
    required this.suraName,
    required this.startDate,
    this.endDate,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() => {
        'pageNumber': pageNumber,
        'suraName': suraName,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      };

  // Create from JSON
  factory RecentPage.fromJson(Map<String, dynamic> json) {
    final startDate = parseDateTime(json['start_date'] ?? json['startDate']);
    print("start_date: ${json['start_date'] ?? json['startDate']} -> $startDate");
    final endDate = (json['end_date'] ?? json['endDate']) != null &&
            !(json['end_date'] ?? json['endDate']).toString().startsWith("000")
        ? parseDateTime((json['end_date'] ?? json['endDate']))
        : null;
    print("endDate: ${(json['end_date'] ?? json['endDate'])} -> $endDate");

    final page_number = parseField<int?>(json, 'page_number', parseField<int?>(json, 'pageNumber', null)) ?? 0;
    print("page_number: ${json['page_number'] ?? json['pageNumber']} -> $page_number");

    final sura_name = parseField<String?>(json, 'surah_name', parseField<String?>(json, 'surahName', parseField<String?>(json, 'suraName', null))) ?? "";
    print("sura_name: ${json['surah_name'] ?? json['surahName']?? json['suraName']} -> $sura_name");

    return RecentPage(
      pageNumber: page_number,
      suraName: sura_name,
      startDate: startDate ?? DateTime.now(),
      endDate: ((endDate?.year ?? 0) == 0
          ? startDate?.add(const Duration(seconds: 30))
          : endDate) ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'RecentPage(pageNumber: $pageNumber, suraName: $suraName, startDate: $startDate, endDate: $endDate)';
  }
}

/*
// Golang struct for UserStreak
type UserStreak struct {
	UserID         uint64       `json:"user_id" db:"user_id"`
	CurrentStreak  int          `json:"current_streak" db:"current_streak"`
	LongestStreak  int          `json:"longest_streak" db:"longest_streak"`
	LastActiveDate sql.NullTime `json:"last_active_date" db:"last_active_date"`
}

*/
class UserStreak {
  final int userID;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;

  UserStreak({
    required this.userID,
    required this.currentStreak,
    required this.longestStreak,
    this.lastActiveDate,
  }) : assert(userID >= 0);

  // Convert to JSON
  Map<String, dynamic> toJson() => {
        'user_id': userID,
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'last_active_date': lastActiveDate?.toIso8601String(),
      };

  // Create from JSON
  factory UserStreak.fromJson(Map<String, dynamic> json) {
    final lastActiveDate = parseDateTime(json['last_active_date']) ??  parseDateTime(json['last_active_date']['Time']);
    print("last_active_date: ${json['last_active_date']} -> $lastActiveDate");
    return UserStreak(
      userID: parseField<int?>(json, 'user_id', null) ?? 0,
      currentStreak: parseField<int?>(json, 'current_streak', null) ?? 0,
      longestStreak: parseField<int?>(json, 'longest_streak', null) ?? 0,
      lastActiveDate: lastActiveDate,
    );
  }
}

class LeaderBoardItem {
  final int userID;
  final String name;
  final int score;
  final int streak;

  LeaderBoardItem({
    required this.userID,
    required this.name,
    required this.score,
    required this.streak,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() => {
        'user_id': userID,
        'name': name,
        'score': score,
        'streak': streak,
      };

  // Create from JSON
  factory LeaderBoardItem.fromJson(Map<String, dynamic> json) {
    return LeaderBoardItem(
      userID: parseField<int?>(json, 'user_id', null) ?? 0,
      name: parseField<String?>(json, 'name', null) ?? "",
      score: parseField<int?>(json, 'score', null) ?? 0,
      streak: parseField<int?>(json, 'streak', null) ?? 0,
    );
  }

  @override
  String toString() {
    return 'LeaderBoardItem(userID: $userID, name: $name, score: $score, streak: $streak)';
  }
}
