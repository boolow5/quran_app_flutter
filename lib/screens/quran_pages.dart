import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/components/quran_single_page.dart';
import 'package:quran_app_flutter/providers/quran_data_provider.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';
import 'package:quran_app_flutter/screens/quran_page.dart';

class QuranPages extends StatefulWidget {
  final int pageNumber;
  const QuranPages({
    super.key,
    required this.pageNumber,
  });

  @override
  State<QuranPages> createState() => _QuranPagesState();
}

class _QuranPagesState extends State<QuranPages> {
  late final PageController _pageController;
  int _currentPage = 1;

  bool isTablet = false;
  bool isLandscape = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.pageNumber - 1);
    _pageController.addListener(() {
      if (_pageController.page != null) {
        final newPage = _pageController.page!.round() +
            (isTablet && isLandscape
                ? (_pageController.page!.round() % 2 == 0)
                    ? 2
                    : 1
                : 1);
        if (newPage != _currentPage) {
          _currentPage = newPage;
          print("\n\tPage Changed: ${widget.pageNumber} -> $newPage");
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

    Future.delayed(
        Duration.zero,
        () => setState(() {
              isTablet = MediaQuery.sizeOf(context).width > 600;
              isLandscape =
                  MediaQuery.orientationOf(context) == Orientation.landscape;
            }));
  }

  @override
  void didUpdateWidget(QuranPages oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      isTablet = MediaQuery.sizeOf(context).width > 600;
      isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    });
    if (widget.pageNumber != oldWidget.pageNumber) {
      _currentPage = widget.pageNumber;
      // _pageController
      //     .jumpToPage(widget.pageNumber - (isTablet && isLandscape ? 2 : 1));
      _pageController.jumpToPage(widget.pageNumber - 1);
    }
  }

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
    print(
        "scaleFactor: ${context.read<ThemeProvider>().scaleFactor} isTablet: $isTablet isLandscape: $isLandscape");
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              reverse: true, // For RTL
              itemCount: isTablet && isLandscape ? 302 : 604,
              pageSnapping: true,
              itemBuilder: (context, index) {
                if (isTablet && isLandscape) {
                  final firstPage = (index % 2 == 0 ? index : index - 1) + 1;
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
                          pageNumber: secondPage, // leftPage,
                          updatePageNumber: false,
                          isTablet: isTablet,
                          isLandscape: isLandscape,
                        ),
                      ),
                      // first page of the Quran
                      Expanded(
                        child: QuranSinglePage(
                          pageNumber: firstPage, // rightPage,
                          updatePageNumber: true,
                          isTablet: isTablet,
                          isLandscape: isLandscape,
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
                  );
                }
                return QuranSinglePage(
                  pageNumber: index + 1,
                  updatePageNumber: true,
                  isTablet: isTablet,
                  isLandscape: isLandscape,
                );
              },
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
                    context.push('/table-of-contents');
                  },
                ),
              ),
            ),
            if (isTablet && isLandscape) ...[
              Positioned(
                bottom: 0,
                left: 4,
                child: Container(
                  // width: 50,
                  // height: 50,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      size: 40,
                    ),
                    onPressed: () {
                      _pageController.jumpToPage(_currentPage + 1);
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 4,
                child: Container(
                  // width: 50,
                  // height: 50,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.chevron_right,
                      size: 40,
                    ),
                    onPressed: () {
                      _pageController.jumpToPage(_currentPage - 1);
                    },
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
