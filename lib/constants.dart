// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final navigatorKey = GlobalKey<NavigatorState>();
const String notificationsKey = "notifications";
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey buttonKey = GlobalKey();
final GlobalKey tableOfContentsKey = GlobalKey();
final GlobalKey bookmarksKey = GlobalKey();
final GlobalKey bookmarkButtonKey = GlobalKey();
final GlobalKey streaksKey = GlobalKey();
final GlobalKey recentPagesKey = GlobalKey();
final GlobalKey qiblaCompassKey = GlobalKey();
final GlobalKey settingsKey = GlobalKey();
final GlobalKey backButtonKey = GlobalKey();

const isDebug = false;
const APP_NAME = "MeezanSync";
const BASE_URL =
    isDebug ? "http://192.168.100.50:1140" : "https://quran-api.mahad.dev";

const MAX_FONT_SIZE = 24.5;
const DEFAULT_FONT_SIZE = 19.0;
const DEFAULT_PRIMARY_COLOR = Color(0xFF008080);
// #f7fce3
const DEFAULT_BG_COLOR = Color.fromARGB(0xFF, 0xe6, 0xeb, 0xd2);
const DEFAULT_PAGE_BG_COLOR = Color.fromARGB(0xFF, 0xf7, 0xfc, 0xe3);

String defaultFontFamily() {
  if (kIsWeb) {
    return "ScheherazadeQuran";
  } else {
    return Platform.isIOS ? "hafs" : "ScheherazadeQuran";
  }
}
