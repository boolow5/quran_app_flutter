import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_app_flutter/screens/about_page.dart';
import 'package:quran_app_flutter/screens/bookmarks_page.dart';
import 'package:quran_app_flutter/screens/home_page.dart';
import 'package:quran_app_flutter/screens/qibla_compass_page.dart';
import 'package:quran_app_flutter/screens/quran_pages.dart';
import 'package:quran_app_flutter/screens/settings_page.dart';
import 'package:quran_app_flutter/screens/table_of_contents.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Home(),
    ),
    GoRoute(
      path: '/table-of-contents',
      builder: (context, state) => const TableOfContents(),
    ),
    GoRoute(
      path: '/page/:pageNumber',
      pageBuilder: (context, state) {
        final pageNumber =
            int.tryParse(state.pathParameters['pageNumber'] ?? '1') ?? 1;
        return NoTransitionPage(
          child: QuranPages(pageNumber: pageNumber),
        );
      },
    ),
    GoRoute(
      path: "/bookmarks",
      builder: (context, state) => const BookmarksPage(),
    ),
    GoRoute(
      path: "/qibla",
      builder: (context, state) => const QiblaCompass(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutPage(),
    ),
  ],
  errorBuilder: (context, state) {
    final text = 'Page not found: ${state.uri.path}';
    print(text);
    return Scaffold(
      body: Center(
        child: Text(text),
      ),
    );
  },
);
