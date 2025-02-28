import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/models/notifications.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';
import 'package:quran_app_flutter/providers/quran_data_provider.dart';
import 'package:quran_app_flutter/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String notificationsKey = "notifications";
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
