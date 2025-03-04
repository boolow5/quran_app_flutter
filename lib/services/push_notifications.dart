import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:MeezanSync/constants.dart';
import 'package:MeezanSync/main.dart';
import 'package:MeezanSync/models/notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> onFCMBackgroundMessage(RemoteMessage message) async {
  print("[FCM] onBackgroundMessage: ${message}");
  // return handleMessage(message);
  final storage = SharedPreferences.getInstance();

  await storage.then((prefs) {
    final nots = (prefs.getStringList(notificationsKey) ?? [])
        .map(
          (e) => NotificationModel.fromMap(jsonDecode(e)),
        )
        .toList();

    nots.insert(0, NotificationModel.fromFcm(message));

    prefs.setStringList(
      notificationsKey,
      nots.map((e) => jsonEncode(e.toJson())).take(100).toList(),
    );
  });
}

class PushNotifications {
  static final _fcm = FirebaseMessaging.instance;
  static String fcmToken = "";
  static void Function(RemoteMessage message) onMessage = (message) {};

  static Future<String> init([String savedToken = ""]) async {
    print("PushNotifications.init requesting permissions");
    final NotificationSettings resp = await _fcm.requestPermission();

    if (resp.authorizationStatus != AuthorizationStatus.authorized) {
      print(
          "PushNotifications.init permission not granted (${resp.authorizationStatus})");
      setupHandlers();
      return "";
    } else {
      print("PushNotifications.init permission granted");

      if (savedToken.isNotEmpty && savedToken != fcmToken) {
        print("PushNotifications.init saved token: $savedToken");
        fcmToken = savedToken;
      } else {
        // get fcm token
        final token = await _fcm.getToken();
        if (token != null && token.isNotEmpty) {
          print("got new fcm token: $fcmToken");
          fcmToken = token;
        }
      }
    }

    setupHandlers();
    return fcmToken;
  }

  static Future<void> setupHandlers() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("[FCM] onMessage: ${message}");
      handleMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("[FCM] onMessageOpenedApp: ${message}");
      handleMessage(message, isOpenedApp: true);
    });

    FirebaseMessaging.onBackgroundMessage(onFCMBackgroundMessage);
  }

  static Future<void> goToScreen(String screenName, {Object? extra}) async {
    print("PushNotifications.goToScreen: $screenName, extra: $extra");
    GoRouter.of(navigatorKey.currentContext!).go(screenName, extra: extra);
  }

  static Future<void> handleMessage(RemoteMessage? message,
      {bool isOpenedApp = false}) async {
    if (message == null) {
      print("PushNotifications.handleMessage: message is null");
      print("PushNotifications.handleMessage: isOpenedApp: $isOpenedApp");
      return;
    }

    onMessage(message);

    if (isOpenedApp) {
      if (message.data['screen'] != null) {
        print(
            "PushNotifications.handleMessage: screen in data: \'${message.data['screen']}\'");
        goToScreen(
          message.data['screen']!,
          extra: message,
        );
      } else {
        print("PushNotifications.handleMessage: 'no screen in data'");
        print(
            "PushNotifications.handleMessage: data: ${message.notification?.toMap()}");
        goToScreen("/", extra: message);
      }
    } else {
      // show snackbar with the notification title and message
      if (message.notification != null) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            backgroundColor: Colors.teal,
            content: GestureDetector(
              onTap: () {
                print("PushNotifications.handleMessage: notification tapped");
                if (message.data['screen'] != null) {
                  print(
                      "PushNotifications.handleMessage snackbar: \'${message.data['screen']}\'");
                  goToScreen(
                    message.data['screen']!,
                    extra: message,
                  );
                } else {
                  print(
                      "PushNotifications.handleMessage snackbar: 'no screen in data'");
                  goToScreen("/", extra: message);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    message.notification!.title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.notification!.body!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
  }
}
