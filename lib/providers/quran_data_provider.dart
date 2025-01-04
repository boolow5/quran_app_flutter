import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:quran_app_flutter/models/sura.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecentPage {
  final int pageNumber;
  final String suraName;
  final DateTime startTime;
  DateTime? endTime;

  RecentPage({
    required this.pageNumber,
    required this.suraName,
    required this.startTime,
    this.endTime,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() => {
        'pageNumber': pageNumber,
        'suraName': suraName,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
      };

  // Create from JSON
  factory RecentPage.fromJson(Map<String, dynamic> json) => RecentPage(
        pageNumber: json['pageNumber'] as int,
        suraName: json['suraName'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : null,
      );

  @override
  String toString() {
    return 'RecentPage(pageNumber: $pageNumber, suraName: $suraName, startTime: $startTime, endTime: $endTime)';
  }
}

class QuranDataProvider extends ChangeNotifier {
  late Future<SharedPreferences> _storage;
  List<Sura> _tableOfContents = [];
  int _currentPage = 1;
  final List<RecentPage> _recentPages = [];
  final List<RecentPage> _bookmarks = [];
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

  // Initialize shared preferences
  Future<void> init(Future<SharedPreferences> storage) async {
    if (_initialized) return;
    _storage = storage;
    _prefs = await _storage;
    _loadRecentPages();
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
    final String encoded = json.encode(_recentPages
        .where((page) =>
            page.endTime != null &&
            page.endTime!.difference(page.startTime).inSeconds >= 10)
        .map((page) => page.toJson())
        .toList());
    await _prefs.setString(_recentPagesKey, encoded);
  }

  Future<void> _saveBookmarks() async {
    print("Saving bookmarks: $_bookmarks");
    final String encoded = json.encode(_bookmarks
        .where((page) =>
            page.endTime != null &&
            page.endTime!.difference(page.startTime).inSeconds >= 10)
        .map((page) => page.toJson())
        .toList());
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
        _recentPages.last.endTime = DateTime.now();
      }

      // Add new page or update existing in the recent list
      final int index = _recentPages.indexWhere((p) => p.pageNumber == page);
      if (index >= 0) {
        _recentPages[index] = RecentPage(
          pageNumber: _recentPages[index].pageNumber,
          suraName: _recentPages[index].suraName,
          startTime: DateTime.now(),
          endTime: null,
        );
      } else {
        _recentPages.add(RecentPage(
          pageNumber: page,
          suraName: suraName,
          startTime: DateTime.now(),
        ));
      }

      // Keep only the last maxRecentPages entries
      if (_recentPages.length > maxRecentPages) {
        _recentPages.removeAt(0);
      }

      _currentPage = page;
      _saveRecentPages(); // Persist changes
      notifyListeners();
    }
  }

  bool addBookmark(int page, String suraName) {
    try {
      final bookmark = RecentPage(
        pageNumber: page,
        suraName: suraName,
        startTime: DateTime.now(),
      );
      final int index =
          _bookmarks.indexWhere((bookmark) => bookmark.pageNumber == page);
      if (index >= 0) {
        print('**************** Bookmark already exists ****************');
        _bookmarks[index] = bookmark;
      } else {
        print('**************** Adding bookmark ****************');
        _bookmarks.add(bookmark);
      }

      _saveBookmarks(); // Persist changes
      return true;
    } catch (err) {
      print('**************** Error adding bookmark: $err ****************');
      return false;
    } finally {
      notifyListeners();
    }
  }

  void setEndTimeForMostRecentPage() {
    if (_recentPages.isNotEmpty && _recentPages.last.endTime == null) {
      print(
          '**************** Setting end time for most recent page ****************');
      _recentPages.last.endTime = DateTime.now();
      _saveRecentPages(); // Persist changes
      notifyListeners();
    } else {
      print(
          '**************** End time for most recent page already set ****************');
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
    if (page.endTime == null) return 'Reading...';

    final duration = page.endTime!.difference(page.startTime);
    return formatDuration(duration);
  }

  // Get time elapsed since reading
  String timeSinceReading(RecentPage page, {bool start = false}) {
    final DateTime referenceTime =
        (start ? page.startTime : page.endTime) ?? DateTime.now();
    final Duration elapsed = DateTime.now().difference(referenceTime);

    if (elapsed.inMinutes < 1) {
      return 'Just now';
    } else if (elapsed.inHours < 1) {
      return '${elapsed.inMinutes}m ago';
    } else if (elapsed.inDays < 1) {
      return '${elapsed.inHours}h ago';
    } else if (elapsed.inDays < 30) {
      return '${elapsed.inDays}d ago';
    } else {
      return '${(elapsed.inDays / 30).floor()}mo ago';
    }
  }
}
