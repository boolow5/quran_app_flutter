import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:MeezanSync/components/rounded_box_text.dart';
import 'package:MeezanSync/components/verse_number.dart';
import 'package:MeezanSync/constants.dart';
import 'package:MeezanSync/models/model.dart';
import 'package:MeezanSync/models/sura.dart';
import 'package:MeezanSync/providers/quran_data_provider.dart';
import 'package:MeezanSync/providers/theme_provider.dart';
import 'package:MeezanSync/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

class QuranSinglePage extends StatefulWidget {
  final int pageNumber;
  final bool updatePageNumber;
  final bool isTablet;
  final bool isLandscape;
  final Function(int pageNumber, String suraName) onSuraChange;
  final Function(int pageNumber, String suraName, int? tick) onPageChanged;

  const QuranSinglePage({
    super.key,
    required this.pageNumber,
    required this.updatePageNumber,
    required this.isTablet,
    required this.isLandscape,
    required this.onSuraChange,
    required this.onPageChanged,
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

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _quranDataProvider = context.read<QuranDataProvider>();
    _currentPage = widget.pageNumber;
    print(" &&&&&&&&&&&&&&&&&& Mounted &&&&&&&&&&&&&&&&&&");
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
    });

    _loadVerses(_currentPage);

    // Initialize current page in QuranDataProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_suraName.isNotEmpty && widget.updatePageNumber) {
        _quranDataProvider.setCurrentPage(_currentPage, _suraName);
      }
    });
  }

  @override
  void didUpdateWidget(covariant QuranSinglePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPage != widget.pageNumber) {
      _currentPage = widget.pageNumber;
      // _loadVerses(_currentPage);
      if (!mounted) {
        print(" &&&&&&&&&&&&&&&&&& Unmounted &&&&&&&&&&&&&&&&&&");
        _timer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadVerses(int pageNumber) async {
    print("Loading verses for page $pageNumber");
    // if (widget.isTablet && widget.isLandscape) {
    //   pageNumber = (pageNumber * 2).ceil();
    // }
    print("Is tablet: ${widget.isTablet} Is landscape: ${widget.isLandscape}");
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
        widget.onSuraChange(pageNumber, _suraName);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading verses: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
                    // bismillah
                    return Container(
                      width: _isSpecialPage() ? constraints.maxWidth : null,
                      height:
                          _isSpecialPage() ? constraints.maxWidth / 2 : null,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: _isSpecialPage()
                            ? BorderRadius.only(
                                topLeft: Radius.circular(constraints.maxWidth),
                                topRight: Radius.circular(constraints.maxWidth),
                              )
                            : BorderRadius.all(Radius.circular(20.0)),
                        border: Border.all(
                          color: DEFAULT_PRIMARY_COLOR,
                          width: 3.0,
                        ),
                      ),
                      margin: _isSpecialPage()
                          ? null
                          : const EdgeInsets.only(
                              bottom: 12,
                            ),
                      padding: EdgeInsets.all(2.0),
                      child: Container(
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
                        decoration: BoxDecoration(
                          color: DEFAULT_PRIMARY_COLOR,
                          borderRadius: _isSpecialPage()
                              ? BorderRadius.only(
                                  topLeft:
                                      Radius.circular(constraints.maxWidth),
                                  topRight:
                                      Radius.circular(constraints.maxWidth),
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
                                  fontFamily: defaultFontFamily(),
                                  // 'KFGQPC', // DEFAULT_FONT_FAMILY, // 'KFGQPC',
                                  fontSize: context
                                      .read<ThemeProvider>()
                                      .fontSize(16),
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
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

    return VisibilityDetector(
      key: Key('quran_page_$_currentPage'),
      onVisibilityChanged: (visibilityInfo) {
        final isVisible = visibilityInfo.visibleFraction > 0.0;
        print(
            "page: $_currentPage visible: [$isVisible] ${visibilityInfo.visibleFraction}");
        if (!isVisible) {
          widget.onPageChanged(_currentPage, _suraName, _timer?.tick);

          _timer?.cancel();
        }
      },
      child: _buildPageContent(
          boxHeight, boxWidth, context, boxPadding, boxMargin),
    );
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
        : screenHeight - (screenHeight * 0.157);
    double pageWidth =
        _isSpecialPage() ? specialBoxSize : screenWith - (screenWith * 0.03);

    if (!_isSpecialPage() && MediaQuery.sizeOf(context).width > 600) {
      pageWidth = min(screenWith, 490.0);
      // print("screenWith: $screenWith pageWidth -> ${pageWidth}");
      pageHeight = pageWidth * 1.64;
    }

    // prevent overflow in small screens
    if (_isSpecialPage() && pageHeight > screenHeight * 0.74) {
      pageHeight = screenHeight * 0.74 +
          context.read<ThemeProvider>().scaleFactor / 2.25;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          if (!_isSpecialPage()) ...[
            SizedBox(
              width: pageWidth * 0.9,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RoundedBoxText(
                    text: "سورة $_suraName ",
                    width: 110,
                    height: 22,
                    fontSize: 13,
                  ),
                  RoundedBoxText(
                    text: toArabicNumber(_currentPage),
                    width: 50,
                    height: 22,
                  ),
                  RoundedBoxText(
                    text: "رقم السورة ${toArabicNumber(_suraNumber)}",
                    width: 110,
                    height: 22,
                    fontSize: 13,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            SizedBox(height: pageHeight * 0.1),
          ],
          Center(
            child: Stack(
              children: [
                Container(
                  margin: EdgeInsets.all(0),
                  padding: EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: !_isSpecialPage()
                        ? Border.all(
                            color: DEFAULT_PRIMARY_COLOR,
                            width: 4.0,
                          )
                        : null,
                  ),
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
                        : EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                    padding: EdgeInsets.symmetric(
                      horizontal: context
                          .read<ThemeProvider>()
                          .fontSize(_isSpecialPage() ? 12.0 : 8.0),
                      vertical: _isSpecialPage() ? 20.0 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black : DEFAULT_PAGE_BG_COLOR,
                      // color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: _isSpecialPage()
                          ? BorderRadius.circular(specialBoxSize / 2)
                          : null,
                      border: _isSpecialPage()
                          ? Border.all(
                              color: DEFAULT_PRIMARY_COLOR,
                              width: 16.0,
                            )
                          : Border.all(
                              color: DEFAULT_PRIMARY_COLOR,
                              width: 2.0,
                            ),
                    ),
                    child: SingleChildScrollView(
                      child: Container(
                        decoration: _isSpecialPage()
                            ? BoxDecoration(
                                border: Border.all(
                                  color: Colors
                                      .transparent, // DEFAULT_PRIMARY_COLOR,
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
                          textAlign: _isSpecialPage()
                              ? TextAlign.center
                              : TextAlign.justify,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: context
                                  .read<ThemeProvider>()
                                  .fontSize(_isSpecialPage() ? 21.0 : 22.0),
                              color: Theme.of(context).colorScheme.onBackground,
                              height: _isSpecialPage() ? 1.7 : 1.5,
                              fontFamily: defaultFontFamily(),
                            ),
                            children: _buildVerseSpans(context, _currentPage),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isSpecialPage()) ...[
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: RoundedBoxText(
                        text: "سورة $_suraName ",
                        width: 120,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: RoundedBoxText(
                        text: toArabicNumber(_currentPage),
                        width: 40,
                        height: 30,
                        // border: Border.all(
                        //   color: Theme.of(context).primaryColor,
                        //   width: 2.0,
                        // ),
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
