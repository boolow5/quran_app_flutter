import 'package:flutter/material.dart';
import 'package:quran_app_flutter/constants.dart';
import 'package:quran_app_flutter/utils/utils.dart';

TextSpan buildVerseNumber(
  BuildContext context, {
  required int verseNumber,
}) {
  return TextSpan(
    children: [
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '۝',
                style: TextStyle(
                  fontFamily: 'KFGQPC',
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  color: DEFAULT_PRIMARY_COLOR,
                  // color: Theme.of(context)
                  //     .colorScheme
                  //     .onSurfaceVariant
                  //     .withOpacity(0.8),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, 2),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    toArabicNumber(verseNumber),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
