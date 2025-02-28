import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:quran_app_flutter/utils/utils.dart';

class NotificationModel {
  final int? id;
  final String title;
  final String body;
  final DateTime time;
  final String routeName;
  final Map<String, dynamic>? more;
  final bool? isSeen;

  NotificationModel({
    this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.routeName,
    this.more,
    this.isSeen,
  });

  // copyWith
  NotificationModel copyWith({
    int? id,
    String? title,
    String? body,
    DateTime? time,
    String? routeName,
    Map<String, dynamic>? more,
    bool? isSeen,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      time: time ?? this.time,
      routeName: routeName ?? this.routeName,
      more: more ?? this.more,
      isSeen: isSeen ?? this.isSeen,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'time': time.toUtc().toIso8601String(),
      'routeName': routeName,
      'more': more ?? Map<String, dynamic>.from({}),
      'seen': isSeen,
    };
  }

  fromJson(Map<String, dynamic> data) {
    print("NotificationModel: fromJson: $time");
    return NotificationModel.fromMap(data);
  }

  static NotificationModel fromFcm(RemoteMessage message) {
    print("fromFcm: ${message.data}");
    return NotificationModel(
      id: parseField<int>(message.data, "notification_id", 0),
      title: message.notification?.title ?? "",
      body: message.notification?.body ?? "",
      time: message.sentTime ?? DateTime.now(),
      routeName: message.data["screen"] ?? "",
      more: message.data,
      isSeen: false,
    );
  }

  static NotificationModel fromMap(Map<String, dynamic> data) {
    final time = data["item"] ?? data["created_at"];
    print("NotificationModel: fromJson: $time");
    final extras =
        data["more"] ?? data["data"] ?? Map<String, dynamic>.from({});
    return NotificationModel(
      id: parseField<int>(data, "id", 0),
      title: data["title"],
      body: data["body"],
      time: time != null ? DateTime.parse(time) : DateTime.now(),
      routeName: extras["routeName"] ?? extras["screen"] ?? "/notifications",
      more: extras,
      isSeen: data["seen"],
    );
  }

  @override
  String toString() {
    return 'NotificationModel{id: $id,title: $title, body: $body, time: $time, routeName: $routeName}';
  }
}
