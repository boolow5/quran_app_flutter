import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/components/rounded_box_text.dart';
import 'package:quran_app_flutter/components/verse_number.dart';
import 'package:quran_app_flutter/constants.dart';
import 'package:quran_app_flutter/providers/quran_data_provider.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';
import 'package:quran_app_flutter/screens/quran_page.dart';
import 'package:quran_app_flutter/utils/utils.dart';

class QuranSinglePage extends StatefulWidget {
  final int pageNumber;
  final bool updatePageNumber;
  final bool isTablet;
  final bool isLandscape;

  const QuranSinglePage({
    super.key,
    required this.pageNumber,
    required this.updatePageNumber,
    required this.isTablet,
    required this.isLandscape,
  }) : assert(pageNumber > 0);

  @override
  State<QuranSinglePage> createState() => _QuranSinglePageState();
}

class _QuranSinglePageState extends State<QuranSinglePage> {
  late final QuranDataProvider _quranDataProvider;
  String _suraName = '';
  int _suraNumber = 0;
  List<Verse> _verses = [];
  Map<int, Sura> _suras = {};
  bool _isLoading = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _quranDataProvider = context.read<QuranDataProvider>();
    _currentPage = widget.pageNumber;

    _loadVerses(_currentPage);

    // Initialize current page in QuranDataProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_suraName.isNotEmpty && widget.updatePageNumber) {
        _quranDataProvider.setCurrentPage(_currentPage, _suraName);
      }
    });
  }

  @override
  void dispose() {
    if (widget.updatePageNumber) {
      _quranDataProvider.setEndTimeForMostRecentPage();
    }
    super.dispose();
  }

  Future<void> _loadVerses(int pageNumber) async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/quran/page-$pageNumber.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      final List<Verse> verses = [];
      final Map<String, dynamic> surasJson =
          jsonMap['suras'] as Map<String, dynamic>;

      // Iterate through each sura in the page
      for (var entry in surasJson.entries) {
        final suraNumber = int.parse(entry.key);
        final suraData = entry.value as Map<String, dynamic>;

        // Create Sura object
        _suras[suraNumber] = Sura.fromJson(suraNumber, suraData);
        _suraName = _suras[suraNumber]!.name ?? '<???>';
        _suraNumber = suraNumber;

        final List<dynamic> ayas = suraData['ayas'] as List<dynamic>;
        // Add verses from this sura
        verses.addAll(
          ayas.map((aya) => Verse.fromJson(suraNumber, aya)),
        );
      }

      setState(() {
        _verses = verses;
        _isLoading = false;
      });

      // Update QuranDataProvider with current page after loading verses
      if (_suraName.isNotEmpty && widget.updatePageNumber) {
        _quranDataProvider.setCurrentPage(pageNumber, _suraName);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading verses: $e')),
        );
      }
    }
  }

  bool _isSpecialPage() {
    return _currentPage <= 2;
  }

  List<TextSpan> _buildVerseSpans(BuildContext context, int pageNumber) {
    List<TextSpan> spans = [];
    int? currentSuraNumber;

    for (int i = 0; i < _verses.length; i++) {
      // Add sura header if this is the start of a new sura
      if (currentSuraNumber != _verses[i].suraNumber) {
        currentSuraNumber = _verses[i].suraNumber;
        final sura = _suras[currentSuraNumber]!;

        // Add some spacing before the header (except for first sura)
        if (i > 0) {
          spans.add(const TextSpan(text: '\n\n'));
        }

        // Add sura header
        if (_verses[i].number == 1 && sura.number != 9) {
          spans.add(TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      width: _isSpecialPage() ? constraints.maxWidth : null,
                      height:
                          _isSpecialPage() ? constraints.maxWidth / 2 : null,
                      padding: _isSpecialPage()
                          ? EdgeInsets.only(
                              top: constraints.maxWidth / 4,
                              right: 8.0,
                              left: 8.0,
                              bottom: 4.0,
                            )
                          : const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                      margin: _isSpecialPage()
                          ? null
                          : const EdgeInsets.only(
                              bottom: 12,
                            ),
                      decoration: BoxDecoration(
                        color: DEFAULT_PRIMARY_COLOR,
                        borderRadius: _isSpecialPage()
                            ? BorderRadius.only(
                                topLeft: Radius.circular(constraints.maxWidth),
                                topRight: Radius.circular(constraints.maxWidth),
                              )
                            : BorderRadius.all(Radius.circular(20.0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_verses[i].number == 1 && sura.number != 9)
                            Text(
                              'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                              style: TextStyle(
                                fontFamily:
                                    'KFGQPC', // DEFAULT_FONT_FAMILY, // 'KFGQPC',
                                fontSize:
                                    context.read<ThemeProvider>().fontSize(20),
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ));
        }
      }

      if (!(pageNumber == 1 && _verses[i].number == 1)) {
        // Add the verse text
        spans.add(
          TextSpan(
            text: _verses[i].text,
            style: TextStyle(
              fontSize:
                  context.read<ThemeProvider>().fontSize(DEFAULT_FONT_SIZE),
              // height: 1.2,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
      // Add verse number with end-of-verse symbol
      spans.add(TextSpan(
        text: '',
      ));
      if (!(pageNumber == 1 && _verses[i].number == 1)) {
        spans.add(
          buildVerseNumber(
            context,
            verseNumber: _verses[i].number,
          ),
        );
      }
      // Add verse number with end-of-verse symbol
      spans.add(TextSpan(
        text: '',
      ));

      // Add space or ornamental divider after verse
      if (i < _verses.length - 1) {
        spans.add(const TextSpan(text: ''));
      }
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    final fontCorrection = context.read<ThemeProvider>().fontSize(16) * 0.045;

    final fontPadding = context.read<ThemeProvider>().fontSize(16);
    double boxHeight = ((screenHeight > 681
                ? screenHeight * (_currentPage == 2 ? 0.84 : 0.78)
                : 545.0) *
            fontCorrection) -
        40;
    double boxWidth = (screenWidth > 468
            ? screenWidth * (_currentPage == 2 ? 0.8 : 0.8)
            : 375.0) *
        fontCorrection;
    double fontMatchSize = context.read<ThemeProvider>().fontSize(16.0);
    double boxPadding =
        boxHeight * context.read<ThemeProvider>().fontSize(0.0015);
    double boxMargin = fontMatchSize > 14 ? fontMatchSize - 14.0 : 0;
    double horizontalMargin = (boxWidth * 0.15) - (fontPadding);

    if (boxWidth < 300) {
      boxWidth = 300 + (fontCorrection * 50);
    }
    if (boxHeight < 380) {
      boxHeight = 380 + (fontCorrection * (_currentPage == 2 ? 80 : 50));
    }
    if (horizontalMargin < 0) {
      horizontalMargin = 0;
    }
    if (fontMatchSize < 12.8) {
      fontMatchSize = 12.8;
    }

    // print("------------------------- box size -------------------------");
    // print("boxWidth: $boxWidth");
    // print("boxHeight: $boxHeight");
    // print("fontMatchSize: $fontMatchSize");
    // print("horizontalMargin: $horizontalMargin");
    // print("fontCorrection: $fontCorrection");
    // print("boxPadding: $boxPadding");
    // print("boxMargin: $boxMargin");
    // print(">------------------------ box size ------------------------<");

    return _buildPageContent(
        boxHeight, boxWidth, context, boxPadding, boxMargin);
  }

  Widget _buildPageContent(double boxHeight, double boxWidth,
      BuildContext context, double boxPadding, double boxMargin) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWith = MediaQuery.sizeOf(context).width /
        (widget.isTablet && widget.isLandscape ? 2.05 : 1);

    double specialBoxSize = max(
        screenWith * (context.read<ThemeProvider>().scaleFactor / 2.25), 375.0);
    double pageHeight = _isSpecialPage()
        ? specialBoxSize * 1.45
        : screenHeight - (screenHeight * 0.15);
    double pageWidth =
        _isSpecialPage() ? specialBoxSize : screenWith - (screenWith * 0.03);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          !_isSpecialPage()
              ? SizedBox(
                  width: specialBoxSize,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      RoundedBoxText(
                        text: _suraName,
                        width: 100,
                      ),
                      RoundedBoxText(
                        text: toArabicNumber(_currentPage),
                        width: 40,
                      ),
                      RoundedBoxText(
                        text: "السورة ${toArabicNumber(_suraNumber)}",
                        width: 100,
                      ),
                    ],
                  ),
                )
              : Center(
                  child: RoundedBoxText(
                    text: toArabicNumber(_currentPage),
                    width: 40,
                  ),
                ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              // height: _isSpecialPage() ? boxHeight : null,
              // width: _isSpecialPage() ? boxWidth : null,
              height: pageHeight,
              width: pageWidth,
              // constraints: BoxConstraints(
              //   maxWidth: _isSpecialPage() ? 350 : pageWidth,
              //   maxHeight: _isSpecialPage() ? 530 : 800,
              // ),
              margin: _isSpecialPage()
                  ? EdgeInsets.symmetric(vertical: 32, horizontal: 0)
                  : EdgeInsets.symmetric(vertical: 0, horizontal: 4),
              padding: EdgeInsets.symmetric(
                horizontal: context.read<ThemeProvider>().fontSize(20.0),
                vertical: _isSpecialPage() ? 20.0 : 8,
              ),
              decoration: BoxDecoration(
                color: DEFAULT_PAGE_BG_COLOR,
                // color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: _isSpecialPage()
                    ? BorderRadius.circular(specialBoxSize / 2)
                    : null,
                border: _isSpecialPage()
                    ? Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 16.0,
                      )
                    : null,
              ),
              child: SingleChildScrollView(
                child: Container(
                  decoration: _isSpecialPage()
                      ? BoxDecoration(
                          border: Border.all(
                            color: Colors.transparent, // DEFAULT_PRIMARY_COLOR,
                            width: 2.0,
                          ),
                          borderRadius:
                              BorderRadius.circular(specialBoxSize / 4),
                        )
                      : null,
                  padding: _isSpecialPage()
                      ? EdgeInsets.only(
                          top: boxPadding,
                          right: boxPadding,
                          left: boxPadding,
                        )
                      : EdgeInsets.zero,
                  margin: _isSpecialPage()
                      ? EdgeInsets.only(
                          top: boxMargin,
                          right: boxMargin,
                          left: boxMargin,
                        )
                      : EdgeInsets.zero,
                  child: RichText(
                    textAlign:
                        _isSpecialPage() ? TextAlign.center : TextAlign.justify,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: context
                            .read<ThemeProvider>()
                            .fontSize(_isSpecialPage() ? 24.0 : 24.0),
                        color: Theme.of(context).colorScheme.onBackground,
                        height: _isSpecialPage() ? 1.7 : 1.5,
                        fontFamily: DEFAULT_FONT_FAMILY,
                      ),
                      children: _buildVerseSpans(context, _currentPage),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
