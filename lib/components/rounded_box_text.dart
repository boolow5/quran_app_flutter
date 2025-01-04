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
  });

  final String text;
  final double? height;
  final double? width;

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
        color: DEFAULT_PRIMARY_COLOR.withValues(
          alpha: 0.85,
        ),
        borderRadius: BorderRadius.circular(calculatedHeight / 2),
      ),
      child: Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            text,
            style: TextStyle(
              fontFamily: DEFAULT_FONT_FAMILY,
              color: Colors.white,
              fontSize: context.read<ThemeProvider>().fontSize(16),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
