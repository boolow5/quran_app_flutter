import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/constants.dart';
import 'package:quran_app_flutter/providers/quran_data_provider.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  List<RecentPage> _selectedBookmarks = [];

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      setState(() {
        _selectedBookmarks = [];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Bookmarks'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: context.watch<QuranDataProvider>().bookmarks.isEmpty
          ? const Center(child: Text('No bookmarks'))
          : LayoutBuilder(builder: (context, constraints) {
              final isAllSelected = _selectedBookmarks.length ==
                  context.read<QuranDataProvider>().bookmarks.length;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // select all
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedBookmarks = _selectedBookmarks.isEmpty
                                  ? context.read<QuranDataProvider>().bookmarks
                                  : _selectedBookmarks.length !=
                                          context
                                              .read<QuranDataProvider>()
                                              .bookmarks
                                              .length
                                      ? context
                                          .read<QuranDataProvider>()
                                          .bookmarks
                                      : [];
                            });
                          },
                          child: Row(
                            children: [
                              Icon(isAllSelected
                                  ? Icons.clear
                                  : _selectedBookmarks.isNotEmpty
                                      ? Icons.select_all
                                      : Icons.check_box_outline_blank),
                              const SizedBox(width: 8),
                              Text(isAllSelected
                                  ? 'Deselect All'
                                  : 'Select All'),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              final selectedIndices = _selectedBookmarks
                                  .map((b) => b.pageNumber)
                                  .toList();
                              context
                                  .read<QuranDataProvider>()
                                  .removeBookmark(selectedIndices);
                              _selectedBookmarks = [];
                            });
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.delete),
                              Text('Select All'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: constraints.maxHeight - 48,
                    child: ListView.builder(
                      itemCount:
                          context.watch<QuranDataProvider>().bookmarks.length,
                      itemBuilder: (context, index) {
                        final bookmark =
                            context.watch<QuranDataProvider>().bookmarks[index];
                        return ListTile(
                          leading: IconButton(
                            icon: _selectedBookmarks.contains(bookmark)
                                ? const Icon(Icons.check_box)
                                : const Icon(Icons.check_box_outline_blank),
                            onPressed: () {
                              setState(() {
                                if (_selectedBookmarks.contains(bookmark)) {
                                  _selectedBookmarks.remove(bookmark);
                                } else {
                                  _selectedBookmarks.add(bookmark);
                                }
                              });
                            },
                          ),
                          title: Text(
                            bookmark.suraName,
                            style: TextStyle(
                              fontFamily: defaultFontFamily(),
                              fontSize:
                                  context.read<ThemeProvider>().fontSize(24),
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                          subtitle: Text(
                            'Page ${bookmark.pageNumber}',
                            style: TextStyle(
                              fontSize:
                                  context.read<ThemeProvider>().fontSize(16),
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          trailing: Text(
                            context
                                .read<QuranDataProvider>()
                                .timeSinceReading(bookmark, start: true)
                                .toString(),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          onTap: () {
                            context.push('/page/${bookmark.pageNumber}');
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
    );
  }
}
