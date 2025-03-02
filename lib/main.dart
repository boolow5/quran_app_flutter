import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/constants.dart';
import 'package:quran_app_flutter/models/notifications.dart';
import 'package:quran_app_flutter/providers/leader_board_provider.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';
import 'package:quran_app_flutter/providers/quran_data_provider.dart';
import 'package:quran_app_flutter/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> onFCMBackgroundMessage(RemoteMessage message) async {
  print("[FCM] onBackgroundMessage: ${message}");
  // return handleMessage(message);
  // final storage = SharedPreferences.getInstance();
  //
  // await storage.then((prefs) {
  //   final nots = (prefs.getStringList(notificationsKey) ?? [])
  //       .map(
  //         (e) => NotificationModel.fromMap(jsonDecode(e)),
  //       )
  //       .toList();
  //
  //   nots.insert(0, NotificationModel.fromFcm(message));
  //
  //   prefs.setStringList(
  //     notificationsKey,
  //     nots.map((e) => jsonEncode(e.toJson())).take(100).toList(),
  //   );
  // });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  const fatalError = true;
  // Non-async exceptions
  // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Catch Flutter errors
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  // FlutterError.onError = (errorDetails) {
  //   if (fatalError) {
  //     print("[FLUTTER FATAL ERROR] ${errorDetails.exceptionAsString()}");
  //     // If you want to record a "fatal" exception
  //     // FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  //     FirebaseCrashlytics.instance.recordError(
  //       errorDetails.exception,
  //       errorDetails.stack,
  //       fatal: fatalError,
  //     );
  //     // ignore: dead_code
  //   } else {
  //     print("[FLUTTER ERROR] ${errorDetails.exceptionAsString()}");
  //     // If you want to record a "non-fatal" exception
  //     FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
  //   }
  // };
  // Async exceptions
  PlatformDispatcher.instance.onError = (error, stack) {
    if (fatalError) {
      // If you want to record a "fatal" exception
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      // ignore: dead_code
    } else {
      // If you want to record a "non-fatal" exception
      FirebaseCrashlytics.instance.recordError(error, stack);
    }
    return true;
  };

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
        ChangeNotifierProvider(create: (_) => LeaderBoardProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp.router(
          scaffoldMessengerKey: scaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          title: 'MeezanSync',
          theme: themeProvider.theme,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
