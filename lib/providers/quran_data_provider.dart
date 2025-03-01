import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quran_app_flutter/models/model.dart';
import 'package:quran_app_flutter/models/sura.dart';
import 'package:quran_app_flutter/services/api_service.dart';
import 'package:quran_app_flutter/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    try {
      print("createOrUpdateFCMToken: $fcmToken");
      final resp = await apiService
          .post(path: "/api/v1/notifications/device-fcm-token", data: {
        "device_token": fcmToken,
      });

      print("createOrUpdateFCMToken: ${resp}");
    } catch (err) {
      print("createOrUpdateFCMToken error: $err");
    }
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
        throw resp ?? 'Something went wrong';
      }
    } on DioException catch (e) {
      print("getRecentPages Dio Error: $e");
    } catch (e) {
      print("getRecentPages Uknown Error: $e");
    }
  }
}
