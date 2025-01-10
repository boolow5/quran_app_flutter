import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';
import 'package:quran_app_flutter/providers/quran_data_provider.dart';
import 'package:quran_app_flutter/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final storage = SharedPreferences.getInstance();
  runApp(MyApp(
    storage: storage,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.storage});

  final Future<SharedPreferences> storage;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(storage)),
        ChangeNotifierProvider(
          create: (_) {
            final provider = QuranDataProvider();
            provider.init(storage); // Initialize shared preferences
            return provider;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'MeezanSync',
          theme: themeProvider.theme,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
