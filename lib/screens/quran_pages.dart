import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/components/quran_single_page.dart';
import 'package:quran_app_flutter/providers/quran_data_provider.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';
import 'package:quran_app_flutter/utils/utils.dart';

class QuranPages extends StatefulWidget {
  final int routePageNumber;
  const QuranPages({
    super.key,
    required this.routePageNumber,
  });

  @override
  State<QuranPages> createState() => _QuranPagesState();
}

class _QuranPagesState extends State<QuranPages> {
  late final PageController _pageController;
  int _currentPage = 1;
  int _bookmarkPage = 0;
  String _currentSuraName = '';

  bool isTablet = false;
  bool isLandscape = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(microseconds: 100), () {
      setState(() {
        isLoading = false;
      });
    });

    Future.delayed(Duration.zero, () {
      final initialPage = context.read<ThemeProvider>().isDoublePaged
          ? (widget.routePageNumber / 2).ceil()
          : widget.routePageNumber - 1;

      print(
          "routePageNumber: ${widget.routePageNumber}, initialPage: $initialPage");
      _pageController = PageController(initialPage: initialPage);
      setState(() {
        _bookmarkPage = widget.routePageNumber;
      });
      _pageController.addListener(() {
        if (_pageController.page != null) {
          final newPage = _pageController.page!.round() + 1;
          // (isTablet && isLandscape
          //     ? (_pageController.page!.round() % 2 == 0)
          //         ? 2
          //         : 1
          //     : 1);
          if (newPage != _currentPage) {
            _currentPage = newPage;
            print("\n\tPage Changed: ${widget.routePageNumber} -> $newPage");
            print(
                "\n\tCurrent Page: $_currentPage, New Page: $newPage -> '/page/$newPage'");
            context.go('/page/$newPage');
            setState(() {});
            // _loadVerses(newPage);
            // if (_suraName.isNotEmpty) {
            //   _quranDataProvider.setCurrentPage(newPage, _suraName);
            // }
          }
        }
      });

      setState(() {
        isTablet = MediaQuery.sizeOf(context).width > 600;
        isLandscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;
      });

      if (!mounted) return;
      final size = MediaQuery.sizeOf(context);
      context.read<ThemeProvider>().setScreenSize(
            size.width,
            size.height,
            MediaQuery.sizeOf(context).width > 600,
            MediaQuery.orientationOf(context) == Orientation.landscape,
          );
    });
  }

  // @override
  // void didUpdateWidget(QuranPages oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   setState(() {
  //     isTablet = MediaQuery.sizeOf(context).width > 600;
  //     isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;
  //   });
  //   if (widget.pageNumber != oldWidget.pageNumber) {
  //     _currentPage = widget.pageNumber;
  //     // _pageController
  //     //     .jumpToPage(widget.pageNumber - (isTablet && isLandscape ? 2 : 1));
  //     _pageController.jumpToPage(widget.pageNumber - 1);
  //   }
  // }

  @override
  void dispose() {
    super.dispose();

    _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    // print(
    //     "scaleFactor: ${context.read<ThemeProvider>().scaleFactor} isTablet: $isTablet isLandscape: $isLandscape");

    final isBookmarked = context
        .watch<QuranDataProvider>()
        .isBookmarked(_bookmarkPage, isWideScreen: isTablet && isLandscape);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : PageView.builder(
                    controller: _pageController,
                    reverse: true, // For RTL
                    itemCount: isTablet && isLandscape ? 302 : 604,
                    pageSnapping: true,
                    itemBuilder: (context, index) {
                      if (isTablet && isLandscape) {
                        final firstPage =
                            (index % 2 == 0 ? index : index - 1) + 1;
                        final secondPage = firstPage + 1;
                        print(
                            "[$index] leftPage: $secondPage, rightPage: $firstPage");
                        // final rightPage = _currentPage % 2 == 0
                        //     ? _currentPage
                        //     : _currentPage > 1
                        //         ? _currentPage - 1
                        //         : 1;
                        // final leftPage = rightPage + 1;
                        // // final leftPage = widget.pageNumber % 2 == 0
                        // //     ? widget.pageNumber + 1
                        // //     : widget.pageNumber;
                        return Row(
                          children: [
                            // second page of the Quran
                            Expanded(
                              child: QuranSinglePage(
                                  pageNumber: secondPage, // left page,
                                  updatePageNumber: false,
                                  isTablet: isTablet,
                                  isLandscape: isLandscape,
                                  onSuraChange: (pageNumber, suraName) {
                                    // ignore changes as they are already handled in the first page
                                  }),
                            ),
                            // first page of the Quran
                            Expanded(
                              child: QuranSinglePage(
                                pageNumber: firstPage, // right page,
                                updatePageNumber: true,
                                isTablet: isTablet,
                                isLandscape: isLandscape,
                                onSuraChange: (pageNumber, suraName) {
                                  _currentSuraName = suraName;
                                  _bookmarkPage = pageNumber;

                                  context
                                      .read<QuranDataProvider>()
                                      .setEndTimeForMostRecentPage(
                                        pageNumber,
                                        suraName,
                                        isDoublePage: isTablet && isLandscape,
                                      );
                                },
                              ),
                            ),
                          ],
                        );
                      } else if (isTablet && !isLandscape) {
                        return QuranSinglePage(
                          pageNumber: index + 1,
                          updatePageNumber: true,
                          isTablet: isTablet,
                          isLandscape: isLandscape,
                          onSuraChange: (pageNumber, suraName) {
                            _currentSuraName = suraName;
                            _bookmarkPage = pageNumber;
                            context
                                .read<QuranDataProvider>()
                                .setEndTimeForMostRecentPage(
                                  pageNumber,
                                  suraName,
                                  isDoublePage: isTablet && isLandscape,
                                );
                          },
                        );
                      }
                      return QuranSinglePage(
                        pageNumber: index + 1,
                        updatePageNumber: true,
                        isTablet: isTablet,
                        isLandscape: isLandscape,
                        onSuraChange: (pageNumber, suraName) {
                          _currentSuraName = suraName;
                          _bookmarkPage = pageNumber;
                          context
                              .read<QuranDataProvider>()
                              .setEndTimeForMostRecentPage(
                                pageNumber,
                                suraName,
                                isDoublePage: isTablet && isLandscape,
                              );
                        },
                      );
                    },
                  ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                // width: 50,
                // height: 50,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                ),
                child: IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                    color: isBookmarked
                        ? Colors.green
                        : Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () {
                    final saved = context.read<QuranDataProvider>().addBookmark(
                          _bookmarkPage,
                          _currentSuraName,
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
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                // width: 50,
                // height: 50,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    context
                        .read<QuranDataProvider>()
                        .setEndTimeForMostRecentPage(
                          _bookmarkPage,
                          _currentSuraName,
                          isDoublePage: isTablet && isLandscape,
                        );
                    context.push('/table-of-contents');
                  },
                ),
              ),
            ),
            if (isTablet && isLandscape) ...[
              Positioned(
                bottom: 30,
                left: 4,
                child: Container(
                  // width: 50,
                  // height: 50,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: GestureDetector(
                    child: Container(
                      padding: const EdgeInsets.only(top: 40),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chevron_left,
                            size: 40,
                            color: _bookmarkPage > 603 ? Colors.grey : null,
                          ),
                          Text(
                            _bookmarkPage + 2 == 604
                                ? ''
                                : toArabicNumber(_bookmarkPage + 2),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      print("GO to next page ${_bookmarkPage + 2}");
                      context.go('/page/${_bookmarkPage + 2}');
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 30,
                right: 4,
                child: Container(
                  // width: 50,
                  // height: 50,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: GestureDetector(
                    onTap: _bookmarkPage - 2 > 0
                        ? () {
                            print("GO to prev page ${_bookmarkPage - 2}");
                            context.go('/page/${_bookmarkPage - 2}');
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.only(top: 40),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _bookmarkPage - 2 > 0
                                ? toArabicNumber(_bookmarkPage - 2)
                                : '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 40,
                            color: _bookmarkPage - 2 > 0 ? null : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }
}
