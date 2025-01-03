import 'package:flutter/material.dart';
import 'package:quran_app_flutter/constants.dart';

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
    return Container(
      width: width ?? 50,
      height: height ?? 28,
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: DEFAULT_PRIMARY_COLOR.withValues(
          alpha: 0.85,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            text,
            style: TextStyle(
              fontFamily: DEFAULT_FONT_FAMILY,
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
