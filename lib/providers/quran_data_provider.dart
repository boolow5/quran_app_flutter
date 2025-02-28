import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quran_app_flutter/models/sura.dart';
import 'package:quran_app_flutter/services/api_service.dart';
import 'package:quran_app_flutter/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final startDate = parseDateTime(json['start_date']) ?? DateTime.now();
    print("start_date: ${json['start_date']} -> $startDate");
    final endDate = json['end_date'] != null &&
            !json['end_date'].toString().startsWith("000")
        ? parseDateTime(json['end_date'])
        : null;
    print("endDate: ${json['end_date']} -> $endDate");

    return RecentPage(
      pageNumber: parseField<int?>(json, 'page_number', null) ?? 0,
      suraName: parseField<String?>(json, 'surah_name', null) ?? "",
      startDate: startDate,
      endDate: (endDate?.year ?? 0) == 0
          ? startDate.add(const Duration(seconds: 30))
          : endDate,
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
    final lastActiveDate = parseDateTime(json['last_active_date']);
    return UserStreak(
      userID: parseField<int?>(json, 'user_id', null) ?? 0,
      currentStreak: parseField<int?>(json, 'current_streak', null) ?? 0,
      longestStreak: parseField<int?>(json, 'longest_streak', null) ?? 0,
      lastActiveDate: lastActiveDate ?? DateTime.now(),
    );
  }
}

class QuranDataProvider extends ChangeNotifier {
  late Future<SharedPreferences> _storage;
  List<Sura> _tableOfContents = [];
  int _currentPage = 1;
  List<RecentPage> _recentPages = [];
  List<RecentPage> _bookmarks = [];
  String? _fcmToken;

  static const int maxRecentPages = 10;
  static const String _recentPagesKey = 'recent_pages';
  late SharedPreferences _prefs;
  bool _initialized = false;
  UserStreak _userStreak = UserStreak(
    userID: 0,
    currentStreak: 0,
    longestStreak: 0,
  );

  // Getters
  List<Sura> get tableOfContents => _tableOfContents;
  int get currentPage => _currentPage;
  List<RecentPage> get recentPages => List.unmodifiable(_recentPages);
  List<RecentPage> get bookmarks =>
      List.unmodifiable(_bookmarks.reversed.take(100).toList());
  List<RecentPage> get currentRecentPages =>
      _recentPages.isNotEmpty ? _recentPages.reversed.take(3).toList() : [];

  int get userStreakDays => _userStreak.currentStreak;
  String? get fcmToken => _fcmToken;

  set fcmToken(String? token) {
    _fcmToken = token;
    notifyListeners();
  }

  // Initialize shared preferences
  Future<void> init(Future<SharedPreferences> storage) async {
    if (_initialized) return;
    _storage = storage;
    _prefs = await _storage;
    _loadRecentPages();
    _loadBookmarks();
    _initialized = true;
  }

  // Load recent pages from SharedPreferences
  void _loadRecentPages() {
    final String? recentPagesJson = _prefs.getString(_recentPagesKey);
    if (recentPagesJson != null) {
      final List<dynamic> decoded = json.decode(recentPagesJson);
      _recentPages.clear();
      _recentPages.addAll(
        decoded.map(
          (item) => RecentPage.fromJson(item as Map<String, dynamic>),
        ),
      );
      notifyListeners();
    }
  }

  void _loadBookmarks() {
    final String? bookmarksJson = _prefs.getString('bookmarks');
    if (bookmarksJson != null) {
      final List<dynamic> decoded = json.decode(bookmarksJson);
      _bookmarks.clear();
      _bookmarks.addAll(
        decoded
            .map((item) => RecentPage.fromJson(item as Map<String, dynamic>)),
      );
      notifyListeners();
    }
  }

  // Save recent pages to SharedPreferences
  Future<void> _saveRecentPages() async {
    try {
      final pages = _recentPages
          .where((page) =>
              page.endDate != null &&
              page.endDate!.difference(page.startDate).inSeconds >= 30)
          .toList();

      final String encoded =
          json.encode(pages.map((page) => page.toJson()).toList());
      await _prefs.setString(_recentPagesKey, encoded);
    } catch (e) {
      print("Error saving recent pages: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> _saveBookmarks() async {
    // print("Saving bookmarks: $_bookmarks");
    final String encoded =
        json.encode(_bookmarks.map((page) => page.toJson()).toList());
    await _prefs.setString('bookmarks', encoded);
  }

  // Setters
  void setTableOfContents(List<Sura> toc) {
    _tableOfContents = toc;
    notifyListeners();
  }

  void setCurrentPage(int page, String suraName) {
    if (_currentPage != page) {
      // End timing for previous page
      if (_recentPages.isNotEmpty) {
        _recentPages.last.endDate = DateTime.now();
      }

      // Add new page or update existing in the recent list
      final int index = _recentPages.indexWhere((p) => p.pageNumber == page);
      if (index >= 0 && _recentPages[index].suraName == suraName) {
        _recentPages.removeAt(index);
      }
      _recentPages.add(RecentPage(
        pageNumber: page,
        suraName: suraName,
        startDate: DateTime.now(),
      ));

      // Keep only the last maxRecentPages entries
      if (_recentPages.length > maxRecentPages) {
        _recentPages.removeAt(0);
      }

      _currentPage = page;
      _recentPages = _recentPages
          .where((page) =>
              page.endDate != null &&
              page.endDate!.difference(page.startDate).inSeconds >= 10)
          .toList();
      _saveRecentPages(); // Persist changes
      notifyListeners();
    }
  }

  bool isBookmarked(int page, {bool isWideScreen = false}) {
    return _bookmarks.any((bookmark) => isWideScreen
        ? (page % 2 == 0 ? bookmark.pageNumber == page + 1 : false)
        : bookmark.pageNumber == page);
  }

  bool _addBookmark(int page, String suraName) {
    try {
      final int index =
          _bookmarks.indexWhere((bookmark) => bookmark.pageNumber == page);
      if (index >= 0) {
        // print('**************** Bookmark already exists ****************');
        final bookmark = RecentPage(
          pageNumber: _bookmarks[index].pageNumber,
          suraName: _bookmarks[index].suraName,
          startDate: DateTime.now(),
        );
        _bookmarks[index] = bookmark;
      } else {
        // print('**************** Adding bookmark ****************');
        _bookmarks.add(RecentPage(
          pageNumber: page,
          suraName: suraName,
          startDate: DateTime.now(),
        ));
      }

      _saveBookmarks(); // Persist changes
      return true;
    } catch (err) {
      // print('**************** Error adding bookmark: $err ****************');
      return false;
    } finally {
      notifyListeners();
    }
  }

  void removeBookmark(List<int> pages) {
    _bookmarks.removeWhere((bookmark) => pages.contains(bookmark.pageNumber));
    _saveBookmarks();
    notifyListeners();
  }

  Future<void> setRecentPage(
    int pageNumber,
    String suraName, {
    bool isDoublePage = false,
    int? secondsOpen = 0,
  }) async {
    if (secondsOpen != null && secondsOpen > 30) {
      final page = RecentPage(
        pageNumber: pageNumber,
        suraName: suraName,
        startDate: DateTime.now().subtract(Duration(seconds: secondsOpen)),
        endDate: DateTime.now(),
      );
      _recentPages.add(page);
      _saveRecentPages();
      notifyListeners();

      try {
        final saved = await sendReadEvent(pageNumber, suraName, secondsOpen);
        if (saved) {
          print("Read event sent successfully");
        } else {
          print("Error sending read event");
        }
      } catch (e) {
        print("Error sending read event: $e");
      }
    }
  }

  // Helper method to format duration
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  // Get reading duration for a recent page
  String getReadingDuration(RecentPage page) {
    if (page.endDate == null) return 'Reading...';

    final duration = page.endDate!.difference(page.startDate);
    return formatDuration(duration);
  }

  // Get time elapsed since reading
  String timeSinceReading(RecentPage page, {bool start = false}) {
    final DateTime referenceTime =
        (start ? page.startDate : page.endDate) ?? DateTime.now();
    final Duration elapsed = DateTime.now().difference(referenceTime);

    if (elapsed.inMinutes < 1) {
      return 'Just now';
    } else if (elapsed.inHours < 1) {
      return '${elapsed.inMinutes}m ago';
    } else if (elapsed.inDays < 1) {
      return '${elapsed.inHours}h ago';
    } else if (elapsed.inDays < 30) {
      return '${elapsed.inDays}d ago';
    } else if (elapsed.inDays < 365) {
      return '${(elapsed.inDays / 30).floor()}mon ago';
    } else {
      return '${(elapsed.inDays / 365).floor()}yr ago';
    }
  }

  Future<void> getBookmarks() async {
    try {
      final resp = await apiService.get(path: "/api/v1/bookmarks");
      print("getBookmarks: $resp");
      if (resp != null && resp.isNotEmpty) {
        print("getBookmarks Success: ${resp.length}");
        final bookmarks = resp ?? [];
        _bookmarks = List<RecentPage>.from(
            bookmarks.map((item) => RecentPage.fromJson(item)));
        print("getBookmarks: ${prettyJson(_bookmarks)}");
      } else {
        print("getBookmarks Failed: ${resp?.data}");
        throw resp?.data['message'] ?? 'Something went wrong';
      }
    } on DioException catch (e) {
      print("getBookmarks Dio Error: $e");
    } catch (e) {
      print("getBookmarks Uknown Error: $e");
    }
  }

  Future<bool> addBookmark(String? userID, int pageNumber, String suraName,
      {DateTime? startDate, DateTime? endDate}) async {
    bool saved = false;
    try {
      final resp = await apiService.post(
        path: "/api/v1/bookmarks",
        data: {
          "user_id": userID,
          "pageNumber": pageNumber,
          "suraName": suraName,
          "startDate": toUTCRFC3339(
            startDate ?? DateTime.now().add(Duration(seconds: -15)),
          ),
          "endDate": toUTCRFC3339(endDate ?? DateTime.now()),
        },
      );
      if (resp != null && resp?.statusCode == 200) {
        print("addBookmark Success: ${resp.data}");
        final bookmark = resp.data['data']['bookmark'];
        _bookmarks.add(RecentPage.fromJson(bookmark));
      } else {
        print("addBookmark Failed: ${resp?.data}");
        throw resp?.data['message'] ?? 'Something went wrong';
      }
    } on DioException catch (e) {
      print("addBookmark Dio Error: $e");
    } catch (e) {
      print("addBookmark Uknown Error: $e");
    } finally {
      saved = _addBookmark(pageNumber, suraName);
    }
    return saved;
  }

  Future<bool> sendReadEvent(
    int pageNumber,
    String suraName,
    int seconds,
  ) async {
    bool sent = false;
    try {
      final resp = await apiService.post(
        path: "/api/v1/streaks/read-event",
        data: {
          "page_number": pageNumber,
          "surah_name": suraName,
          "seconds_open": seconds,
        },
      );
      print("sendReadEvent: $resp");
      if (resp != null && resp["success"] == true) {
        print("sendReadEvent Success: ${resp['message']}");
        sent = true;
      } else {
        print("sendReadEvent Failed: ${resp?.data}");
        throw resp?.data['message'] ?? 'Something went wrong';
      }
    } on DioException catch (e) {
      print("sendReadEvent Dio Error: $e");
    } catch (e) {
      print("sendReadEvent Uknown Error: $e");
    }
    return sent;
  }

  Future<void> getUserStreak() async {
    try {
      final resp = await apiService.get(path: "/api/v1/streaks");
      print("getUserStreak: $resp");
      if (resp != null && resp["user_id"] > 0) {
        print("getUserStreak Success: ${resp['current_streak']}");
        _userStreak = UserStreak.fromJson(resp);
        notifyListeners();
      } else {
        print("getUserStreak Failed: ${resp?.data}");
        throw resp?.data['message'] ?? 'Something went wrong';
      }
    } on DioException catch (e) {
      print("getUserStreak Dio Error: $e");
    } catch (e) {
      print("getUserStreak Uknown Error: $e");
    }
  }

  Future<void> createOrUpdateFCMToken(String fcmToken) async {
    print("createOrUpdateFCMToken: $fcmToken");
    final resp = await apiService
        .post(path: "/api/v1/notifications/device-fcm-token", data: {
      "device_token": fcmToken,
    });

    print("createOrUpdateFCMToken: ${resp}");

    return;
  }

  Future<void> getRecentPages() async {
    try {
      final resp = await apiService.get(path: "/api/v1/recent-pages");
      print("getRecentPages: $resp");
      if (resp != null && resp.isNotEmpty) {
        print("getRecentPages Success: ${resp.length}");
        final recentPages = resp ?? [];
        _recentPages = List<RecentPage>.from(
            recentPages.map((item) => RecentPage.fromJson(item)));
        print("getRecentPages: ${prettyJson(_recentPages)}");
        _saveRecentPages();
      } else {
        print("getRecentPages Failed: ${resp}");
        throw resp['message'] ?? 'Something went wrong';
      }
    } on DioException catch (e) {
      print("getRecentPages Dio Error: $e");
    } catch (e) {
      print("getRecentPages Uknown Error: $e");
    }
  }
}
