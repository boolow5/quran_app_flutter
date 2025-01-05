import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/components/rounded_box_text.dart';
import 'package:quran_app_flutter/components/verse_number.dart';
import 'package:quran_app_flutter/constants.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';
import 'package:quran_app_flutter/providers/quran_data_provider.dart';
import 'package:quran_app_flutter/utils/utils.dart';

class QuranPage extends StatefulWidget {
  final int pageNumber;

  const QuranPage({Key? key, required this.pageNumber}) : super(key: key);

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  late final PageController _pageController;
  late final QuranDataProvider _quranDataProvider;
  String _suraName = '';
  int _suraNumber = 0;
  List<Verse> _verses = [];
  Map<int, Sura> _suras = {};
  bool _isLoading = true;
  int _currentPage = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    _quranDataProvider = context.read<QuranDataProvider>();
    _currentPage = widget.pageNumber;
    _pageController = PageController(initialPage: widget.pageNumber - 1);
    _pageController.addListener(() {
      if (_pageController.page != null) {
        final newPage = _pageController.page!.round() + 1;
        if (newPage != _currentPage) {
          _currentPage = newPage;
          context.go('/page/$newPage');
          _loadVerses(newPage);
          if (_suraName.isNotEmpty) {
            _quranDataProvider.setCurrentPage(newPage, _suraName);
          }
        }
      }
    });
    _loadVerses(widget.pageNumber);

    // Initialize current page in QuranDataProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_suraName.isNotEmpty) {
        _quranDataProvider.setCurrentPage(widget.pageNumber, _suraName);
      }
    });
  }

  @override
  void dispose() {
    _quranDataProvider.setEndTimeForMostRecentPage();
    _pageController.dispose();
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
      if (_suraName.isNotEmpty) {
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _quranDataProvider.setEndTimeForMostRecentPage();
            context.push('/table-of-contents');
          },
        ),
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RoundedBoxText(
              text: "السورة ${toArabicNumber(_suraNumber)}",
              width: 100,
            ),
            RoundedBoxText(
              text: toArabicNumber(widget.pageNumber),
              width: 40,
            ),
            RoundedBoxText(
              text: _suraName,
              width: 100,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              final saved = _quranDataProvider.addBookmark(
                widget.pageNumber,
                _suraName,
              );
              if (saved) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bookmark saved successfully',
                        style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to save bookmark',
                        style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          reverse: true, // For RTL
          itemCount: 604,
          pageSnapping: true,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: SingleChildScrollView(
                    child: Center(
                      child: Container(
                        height: _isSpecialPage() ? boxHeight : null,
                        width: _isSpecialPage() ? boxWidth : null,
                        margin: _isSpecialPage()
                            ? EdgeInsets.symmetric(vertical: 32, horizontal: 0)
                            : null,
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              context.read<ThemeProvider>().fontSize(20.0),
                          vertical: _isSpecialPage() ? 20.0 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(boxWidth / 2),
                          border: _isSpecialPage()
                              ? Border.all(
                                  color: DEFAULT_PRIMARY_COLOR,
                                  width: 16.0,
                                )
                              : null,
                        ),
                        child: Container(
                          decoration: _isSpecialPage()
                              ? BoxDecoration(
                                  border: Border.all(
                                    color: Colors
                                        .transparent, // DEFAULT_PRIMARY_COLOR,
                                    width: 2.0,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(boxWidth / 4),
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
                                    .fontSize(_isSpecialPage() ? 24.0 : 24.0),
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                                height: _isSpecialPage() ? 1.7 : 1.5,
                                fontFamily: DEFAULT_FONT_FAMILY,
                              ),
                              children:
                                  _buildVerseSpans(context, widget.pageNumber),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(QuranPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pageNumber != oldWidget.pageNumber) {
      _currentPage = widget.pageNumber;
      _pageController.jumpToPage(widget.pageNumber - 1);
      _loadVerses(widget.pageNumber);
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
}

// Model class for verses
class Verse {
  final String text;
  final int number;
  final int suraNumber;
  final String? bismillah;

  Verse({
    required this.text,
    required this.number,
    required this.suraNumber,
    this.bismillah,
  });

  factory Verse.fromJson(int suraNumber, Map<String, dynamic> json) {
    return Verse(
      text: json['text'] as String,
      number: json['index'] as int,
      suraNumber: suraNumber,
      bismillah: json['bismillah'] as String?,
    );
  }
}

class Sura {
  final int number;
  final String name;
  final String transliteratedName;
  final String englishName;
  final String type;

  Sura({
    required this.number,
    required this.name,
    required this.transliteratedName,
    required this.englishName,
    required this.type,
  });

  factory Sura.fromJson(int number, Map<String, dynamic> json) {
    return Sura(
      number: number,
      name: json['name'] as String,
      transliteratedName: json['tname'] as String,
      englishName: json['ename'] as String,
      type: json['type'] as String,
    );
  }
}
