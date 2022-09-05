import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'Constant.dart';
import 'Session.dart';
import 'String.dart';

//notification handle in this class

class PushNotificationService {
  FirebaseMessaging _fcm;

  PushNotificationService(this._fcm);

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future initialise() async {
    if (Platform.isIOS) {
      iospermission();
    }
    _fcm.getToken();
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(myForgroundMessageHandler);
    FirebaseMessaging.onMessage.listen(myForgroundMessageHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(myForgroundMessageHandler);
  }

  void iospermission() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static Future<dynamic> myForgroundMessageHandler(
      RemoteMessage message) async {
    if (message.data != null) {
      var data = message.data;
      if (data['type'] == "default" || data['type'] == "category") {

        var title = data['title'].toString();
        var body = data['message'].toString();
        var image = data['image'];
        var payload = data["news_id"];

        if (payload == null) {
          payload = "";
        } else {
          payload = payload;
        }

        if (image != null || image != "") {
          if (notiEnable!) {
            generateImageNotication(title, body, image, payload);
          }
        } else {
          if (notiEnable!) {
            generateSimpleNotication(title, body, payload);
          }
        }
      } else {

        var type = data['type'].toString();
        var newsId = data['news_id'].toString();
        var message = data['message'];


        if (notiEnable!) {
          generateSimpleNotication(message, "", newsId);
        }
      }
    }
  }

  static Future<String> _downloadAndSaveFile(
      String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  static Future<void> generateImageNotication(
      String title, String msg, String image, String type) async {
    var largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
    var bigPicturePath = await _downloadAndSaveFile(image, 'bigPicture');
    var bigPictureStyleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(bigPicturePath),
        hideExpandedLargeIcon: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
        summaryText: msg,
        htmlFormatSummaryText: true);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'com.desidiaries.com',
      'news',
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      styleInformation: bigPictureStyleInformation,
    );
    var platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, title, msg, platformChannelSpecifics, payload: type);
  }

  static Future<void> generateSimpleNotication(
      String title, String msg, String type) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'com.desidiaries.com',
      'news',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    var platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, title, msg, platformChannelSpecifics, payload: type);
  }
}
