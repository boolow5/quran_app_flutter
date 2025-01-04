import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/components/rounded_box_text.dart';
import 'package:quran_app_flutter/components/verse_number.dart';
import 'package:quran_app_flutter/constants.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';
import 'package:quran_app_flutter/utils/utils.dart';

class QuranPage extends StatefulWidget {
  final int pageNumber;

  const QuranPage({Key? key, required this.pageNumber}) : super(key: key);

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  late final PageController _pageController;
  String _suraName = '';
  int _suraNumber = 0;
  List<Verse> _verses = [];
  Map<int, Sura> _suras = {};
  bool _isLoading = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.pageNumber;
    _pageController = PageController(initialPage: widget.pageNumber - 1);
    _pageController.addListener(() {
      if (_pageController.page != null) {
        final newPage = _pageController.page!.round() + 1;
        if (newPage != _currentPage) {
          _currentPage = newPage;
          context.push('/page/$newPage');
          _loadVerses(newPage);
        }
      }
    });
    _loadVerses(widget.pageNumber);
  }

  @override
  void dispose() {
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.push('/');
            }
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
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          reverse: true, // For RTL
          itemCount: 604,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: SingleChildScrollView(
                    child: Container(
                      height: _isSpecialPage() ? 515 : null,
                      width: _isSpecialPage() ? 380 : null,
                      margin: _isSpecialPage()
                          ? const EdgeInsets.symmetric(vertical: 32)
                          : null,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: _isSpecialPage() ? 16.0 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: _isSpecialPage()
                            ? Border.all(
                                // color: Theme.of(context)
                                //     .colorScheme
                                //     .primary
                                //     .withOpacity(0.5),
                                color: DEFAULT_PRIMARY_COLOR,
                                width: 16.0,
                              )
                            : null,
                      ),
                      child: Container(
                        decoration: _isSpecialPage()
                            ? BoxDecoration(
                                border: Border.all(
                                  // color: Theme.of(context)
                                  //     .colorScheme
                                  //     .primary
                                  //     .withOpacity(0.3),
                                  color: DEFAULT_PRIMARY_COLOR,
                                  width: 2.0,
                                ),
                              )
                            : null,
                        padding: _isSpecialPage()
                            ? const EdgeInsets.symmetric(
                                vertical: 24.0,
                                horizontal: 24,
                              )
                            : EdgeInsets.zero,
                        child: RichText(
                          textAlign: _isSpecialPage()
                              ? TextAlign.center
                              : TextAlign.justify,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: _isSpecialPage() ? 24.0 : 24.0,
                              color: Theme.of(context).colorScheme.onBackground,
                              height: _isSpecialPage() ? 2.0 : 1.6,
                              fontFamily: DEFAULT_FONT_FAMILY, // 'KFGQPC',
                            ),
                            children:
                                _buildVerseSpans(context, widget.pageNumber),
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
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  // margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    // color: Theme.of(context).colorScheme.surfaceVariant,
                    color: DEFAULT_PRIMARY_COLOR,
                    // borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Sura type on the left
                      // Text(
                      //   sura.type,
                      //   style: TextStyle(
                      //     fontSize: DEFAULT_FONT_SIZE,
                      //     color: Colors.white,
                      //   ),
                      // ),
                      // Bismillah in the middle (only for first verse of sura, except for Sura 9)
                      if (_verses[i].number == 1 && sura.number != 9)
                        Text(
                          'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                          style: TextStyle(
                            fontFamily:
                                'KFGQPC', // DEFAULT_FONT_FAMILY, // 'KFGQPC',
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      // Sura number on the right
                      // Container(
                      //   padding: const EdgeInsets.all(8),
                      //   decoration: BoxDecoration(
                      //     border: Border.all(
                      //       color: Theme.of(context).colorScheme.onSurfaceVariant,
                      //     ),
                      //     shape: BoxShape.circle,
                      //   ),
                      //   child: Text(
                      //     toArabicNumber(sura.number),
                      //     style: TextStyle(
                      //       fontFamily: DEFAULT_FONT_FAMILY,
                      //       fontSize: DEFAULT_FONT_SIZE,
                      //       color: Colors.white,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
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
              fontSize: DEFAULT_FONT_SIZE,
              color: Theme.of(context).colorScheme.onSurfaceVariant, // red
            ),
          ),
        );
      }

      // Add verse number with end-of-verse symbol
      spans.add(TextSpan(
        text: ' ',
      ));
      if (!(pageNumber == 1 && _verses[i].number == 1)) {
        spans.add(
          buildVerseNumber(
            context,
            verseNumber: _verses[i].number,
          ),
        );
      }

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
