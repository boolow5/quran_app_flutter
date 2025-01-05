import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/constants.dart';
import 'package:quran_app_flutter/providers/quran_data_provider.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';

class BookmarksPage extends StatelessWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarks = context.watch<QuranDataProvider>().bookmarks;
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
              context.push('/');
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
      body: bookmarks.isEmpty
          ? const Center(child: Text('No bookmarks'))
          : ListView.builder(
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final bookmark = bookmarks[index];
                return ListTile(
                  title: Text(
                    bookmark.suraName,
                    style: TextStyle(
                      fontFamily: DEFAULT_FONT_FAMILY,
                      fontSize: context.read<ThemeProvider>().fontSize(24),
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  subtitle: Text(
                    'Page ${bookmark.pageNumber}',
                    style: TextStyle(
                      fontSize: context.read<ThemeProvider>().fontSize(16),
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Text(
                    context
                        .read<QuranDataProvider>()
                        .timeSinceReading(bookmark, start: true)
                        .toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () {
                    context.push('/page/${bookmark.pageNumber}');
                  },
                );
              },
            ),
    );
  }
}
