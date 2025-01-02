import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_app_flutter/screens/quran_page.dart';
import 'package:quran_app_flutter/screens/table_of_contents.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
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
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri.path}'),
    ),
  ),
);
