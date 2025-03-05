import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:MeezanSync/constants.dart';
import 'package:MeezanSync/screens/about_page.dart';
import 'package:MeezanSync/screens/bookmarks_page.dart';
import 'package:MeezanSync/screens/home_page.dart';
import 'package:MeezanSync/screens/leader_board_page.dart';
import 'package:MeezanSync/screens/login_page.dart';
import 'package:MeezanSync/screens/qibla_compass_page.dart';
import 'package:MeezanSync/screens/quran_pages.dart';
import 'package:MeezanSync/screens/settings_page.dart';
import 'package:MeezanSync/screens/table_of_contents.dart';

final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey,
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
          child: QuranPages(
            routePageNumber: pageNumber,
            onPageChange: (pageNumber) {
              navigatorKey.currentContext?.go('/page/$pageNumber');
            },
          ),
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
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutPage(),
    ),
    GoRoute(
      path: "/leader-board",
      builder: (context, state) => LeaderBoardPage(),
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
