import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';
import 'package:quran_app_flutter/router/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Quran App',
          theme: themeProvider.theme,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
