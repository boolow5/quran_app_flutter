import 'package:MeezanSync/utils/utils.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:MeezanSync/constants.dart';
import 'package:MeezanSync/firebase_options.dart';
import 'package:MeezanSync/providers/leader_board_provider.dart';
import 'package:MeezanSync/providers/onboarding_provider.dart';
import 'package:MeezanSync/providers/theme_provider.dart';
import 'package:MeezanSync/providers/quran_data_provider.dart';
import 'package:MeezanSync/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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

  await routeNotifier.loadSavedLocation();

  WakelockPlus.enable();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) {
    if (!kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    } else {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    }
    const fatalError = true;
    // Non-async exceptions
    // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Catch Flutter errors
    FlutterError.onError =
        (FlutterErrorDetails flutterErrorDetails, {bool fatal = false}) {
      if (!kDebugMode && !kIsWeb) {
        FirebaseCrashlytics.instance
            .recordFlutterError(flutterErrorDetails, fatal: fatal);
      }
    };

    // FlutterError.onError = (errorDetails) {
    //   if (fatalError) {
    //     print("[FLUTTER FATAL ERROR] ${errorDetails.exceptionAsString()}");
    //     // If you want to record a "fatal" exception
    //     // FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    //     FirebaseCrashlyticsRecordError(
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
        FirebaseCrashlyticsRecordError(error, stack, fatal: true);
        // ignore: dead_code
      } else {
        // If you want to record a "non-fatal" exception
        FirebaseCrashlyticsRecordError(error, stack);
      }
      return true;
    };
  }

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
          create: (_) => QuranDataProvider(storage),
        ),
        ChangeNotifierProvider(create: (_) => LeaderBoardProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider(storage)),
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
