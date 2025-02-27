import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quran_app_flutter/constants.dart';
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
    final startDate = parseDateTime(json['startDate']) ?? DateTime.now();
    print("startDate: ${json['startDate']} -> $startDate");
    final endDate = parseDateTime(json['endDate']);
    print("endDate: ${json['endDate']} -> $endDate");

    return RecentPage(
      pageNumber: parseField<int?>(json, 'pageNumber', null) ?? 0,
      suraName: parseField<String?>(json, 'suraName', null) ?? "",
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  String toString() {
    return 'RecentPage(pageNumber: $pageNumber, suraName: $suraName, startDate: $startDate, endDate: $endDate)';
  }
}

class QuranDataProvider extends ChangeNotifier {
  late Future<SharedPreferences> _storage;
  List<Sura> _tableOfContents = [];
  int _currentPage = 1;
  List<RecentPage> _recentPages = [];
  List<RecentPage> _bookmarks = [];
  int _daysStreak = 0;
  int _maxStreak = 0;
  static const int maxRecentPages = 10;
  static const String _recentPagesKey = 'recent_pages';
  late SharedPreferences _prefs;
  bool _initialized = false;

  // Getters
  List<Sura> get tableOfContents => _tableOfContents;
  int get currentPage => _currentPage;
  List<RecentPage> get recentPages => List.unmodifiable(_recentPages);
  List<RecentPage> get bookmarks =>
      List.unmodifiable(_bookmarks.reversed.take(100).toList());
  List<RecentPage> get currentRecentPages =>
      _recentPages.isNotEmpty ? _recentPages.reversed.take(3).toList() : [];
  int get daysStreak => _daysStreak;
  int get maxStreak => _maxStreak;

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
        decoded
            .map((item) => RecentPage.fromJson(item as Map<String, dynamic>)),
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

  void setRecentPage(
    int pageNumber,
    String suraName, {
    bool isDoublePage = false,
    int? secondsOpen = 0,
  }) {
    if (secondsOpen != null && secondsOpen > 0) {
      final page = RecentPage(
        pageNumber: pageNumber,
        suraName: suraName,
        startDate: DateTime.now().subtract(Duration(seconds: secondsOpen)),
        endDate: DateTime.now(),
      );
      _recentPages.add(page);
      _saveRecentPages();
      notifyListeners();
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
        path: "/api/v1/read-read-event",
        data: {
          "page_number": pageNumber,
          "surah_name": suraName,
          "seconds_open": seconds,
        },
      );
      if (resp != null && resp?.statusCode == 200) {
        print("sendReadEvent Success: ${resp.data}");
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
}
