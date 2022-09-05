import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:news/Helper/Color.dart';
import 'package:news/Helper/Constant.dart';
import 'package:news/Helper/Demo_Localization.dart';
import 'package:news/Helper/String.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

//prefrence string set using this function
setPrefrence(String key, String value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}

//prefrence string get using this function
Future<String?> getPrefrence(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}

//prefrence boolean set using this function
setPrefrenceBool(String key, bool value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(key, value);
}

//prefrence boolean get using this function
Future<bool> getPrefrenceBool(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool(key) ?? false;
}

setPrefrenceList(String key, String query) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? valueList = await getPrefrenceList(key);
  if (!valueList!.contains(query)) {
    if (valueList.length > 4) valueList.removeAt(0);
    valueList.add(query);

    prefs.setStringList(key, valueList);
  }
}

Future<List<String>?> getPrefrenceList(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(key);
}

//check network available or not
Future<bool> isNetworkAvailable() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.mobile) {
    return true;
  } else if (connectivityResult == ConnectivityResult.wifi) {
    return true;
  }
  return false;
}

contentShimmer(BuildContext context) {
  return Shimmer.fromColors(
      baseColor: Colors.grey.withOpacity(0.6),
      highlightColor: Colors.grey,
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.only(
          top: 15.0,
        ),
        child: ListView.builder(
          shrinkWrap: true,
          physics: BouncingScrollPhysics(),
          itemBuilder: (_, i) => Padding(
              padding: EdgeInsetsDirectional.only(top: i == 0 ? 0 : 15.0),
              child: Stack(children: [
                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Colors.grey.withOpacity(0.6)),
                  height: 320.0,
                ),
                Positioned.directional(
                    textDirection: Directionality.of(context),
                    bottom: 10.0,
                    start: 10,
                    end: 10,
                    height: 123,
                    child: Container(
                        padding: EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: Colors.grey,
                        ))),
              ])),
          itemCount: 6,
        ),
      ));
}

String placeHolder = "assets/images/placeholder.png";

//network image in error
errorWidget(double height,double width) {
  return Image.asset(
    "assets/images/placeholder.png",
    height: height,
    width: width,
  );
}

//set circular progress here
Widget showCircularProgress(bool _isProgress, Color color) {
  if (_isProgress) {
    return Center(
        child: CircularProgressIndicator(
      valueColor: new AlwaysStoppedAnimation<Color>(color),
    ));
  }
  return Container(
    height: 0.0,
    width: 0.0,
  );
}

//set prefrence in user details
Future<void> saveUserDetail(String id, String name, String email, String mobile,
    String profile, String type, String status,String cover,String bio) async {
  final waitList = <Future<void>>[];
  SharedPreferences prefs = await SharedPreferences.getInstance();
  waitList.add(prefs.setString(ID, id));
  waitList.add(prefs.setString(NAME, name));
  waitList.add(prefs.setString(EMAIL, email));
  waitList.add(prefs.setString(MOBILE, mobile));
  waitList.add(prefs.setString(PROFILE, profile));
  waitList.add(prefs.setString(COVER, cover));
  waitList.add(prefs.setString(TYPE, type));
  waitList.add(prefs.setString(STATUS, status));
  waitList.add(prefs.setString(BIO, bio));
  await Future.wait(waitList);
}

//set language code
Future<Locale> setLocale(String? languageCode) async {
  SharedPreferences _prefs = await SharedPreferences.getInstance();
  await _prefs.setString(LANGUAGE_CODE, languageCode!);
  return _locale(languageCode);
}

//get language code
Future<Locale> getLocale() async {
  SharedPreferences _prefs = await SharedPreferences.getInstance();
  String? languageCode = _prefs.getString(LANGUAGE_CODE) == null
      ? "en"
      : _prefs.getString(LANGUAGE_CODE);
  return _locale(languageCode!);
}

//change language code from list
Locale _locale(String languageCode) {
  switch (languageCode) {
    case "en":
      return Locale("en", "US");
    case "es":
      return Locale("es", "ES");
    case "hi":
      return Locale("hi", "IN");
    case "tr":
      return Locale("tr", "TR");
    case "pt":
      return Locale("pt", "PT");
    default:
      return Locale("en", "US");
  }
}

//create dynamic link that used in share specific news
Future<void> createDynamicLink(String id, int index, String title) async {
  final DynamicLinkParameters parameters = DynamicLinkParameters(
    uriPrefix: deepLinkUrlPrefix,
    link: Uri.parse('https://$deepLinkName/?id=$id&index=$index'),
    androidParameters: AndroidParameters(
      packageName: packageName,
      minimumVersion: 1,
    ),
    iosParameters: IOSParameters(
      bundleId: iosPackage,
      minimumVersion: '1',
      appStoreId: appStoreId,
    ),
  );

 // final Uri longDynamicUrl = await parameters.buildUrl();
  final ShortDynamicLink shortenedLink =
  await FirebaseDynamicLinks.instance.buildShortLink(parameters);
  var str =
      "${title}\n\n$appName\n\nYou can find our app from below url\n\nAndroid:\n"
      "$androidLink$packageName\n\n iOS:\n$iosLink$iosPackage";

  final Uri shortUrl = shortenedLink.shortUrl;

  Share.share(shortUrl.toString(), subject: str);
}

//translate string based on language code
String? getTranslated(BuildContext context, String key) {
  return DemoLocalization.of(context)!.translate(key);
}

//clear all prefrences
Future<void> clearUserSession() async {
  final waitList = <Future<void>>[];

  SharedPreferences prefs = await SharedPreferences.getInstance();

  waitList.add(prefs.remove(ID));
  waitList.add(prefs.remove(NAME));
  waitList.add(prefs.remove(EMAIL));
  CUR_USERID = "";
  CUR_USERNAME = "";
  CUR_USEREMAIL = "";
  CATID = "";

  await prefs.clear();
}



//set convert date time
String? convertToAgo(DateTime input, int from) {
  Duration diff = DateTime.now().difference(input);

  if (diff.inDays >= 1) {
    if (from == 0) {
      var newFormat = DateFormat("dd MMMM yyyy");
      final newsDate1 = newFormat.format(input);
      return newsDate1;
    } else if (from == 1) {
      return '${diff.inDays} days ago';
    } else if (from == 2) {
      var newFormat = DateFormat("dd MMMM yyyy HH:mm:ss");
      final newsDate1 = newFormat.format(input);
      return newsDate1;
    }
  } else if (diff.inHours >= 1) {
    if (input.minute == 00) {
      return '${diff.inHours} hours ago';
    } else {
      if (from == 2) {
        return 'about ${diff.inHours} hours ${input.minute} minutes ago';
      } else {
        return '${diff.inHours} hours ${input.minute} minutes ago';
      }
    }
  } else if (diff.inMinutes >= 1) {
    return '${diff.inMinutes} minutes ago';
  } else if (diff.inSeconds >= 1) {
    return '${diff.inSeconds} seconds ago';
  } else {
    return 'just now';
  }
}

//name validation check
String? nameValidation(String value, BuildContext context) {
  if (value.isEmpty) {
    return getTranslated(context, 'name_required')!;
  }
  if (value.length <= 1) {
    return getTranslated(context, 'name_length')!;
  }
  return null;
}

//email validation check
String? emailValidation(String value, BuildContext context) {
  if (value.length == 0) {
    return getTranslated(context, 'email_required')!;
  } else if (!RegExp(
          r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)"
          r"*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+"
          r"[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
      .hasMatch(value)) {
    return getTranslated(context, 'email_valid')!;
  } else {
    return null;
  }
}

//password validation check
String? passValidation(String value, BuildContext context) {
  if (value.length == 0)
    return getTranslated(context, 'pwd_required')!;
  else if (value.length <= 5)
    return getTranslated(context, 'pwd_length')!;
  else
    return null;
}

String? mobValidation(String value, BuildContext context) {
  if (value.isEmpty) {
    return getTranslated(context, 'mbl_required')!;
  }
  if (value.length < 9) {
    return getTranslated(context, 'mbl_valid')!;
  }
  return null;
}

//get token from admin side here to change your token details
String getToken() {
  final claimSet = new JwtClaim(
    issuedAt: DateTime.now(),
    issuer: 'NewsAPP',
    expiry: DateTime.now().add(Duration(minutes: 5)),
    subject: 'News APP Authentication',
  );

  String token = issueJwtHS256(claimSet, jwtKey);
  print("token***********************$token");
  return token;
}

Map<String, String> get headers => {
      "Authorization": 'Bearer ' + getToken(),
    };
