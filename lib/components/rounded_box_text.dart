import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/constants.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';

class RoundedBoxText extends StatelessWidget {
  const RoundedBoxText({
    super.key,
    required this.text,
    this.height,
    this.width,
    this.border,
    this.fontSize,
  });

  final String text;
  final double? height;
  final double? width;
  final BoxBorder? border;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final calculatedHeight =
        (height ?? 28) + context.read<ThemeProvider>().fontSize(8);
    return Container(
      width: (width ?? 50),
      height: calculatedHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: DEFAULT_PRIMARY_COLOR,
        borderRadius: BorderRadius.circular(calculatedHeight / 2),
        border: border,
      ),
      child: Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            text,
            style: TextStyle(
              fontFamily: defaultFontFamily(),
              color: Colors.white,
              fontSize: context.read<ThemeProvider>().fontSize(fontSize ?? 16),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
