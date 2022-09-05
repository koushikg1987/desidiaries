
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:news/Helper/Color.dart';
import 'package:news/Helper/Demo_Localization.dart';
import 'package:news/Helper/Session.dart';
import 'package:news/Helper/Theme.dart';
import 'package:news/Home.dart';
import 'package:news/Splash.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Helper/Constant.dart';
import 'Helper/PushNotificationService.dart';
import 'Helper/String.dart';
import 'Home.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
  SharedPreferences? prefs;
  void main() async {
  WidgetsFlutterBinding.ensureInitialized();
prefs = await SharedPreferences.getInstance();
  MobileAds.instance.initialize();
  await Firebase.initializeApp();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // status bar color
  ));

  runApp(
  //   MultiProvider(
  //     providers: [
  //       ChangeNotifierProvider<ThemeNotifier>(create: (BuildContext context) {
  //         String? theme = prefs!.getString(APP_THEME);
  //         if (theme == DARK) {
  //           isDark = true;
  //           prefs!.setString(APP_THEME, DARK);
  //         } else if (theme == LIGHT) {
  //           isDark = false;
  //           prefs!.setString(APP_THEME, LIGHT);
  //         }

  //         if (theme == null || theme == "" || theme == SYSTEM) {
  //           prefs!.setString(APP_THEME, SYSTEM);
  //           var brightness =
  //               SchedulerBinding.instance!.window.platformBrightness;
  //           isDark = brightness == Brightness.dark;

  //           return ThemeNotifier(ThemeMode.system);
  //         }
  //         return ThemeNotifier(
  //             theme == LIGHT ? ThemeMode.light : ThemeMode.dark);
  //       }),
  //     ],
  //     child: MyApp(),
  //   ),
  // );
   MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>(create: (BuildContext context) {
          String? theme = prefs!.getString(APP_THEME);
          if (theme == DARK) {
            // isDark = true;
            isDark = false;
            // prefs!.setString(APP_THEME, DARK);
            prefs!.setString(APP_THEME, LIGHT);
          } else if (theme == LIGHT) {
            isDark = false;
            prefs!.setString(APP_THEME, LIGHT);
          }

          if (theme == null || theme == "" || theme == SYSTEM) {
            // prefs!.setString(APP_THEME, SYSTEM);
            prefs!.setString(APP_THEME, LIGHT);
            var brightness =
                SchedulerBinding.instance.window.platformBrightness;
            // isDark = brightness == Brightness.dark;
            isDark = false;

            // return ThemeNotifier(ThemeMode.system);
            return ThemeNotifier(ThemeMode.light);
          }
          return ThemeNotifier(
              theme == LIGHT ? ThemeMode.light : ThemeMode.dark);
        }),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void initState() {
    Future<SharedPreferences> prefs = SharedPreferences.getInstance();
    prefs.then((value) {
      bool? noti = value.getBool(NOTIENABLE);
      if (noti == null || noti == true) {
        notiEnable = true;
        value.setBool(NOTIENABLE, true);
      } else {
        notiEnable = false;
        value.setBool(NOTIENABLE, false);
      }
    });

    super.initState();
  }

  @override
  void didChangeDependencies() {
    getLocale().then((locale) {
      setState(() {
        this._locale = locale;
      });
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    //notification service
    final pushNotificationService = PushNotificationService(_firebaseMessaging);
    pushNotificationService.initialise();
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    if (this._locale == null) {
      return Container(
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      return MaterialApp(
        locale: _locale,
        supportedLocales: [
          Locale("en", "US"),
          Locale("es", "ES"),
          Locale("hi", "IN"),
          Locale("tr", "TR"),
          Locale("pt", "PT"),
        ],
        localizationsDelegates: [
          DemoLocalization.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (locale, supportedLocales) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale!.languageCode &&
                supportedLocale.countryCode == locale.countryCode) {
              return supportedLocale;
            }
          }
          return supportedLocales.first;
        },
        title: appName,
        debugShowCheckedModeBanner: false,
         theme: ThemeData(
          primarySwatch: colors.primary_app,
          primaryColor: colors.primary,
          fontFamily: 'Neue Helvetica',
          canvasColor: colors.bgColor,
          brightness: Brightness.light,
        ),
        // darkTheme: ThemeData(
        //   fontFamily: 'Neue Helvetica',
        //   primarySwatch: colors.primary_app,
        //   primaryColor: colors.primary,
        //   brightness: Brightness.dark,
        //   canvasColor: colors.darkModeColor,
        // ),
        darkTheme:ThemeData(
          primarySwatch: colors.primary_app,
          primaryColor: colors.primary,
          fontFamily: 'Neue Helvetica',
          canvasColor: colors.bgColor,
          brightness: Brightness.light,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => Splash(),
          '/home': (context) => Home(),
        },
        themeMode: themeNotifier.getThemeMode(),
      );
    }
  }
}
