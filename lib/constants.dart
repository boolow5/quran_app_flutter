// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const APP_NAME = "MeezanSync";

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
