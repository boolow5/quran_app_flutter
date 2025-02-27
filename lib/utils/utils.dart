import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';

String toArabicNumber(int number) {
  const Map<String, String> arabicNumbers = {
    '0': '٠',
    '1': '١',
    '2': '٢',
    '3': '٣',
    '4': '٤',
    '5': '٥',
    '6': '٦',
    '7': '٧',
    '8': '٨',
    '9': '٩',
  };

  return number
      .toString()
      .split('')
      .map((digit) => arabicNumbers[digit] ?? digit)
      .join('');
}

int showPageNumber(int pageNumber, bool isDoublePaged) {
  return isDoublePaged ? pageNumber = (pageNumber * 2).ceil() : pageNumber;
}

String latToString(double lat,
    {bool showMinutes = false, bool showSeconds = false}) {
  // Convert the latitude and longitude to degrees and minutes
  double degrees = lat;
  double minutes = (lat - degrees) * 60;
  double seconds = (minutes - minutes.toInt()) * 60;

  // Convert the degrees, minutes, and seconds to strings
  String degreesStr = degrees.toStringAsFixed(1);
  String minutesStr = minutes.toStringAsFixed(1);
  String secondsStr = seconds.toStringAsFixed(1);

  // Return the string representation of the latitude and longitude
  return '$degreesStr°${showMinutes ? " $minutesStr\'" : ''}${showSeconds ? " $secondsStr\"" : ''} N';
}

String lngToString(double lng,
    {bool showMinutes = false, bool showSeconds = false}) {
  // Convert the latitude and longitude to degrees and minutes
  double degrees = lng;
  double minutes = (lng - degrees) * 60;
  double seconds = (minutes - minutes.toInt()) * 60;

  // Convert the degrees, minutes, and seconds to strings
  String degreesStr = degrees.toStringAsFixed(1);
  String minutesStr = minutes.toStringAsFixed(1);
  String secondsStr = seconds.toStringAsFixed(1);

  // Return the string representation of the latitude and longitude
  return '$degreesStr°${showMinutes ? " $minutesStr\'" : ''}${showSeconds ? " $secondsStr\"" : ''} E';
}

void updateThemeScale(BuildContext context) {
  Future.delayed(Duration.zero, () {
    final size = MediaQuery.sizeOf(context);
    context.read<ThemeProvider>().setScreenSize(
          size.width,
          size.height,
          MediaQuery.sizeOf(context).width > 600,
          MediaQuery.orientationOf(context) == Orientation.landscape,
        );
  });
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

String toUTCRFC3339(DateTime dateTime) {
  final utcString = dateTime.toUtc().toIso8601String();
  return utcString.replaceFirst('Z', '+00:00');
}

String prettyJson(dynamic json) {
  final encoder = JsonEncoder.withIndent('  ');
  try {
    return encoder.convert(json);
  } catch (err) {
    return json.toString();
  }
}

T parseField<T>(Map<String, dynamic> map, String key, T defaultValue,
    {bool required = false}) {
  if (map.containsKey(key)) {
    if (map[key] == null || "${map[key]}" == "null") {
      return defaultValue;
    }

    if (map[key] == null) {
      if (required) {
        throw Exception('Field $key is not of type $T');
      } else {
        return defaultValue;
      }
    }

    switch (T) {
      case double:
        if (map[key] is int) {
          return (map[key] as int).toDouble() as T;
        } else if (map[key] is String) {
          return double.parse(map[key] as String) as T;
        } else if (map[key] is double) {
          return map[key] as T;
        }
        return map[key] as T;
      case int:
        if (map[key] is String) {
          return int.parse(map[key] as String) as T;
        } else if (map[key] is double) {
          return map[key].toInt() as T;
        }
        return map[key] as T;
      case String:
        try {
          return map[key] as T;
        } catch (e) {
          return map[key].toString() as T;
        }
      case bool:
        if (map[key] is String) {
          return ["true", "1", "on", "yes", "y"]
              .contains(map[key].toLowerCase()) as T;
        }

        if (["1", "0"].contains(map[key].toString().trim())) {
          return (map[key] == "1") as T;
        }
        return map[key] as T;
      case DateTime:
        if (map[key] is String) {
          return DateTime.tryParse(map[key]) as T;
        } else if (map[key] is DateTime) {
          return map[key] as T;
        }
        return defaultValue;
    }
    try {
      return map[key] == null ? defaultValue : map[key] as T;
    } catch (e) {
      print(
          "parseField<$T>({'$key': ${map[key]}})<${map[key].runtimeType}> error: $e");
      return defaultValue;
    }
  } else {
    return defaultValue;
  }
}

DateTime? parseDateTime(dynamic value, {DateTime? defaultValue}) {
  if (value == null) {
    return defaultValue;
  }
  if (value is DateTime) {
    return value;
  } else {
    try {
      return DateTime.tryParse(value);
    } catch (e) {
      return defaultValue;
    }
  }
}

String firstName(String? fullName) {
  if (fullName == null) {
    return "";
  }
  final parts = fullName.split(' ');
  if (parts.length > 1) {
    parts.removeLast();
    return parts.join(' ');
  }
  return fullName;
}
