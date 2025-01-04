import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_app_flutter/screens/home_page.dart';
import 'package:quran_app_flutter/screens/quran_page.dart';
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
          child: QuranPage(pageNumber: pageNumber),
        );
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
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
