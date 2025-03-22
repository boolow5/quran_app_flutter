import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:MeezanSync/models/model.dart';
import 'package:MeezanSync/models/sura.dart';
import 'package:MeezanSync/services/api_service.dart';
import 'package:MeezanSync/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class QuranDataProvider extends ChangeNotifier {
  late Future<SharedPreferences> _storage;
  String _appVersion = "MeezanSync v1.0.0";
  List<Sura> _tableOfContents = [];
  int _currentPage = 1;
  List<RecentPage> _recentPages = [];
  bool _recentPagesLoading = false;
  List<RecentPage> _bookmarks = [];
  String? _fcmToken;

  // queues
  List<ReadEvent> _readEventsQueue = [];

  static const int maxRecentPages = 10;
  static const String _recentPagesKey = 'recent_pages';
  late SharedPreferences _prefs;
  bool _initialized = false;
  UserStreak _userStreak = UserStreak(
    userID: 0,
    currentStreak: 0,
    longestStreak: 0,
  );
  bool _userStreakLoading = false;

  // Getters
  String get appVersion => _appVersion;
  List<Sura> get tableOfContents => _tableOfContents;
  int get currentPage => _currentPage;
  List<RecentPage> get recentPages => List.unmodifiable(_recentPages);
  List<RecentPage> get bookmarks => List.unmodifiable(
      _bookmarks.reversed.where((e) => e.pageNumber > 0).take(100).toList());
  List<RecentPage> get currentRecentPages => _recentPages.isNotEmpty
      ? _recentPages.reversed.where((e) => e.pageNumber > 0).take(3).toList()
      : [];

  int get userStreakDays => _userStreak.currentStreak;
  bool get userStreakWasActiveToday => isToday(_userStreak.lastActiveDate);
  String? get fcmToken => _fcmToken;

  bool get recentPagesLoading => _recentPagesLoading;
  bool get userStreakLoading => _userStreakLoading;

  set fcmToken(String? token) {
    _fcmToken = token;
    notifyListeners();
  }

  QuranDataProvider(Future<SharedPreferences> storage) {
    _storage = storage;
    storage.then((prefs) {
      _prefs = prefs;
    });
  }

  // Initialize shared preferences
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await _storage;
    _loadRecentPages();
    _loadBookmarks();

    _loadReadEvents();
    _initialized = true;

    _loopReadEvents();
    notifyListeners();
  }

  // Loop read events every minute
  void _loopReadEvents() {
    Future.delayed(const Duration(minutes: 1), () {
      sendReadEventsQueue();
      _loopReadEvents();
    });
  }

  // Load read events from SharedPreferences
  void _loadReadEvents() {
    final String? readEventsJson = _prefs.getString('read_events');
    if (readEventsJson != null) {
      final List<dynamic> decoded = json.decode(readEventsJson);
      _readEventsQueue.clear();
      _readEventsQueue.addAll(
        decoded
            .map((item) => ReadEvent.fromJson(item as Map<String, dynamic>))
            .where((e) => e.pageNumber > 0 && !e.sent)
            .toList(),
      );
      notifyListeners();
    }
  }

  // Load recent pages from SharedPreferences
  void _loadRecentPages() {
    final String? recentPagesJson = _prefs.getString(_recentPagesKey);
    if (recentPagesJson != null) {
      final List<dynamic> decoded = json.decode(recentPagesJson);
      _recentPages.clear();
      _recentPages.addAll(
        decoded
            .map(
              (item) => RecentPage.fromJson(item as Map<String, dynamic>),
            )
            .where((e) => e.pageNumber > 0)
            .toList(),
      );
      notifyListeners();
    }
  }

  void _loadBookmarks() {
    // final String? bookmarksJson = _prefs.getString('bookmarks');
    // if (bookmarksJson != null) {
    //   final List<dynamic> decoded = json.decode(bookmarksJson);
    //   if (_bookmarks.isNotEmpty && decoded.isNotEmpty) {
    //     _bookmarks.clear();
    //   }
    //   _bookmarks.addAll(
    //     decoded
    //         .map((item) => RecentPage.fromJson(item as Map<String, dynamic>)),
    //   );
    //   notifyListeners();
    // }
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
    } catch (err) {
      print("Error saving recent pages: $err");
      if (!err.toString().contains('no token available')) {
        FirebaseCrashlyticsRecordError(
          err,
          StackTrace.current,
          reason: "Error saving recent pages: $err",
          fatal: false,
        );
      }
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
      if (!err.toString().contains('no token available')) {
        FirebaseCrashlyticsRecordError(
          err,
          StackTrace.current,
          reason: "Error adding bookmark: $err",
          fatal: true,
        );
      }
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
      } catch (err) {
        print("Error sending read event: $err");
        if (!err.toString().contains('no token available')) {
          FirebaseCrashlyticsRecordError(
            err,
            StackTrace.current,
            reason: "Error sending read event: $err",
            fatal: false,
          );
        }
      }
    }
  }

  Future<void> getBookmarks() async {
    try {
      final resp = await apiService.get(path: "/api/v1/bookmarks");
      // print("getBookmarks: $resp");
      if (resp != null && resp.isNotEmpty) {
        print("getBookmarks Success: ${resp.length}");
        List<dynamic> bookmarks = (resp ?? []);
        if (bookmarks.isNotEmpty) {
          bookmarks = bookmarks
              .where((item) => item["pageNumber"] > 0) 
              .toList();
        }

        print("getBookmarks: $bookmarks");
        _bookmarks = List<RecentPage>.from(
            bookmarks.map((item) =>  RecentPage.fromJson(item)));
        if (_bookmarks.isNotEmpty) {
          _bookmarks.sort((a, b) => a.startDate.compareTo(b.startDate));
        }
        print("getBookmarks: ${prettyJson(_bookmarks)}");
      } else {
        print("getBookmarks Failed: ${resp?.data}");
        throw resp?.data['message'] ?? 'Something went wrong';
      }
    } on DioException catch (err) {
      print("getBookmarks Dio Error: $err");
      if (!err.toString().contains('no token available')) {
        FirebaseCrashlyticsRecordError(
          err,
          StackTrace.current,
          reason: "getBookmarks API Error: $err",
          fatal: true,
        );
      }
    } catch (e) {
      print("getBookmarks Uknown Error: $e");
    }
  }

  Future<bool> addBookmark(String? userID, int pageNumber, String suraName,
      {DateTime? startDate, DateTime? endDate}) async {
    bool saved = false;
    try {
      final bookmark = await apiService.post(
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
      print("addBookmark: $bookmark");
      if (bookmark != null) {
        print("addBookmark Success: ${bookmark}");
        _bookmarks.add(RecentPage.fromJson(bookmark));
      } else {
        print("addBookmark Failed: ${bookmark}");
        throw 'Something went wrong';
      }
    } on DioException catch (err) {
      print("addBookmark Dio Error: $err");
      if (!err.toString().contains('no token available')) {
        FirebaseCrashlyticsRecordError(
          err,
          StackTrace.current,
          reason: "addBookmark API Error: $err",
          fatal: true,
        );
      }
    } catch (err) {
      print("addBookmark Uknown Error: $err");
      if (!err.toString().contains('no token available')) {
        FirebaseCrashlyticsRecordError(
          err,
          StackTrace.current,
          reason: "addBookmark Uknown Error: $err",
          fatal: true,
        );
      }
    } finally {
      saved = _addBookmark(pageNumber, suraName);
    }
    return saved;
  }

  Future<bool> sendReadEvent(int pageNumber, String suraName, int seconds) async {
    _readEventsQueue.add(ReadEvent(pageNumber: pageNumber, suraName: suraName, seconds: seconds, sent: false));

    try {
      // save read event
      final ref = await _storage;
      await ref.setString("read_events", jsonEncode(_readEventsQueue));
    } catch (err) {
      print("Error saving read events: $err");
      return false;
    }
    return true;
  }

  Future<void> sendReadEventsQueue() async {
    for (int i = 0; i < _readEventsQueue.length; i++) {
      final event = _readEventsQueue[i];
      bool sent = false;
      try {
        final resp = await apiService.post(
          path: "/api/v1/streaks/read-event",
          data: {
          "page_number": event.pageNumber,
          "surah_name": event.suraName,
          "seconds_open": event.seconds,
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
        
        if (sent) {
          _readEventsQueue[i] = _readEventsQueue[i].copyWith(sent: sent);
        }
      } on DioException catch (err) {
        print("sendReadEvent Dio Error: $err");
        if (!err.toString().contains('no token available')) {
          FirebaseCrashlyticsRecordError(
            err,
            StackTrace.current,
            reason: "sendReadEvent API Error: $err",
            fatal: false,
          );
        }
      } catch (err) {
        print("sendReadEvent Uknown Error: $err");
        if (!err.toString().contains('no token available')) {
          FirebaseCrashlyticsRecordError(
            err,
            StackTrace.current,
            reason: "sendReadEvent Uknown Error: $err",
            fatal: false,
          );
        }
      }
    } 

    // remove all sent events
    _readEventsQueue.removeWhere((element) => element.sent);

    notifyListeners();
  }

  Future<List<int>> getUserStreak() async {
    List<int> changes = [0, 0];
    if (_userStreak != null) {
      changes[0] = _userStreak!.currentStreak;
    }

    _userStreakLoading = true;
    notifyListeners();

    try {
      final resp = await apiService.get(path: "/api/v1/streaks");
      print("getUserStreak: $resp");
      if (resp != null && resp["user_id"] > 0) {
        print("getUserStreak Success: ${resp['current_streak']} ${resp['last_active_date']}");
        _userStreak = UserStreak.fromJson(resp);
        if (_userStreak != null) {
          changes[1] = _userStreak!.currentStreak;
        }
        notifyListeners();
      } else {
        print("getUserStreak Failed: ${resp?.data}");
        throw resp?.data['message'] ?? 'Something went wrong';
      }

    } on DioException catch (err) {
      print("getUserStreak Dio Error: $err");
      if (!err.toString().contains('no token available')) {
        FirebaseCrashlyticsRecordError(
          err,
          StackTrace.current,
          reason: "getUserStreak API Error: $err",
          fatal: true,
        );
      }
    } catch (err) {
      print("getUserStreak Uknown Error: $err");
      if (!err.toString().contains('no token available')) {
        FirebaseCrashlyticsRecordError(
          err,
          StackTrace.current,
          reason: "getUserStreak Uknown Error: $err",
          fatal: true,
        );
      }
    } finally {
      _userStreakLoading = false;
      notifyListeners();
    }

    return changes;
  }

  Future<void> createOrUpdateFCMToken(String fcmToken) async {
    try {
      final form = {
        "device_token": fcmToken,
      };
      print("createOrUpdateFCMToken: $form");
      final resp = await apiService.post(
        path: "/api/v1/notifications/device-fcm-token",
        data: form,
      );

      print("createOrUpdateFCMToken: ${resp}");
    } catch (err) {
      print("createOrUpdateFCMToken error: $err");
      if (!err.toString().contains('no token available')) {
        FirebaseCrashlyticsRecordError(
          err,
          StackTrace.current,
          reason: "createOrUpdateFCMToken error: $err",
          fatal: true,
        );
      }
    }
  }

  Future<void> getRecentPages() async {
    _recentPagesLoading = true;
    notifyListeners();
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
    } on DioException catch (err) {
      print("getRecentPages Dio Error: $err");
      if (!err.toString().contains('no token available')) {
        FirebaseCrashlyticsRecordError(
          err,
          StackTrace.current,
          reason: "getRecentPages API Error: $err",
          fatal: false,
        );
      }
    } catch (err) {
      print("getRecentPages Uknown Error: $err");
      if (!err.toString().contains('no token available')) {
        FirebaseCrashlyticsRecordError(
          err,
          StackTrace.current,
          reason: "getRecentPages Uknown Error: $err",
          fatal: false,
        );
      }
    } finally {
      _recentPagesLoading = false;
      notifyListeners();
    }
  }

  Future<void> getVersionDetails() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();

      String appName = packageInfo.appName;
      String packageName = packageInfo.packageName;
      String version = packageInfo.version;
      String buildNumber = packageInfo.buildNumber.toString();
      if (buildNumber.isEmpty) {
        buildNumber = "0";
      } else if (buildNumber.trim().length > 2) {
        // use the last two digits
        buildNumber = buildNumber.substring(buildNumber.length - 2);
      }

      print("_getVersionDetails: appName: $appName, packageName: $packageName");

      _appVersion = "$appName v$version ($buildNumber)";
    } catch (err) {
      print("_getVersionDetails: $err");
      if (!err.toString().contains('no token available')) {
        FirebaseCrashlyticsRecordError(
          err,
          StackTrace.current,
          reason: "_getVersionDetails: $err",
          fatal: true,
        );
      }
    }
  }
}
