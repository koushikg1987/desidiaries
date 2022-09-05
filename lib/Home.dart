import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flick_video_player/flick_video_player.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';

import 'package:http/http.dart' as http;

import 'package:intl/intl.dart';
import 'package:location/location.dart' as loc;
import 'package:location/location.dart';
import 'package:news/Bookmark.dart';
import 'package:news/Helper/Color.dart';
import 'package:news/Helper/Constant.dart';
import 'package:news/Helper/Session.dart';
import 'package:news/Helper/String.dart';
import 'package:news/Model/BreakingNews.dart';
import 'package:news/Model/News.dart';
import 'package:news/NewsTag.dart';
import 'package:news/NotificationList.dart';
import 'package:news/Search.dart';
import 'package:news/Profile.dart';
import 'package:news/category.dart';
import 'package:news/newsItem.dart';
import 'package:readmore/readmore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'Helper/PushNotificationService.dart';
import 'Live.dart';
import 'Login.dart';
import 'Model/Category.dart';
import 'Model/WeatherData.dart';
import 'NewsDetails.dart';
import 'SubHome.dart';
import 'main.dart';

class Home extends StatefulWidget {
  @override
  HomeState createState() => HomeState();
}

int _selectedIndex = 0;

class HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  List<Widget>? fragments;
  DateTime? currentBackPressTime;
  bool _isNetworkAvail = true;
  @override
  void initState() {
    super.initState();
    getUserDetails();
    initDynamicLinks();
    fragments = [
      HomePage(),
      Categoryy(),
      // Bookmark(),
      NotificationList(),
      Profile(),
    ];
    firNotificationInitialize();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getUserDetails() async {
    CUR_USERID = (await getPrefrence(ID)) ?? "";
    CATID = (await getPrefrence(cur_catId)) ?? "";

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);
    return WillPopScope(
        onWillPop: onWillPop,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: colors.bgColor,
          //extendBodyBehindAppBar: true,
          extendBody: true,
          bottomNavigationBar: bottomBar(),
          body: fragments?[_selectedIndex],
        ));
  }

  void firNotificationInitialize() {
    //for firebase push notification
    FlutterLocalNotificationsPlugin();
// initialise the plugin. ic_launcher needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true);
    final MacOSInitializationSettings initializationSettingsMacOS =
        MacOSInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            macOS: initializationSettingsMacOS);

    PushNotificationService.flutterLocalNotificationsPlugin.initialize(
        initializationSettings, onSelectNotification: (String? payload) async {
      if (payload != null && payload != "") {
        debugPrint('notification payload: $payload');
        getNewsById(payload);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyApp()),
        );
      }
    });
  }

  //when home page in back click press
  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (_selectedIndex != 0) {
      _selectedIndex = 0;

      return Future.value(false);
    } else if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      setSnackbar(getTranslated(context, 'EXIT_WR')!);

      return Future.value(false);
    }
    return Future.value(true);
  }

  _onItemTapped(index) async {
    setState(() {
      _selectedIndex = index;
    });
  }

  //when dynamic link share that's open in app used this function
  void initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLink) {
      final Uri? deepLink = dynamicLink.link;

      if (deepLink != null) {
        if (deepLink.queryParameters.length > 0) {
          String id = deepLink.queryParameters['id']!;
          getNewsById(id);
        }
      }
    }, onError: (e) async {
      print(e.message);
    });
  }

  updateParent() {
    //setState(() {});
  }

  //show snackbar msg
  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
      ),
      backgroundColor: isDark! ? colors.tempdarkColor : colors.bgColor,
      elevation: 1.0,
    ));
  }

  //when open dynamic link news index and id can used for fetch specific news
  Future<void> getNewsById(String id) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        NEWS_ID: id,
        ACCESS_KEY: access_key,
        USER_ID: CUR_USERID != null && CUR_USERID != "" ? CUR_USERID : "0"
      };
      http.Response response = await http
          .post(Uri.parse(getNewsByIdApi), body: param, headers: headers)
          .timeout(Duration(seconds: timeOut));
      var getdata = json.decode(response.body);
      log(getdata.toString());
      String error = getdata["error"];

      if (error == "false") {
        var data = getdata["data"];
        List<News> news = [];
        news = (data as List).map((data) => new News.fromJson(data)).toList();
        Navigator.of(context).push(MaterialPageRoute(
            builder: (BuildContext context) => NewsDetails(
                  model: news[0],
                  index: int.parse(id),
                  updateParent: updateParent,
                  id: news[0].id,
                  isFav: false,
                  isDetails: true,
                  news: [],
                  // updateHome: updateParent,
                )));
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg')!);
    }
  }

  bottomBar() {
    return Container(
        // padding: EdgeInsetsDirectional.only(
        //     start: 15.0, end: 15.0, bottom: 15.0, top: 10.0),
        child: Container(
            decoration: BoxDecoration(
              // borderRadius: BorderRadius.circular(10.0),
              // borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                    blurRadius: 10.0,
                    offset: const Offset(5.0, 5.0),
                    color:
                        Theme.of(context).colorScheme.fontColor.withOpacity(1),
                    spreadRadius: 1.0),
              ],
            ),
            child: ClipRRect(
              // borderRadius: BorderRadius.circular(10.0),
              child: BottomNavigationBar(
                showSelectedLabels: false,
                showUnselectedLabels: false,
                currentIndex: _selectedIndex,
                onTap: (int index) {
                  _onItemTapped(index);
                },
                backgroundColor: Theme.of(context).colorScheme.boxColor,
                type: BottomNavigationBarType.fixed,
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                      icon: SvgPicture.asset("assets/images/home_icon.svg",
                          semanticsLabel: 'home',
                          height: 20.0,
                          width: 20.0,
                          color: _selectedIndex == 0
                              ? colors.primary
                              : Theme.of(context).colorScheme.fontColor),
                      label: "Home"),
                  BottomNavigationBarItem(
                      // icon: Image.asset(
                      //   "assets/images/categoryyy.png",
                      // height: 20.0,
                      // width: 20.0,
                      // color: _selectedIndex == 1
                      //     ? colors.primary
                      //     : Theme.of(context).colorScheme.fontColor
                      // ),
                      icon: Icon(Icons.explore_outlined,
                          size: 25.0,
                          color: _selectedIndex == 1
                              ? colors.primary
                              : Theme.of(context).colorScheme.fontColor),
                      label: "Categoty"),
                  // BottomNavigationBarItem(
                  //     icon: SvgPicture.asset("assets/images/saved_icon.svg",
                  //         semanticsLabel: 'saved',
                  //         height: 20.0,
                  //         width: 20.0,
                  //         color: _selectedIndex == 2
                  //             ? colors.primary
                  //             : Theme.of(context).colorScheme.fontColor),
                  //     label: "Saved Bookmark"),
                  BottomNavigationBarItem(
                      icon: Icon(
                        Icons.notifications,
                        color: _selectedIndex == 2
                            ? colors.primary
                            : Theme.of(context).colorScheme.fontColor,
                      ),
                      label: "Notification"),
                  BottomNavigationBarItem(
                      icon: Icon(
                        Icons.person,
                        color: _selectedIndex == 3
                            ? colors.primary
                            : Theme.of(context).colorScheme.fontColor,
                      ),
                      label: "Setting"),
                ],
              ),
            )));
  }
}

List<News> recentNewsList = [];

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  List<News> tempList = [];
  List<Category> tempCatList = [];
  List<BreakingNewsModel> tempBreakList = [];
  List<BreakingNewsModel> breakingNewsList = [];
  WeatherData? weatherData;
  loc.Location _location = new loc.Location();
  String? error;
  bool? _serviceEnabled;
  PermissionStatus? _permissionGranted;
  final TextEditingController textController = TextEditingController();
  TabController? _tc;
  int offsetRecent = 0;
  int totalRecent = 0;
  int offsetUser = 0;
  int totalUser = 0;
  String? catId = "";
  bool _isRecentLoading = true;
  bool _isRecentLoadMore = true;
  bool _isLoading = true;
  bool _isNetworkAvail = true;
  int tcIndex = 0;

  var scrollController = ScrollController();
  List bookMarkValue = [];
  List<String> allImage = []; 

  String selectedCity = select;
  List<String> cityList = [select];

  int offset = 0;
  int total = 0;
  bool enabled = true;
  ScrollController controller = new ScrollController();
  ScrollController controller1 = new ScrollController();
  bool isTab = true;
  SubHome subHome = SubHome();

  bool errorrrr = false;
  String errorMessage = "";
  @override
  void initState() {

    controller.addListener(_scrollListener);

    callApi();

    super.initState();
  }

  Future<void> callApi() async {
    getSetting();

    await getCity();
    await getNews();
  }
  
  bool pageIsScrolling = false;
  final PageController pageController = PageController(); 

  @override
  Widget build(BuildContext context) {
    deviceWidth = MediaQuery.of(context).size.width;
    deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
        backgroundColor: colors.bgColor,
        key: _scaffoldKey,
        body: SafeArea(
          child: !errorrrr && recentNewsList.isEmpty
              ? newsShimmer2()
              : Stack(
                  children: [
                    errorrrr
                        ? Center(
                            child: Text(
                              errorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: deviceWidth! * 0.035),
                            ),
                          )
                        : 
                        PageView.builder(
                            controller: pageController,
                            itemCount: recentNewsList.length,
                            scrollDirection: Axis.vertical,
                            physics: BouncingScrollPhysics(),
                            pageSnapping: true,
                            onPageChanged: (_) {
                              setState(() {});
                            },
                            // physics: ClampingScrollPhysics(),
                            itemBuilder: (BuildContext context, int index) =>
                                NewsItem(
                              index: index,
                            ),
                          ),
                    pageController.positions.isNotEmpty &&
                            recentNewsList.isNotEmpty &&
                            !errorrrr &&
                            // pageController.page.toString().split(".").first == "0"
                            pageController.page == 0.0
                        ? Positioned(
                            top: deviceWidth! * 0.05,
                            left: deviceWidth! * 0.05,
                            child: Row(
                              children: [
                                // Text(pageController.page.toString().split(".").first),
                                Image.asset(
                                  "assets/images/onlycon.png",
                                  width: deviceWidth! * 0.07,
                                  height: deviceWidth! * 0.08,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                    margin: EdgeInsets.symmetric(
                                        horizontal: deviceWidth! * 0.03),
                                    child: DropdownButton<String>(
                                      value: selectedCity,
                                      dropdownColor: errorrrr
                                          ? Colors.white
                                          : Colors.black,
                                      items: cityList.map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(
                                              value.split(splitText).first,
                                              style: TextStyle(
                                                  color: errorrrr
                                                      ? Colors.black
                                                      : Colors.white,
                                                  fontSize:
                                                      deviceWidth! * 0.035)),
                                        );
                                      }).toList(),
                                      onChanged: (_) async {
                                        selectedCity = _!;
                                        offsetRecent = 0;
                                        totalRecent = 0;
                                        recentNewsList.clear();
                                        _isRecentLoading = true;
                                        setState(() {});
                                        await getNews();
                                        setState(() {});
                                      },
                                    ))
                              ],
                            ),
                          )
                        : errorrrr && recentNewsList.isEmpty
                            ? Positioned(
                                top: deviceWidth! * 0.05,
                                left: deviceWidth! * 0.05,
                                child: Row(
                                  children: [
                                    Image.asset(
                                      "assets/images/onlycon.png",
                                      width: deviceWidth! * 0.07,
                                      height: deviceWidth! * 0.08,
                                      fit: BoxFit.cover,
                                    ),
                                    Container(
                                        margin: EdgeInsets.symmetric(
                                            horizontal: deviceWidth! * 0.03),
                                        child: DropdownButton<String>(
                                          value: selectedCity,
                                          dropdownColor: errorrrr
                                              ? Colors.white
                                              : Colors.black,
                                          items: cityList.map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                  value.split(splitText).first,
                                                  style: TextStyle(
                                                      color: errorrrr
                                                          ? Colors.black
                                                          : Colors.white,
                                                      fontSize: deviceWidth! *
                                                          0.035)),
                                            );
                                          }).toList(),
                                          onChanged: (_) async {
                                            selectedCity = _!;
                                            offsetRecent = 0;
                                            totalRecent = 0;
                                            recentNewsList.clear();
                                            _isRecentLoading = true;
                                            setState(() {});
                                            await getNews();
                                            setState(() {});
                                          },
                                        ))
                                  ],
                                ),
                              )
                            : Container()
                  ],
                ),
 
        ));
  }
    
  updateHome() {
    setState(() {});
  }
 
  newsShimmer2() {
    return Shimmer.fromColors(
        baseColor: Colors.grey.withOpacity(0.6),
        highlightColor: Colors.grey,
        child: Container(
            height: deviceHeight,
            child: Stack(children: [
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Colors.grey.withOpacity(0.6)),
                height: deviceHeight,
                width: deviceWidth,
              ),
              Positioned.directional(
                  textDirection: Directionality.of(context),
                  bottom: 7.0,
                  start: 7,
                  end: 7,
                  height: deviceWidth! * 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Colors.grey,
                    ),
                  )),
            ])));
  }
 
//show snackbar msg
  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
      ),
      backgroundColor: isDark! ? colors.tempdarkColor : colors.bgColor,
      elevation: 1.0,
    ));
  }

//get settings api
  Future<void> getSetting() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var param = {
          ACCESS_KEY: access_key,
        };
        http.Response response = await http
            .post(Uri.parse(getSettingApi), body: param, headers: headers)
            .timeout(Duration(seconds: timeOut));
        if (response.statusCode == 200) {
          var getData = json.decode(response.body);
          String error = getData["error"];
          if (error == "false") {
            var data = getData["data"];
            category_mode = data[CATEGORY_MODE];
            comments_mode = data[COMM_MODE];
            breakingNews_mode = data[BREAK_NEWS_MODE];
            liveStreaming_mode = data[LIVE_STREAM_MODE];
            subCategory_mode = data[SUBCAT_MODE];
            if (data.toString().contains(FB_REWARDED_ID)) {
              fbRewardedVideoId = data[FB_REWARDED_ID];
            }
            if (data.toString().contains(FB_INTER_ID)) {
              fbInterstitialId = data[FB_INTER_ID];
            }
            if (data.toString().contains(FB_BANNER_ID)) {
              fbBannerId = data[FB_BANNER_ID];
            }
            if (data.toString().contains(FB_NATIVE_ID)) {
              fbNativeUnitId = data[FB_NATIVE_ID];
            }
            if (data.toString().contains(IOS_FB_REWARDED_ID)) {
              iosFbRewardedVideoId = data[IOS_FB_REWARDED_ID];
            }
            if (data.toString().contains(IOS_FB_INTER_ID)) {
              iosFbInterstitialId = data[IOS_FB_INTER_ID];
            }
            if (data.toString().contains(IOS_FB_BANNER_ID)) {
              iosFbBannerId = data[IOS_FB_BANNER_ID];
            }
            if (data.toString().contains(IOS_FB_NATIVE_ID)) {
              iosFbNativeUnitId = data[IOS_FB_NATIVE_ID];
            }

            if (data.toString().contains(GO_REWARDED_ID)) {
              goRewardedVideoId = data[GO_REWARDED_ID];
            }
            if (data.toString().contains(GO_INTER_ID)) {
              goInterstitialId = data[GO_INTER_ID];
            }
            if (data.toString().contains(GO_BANNER_ID)) {
              goBannerId = data[GO_BANNER_ID];
            }
            if (data.toString().contains(GO_NATIVE_ID)) {
              goNativeUnitId = data[GO_NATIVE_ID];
            }
            if (data.toString().contains(IOS_GO_REWARDED_ID)) {
              iosGoRewardedVideoId = data[IOS_GO_REWARDED_ID];
            }
            if (data.toString().contains(IOS_GO_INTER_ID)) {
              iosGoInterstitialId = data[IOS_GO_INTER_ID];
            }
            if (data.toString().contains(IOS_GO_BANNER_ID)) {
              iosGoBannerId = data[IOS_GO_BANNER_ID];
            }
            if (data.toString().contains(IOS_GO_NATIVE_ID)) {
              iosGoNativeUnitId = data[IOS_GO_NATIVE_ID];
            }
          }
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg')!);
    }
  }
 
  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (this.mounted) {
        setState(() {
          _isRecentLoadMore = true;

          if (offsetRecent < totalRecent) getNews();
        });
      }
    }
  }
 

//get latest news data list
  Future<void> getNews() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var param = {
          ACCESS_KEY: access_key,
          "city_id":
              selectedCity == select ? "" : selectedCity.split(splitText).last,
          LIMIT: perPage.toString(),
          OFFSET: offsetRecent.toString(),
          USER_ID: CUR_USERID != "" ? CUR_USERID : "0"
        };
        log(getNewsApi.toString());
        log(param.toString());
        http.Response response = await http
            .post(Uri.parse(getNewsApi), body: param, headers: headers)
            .timeout(Duration(seconds: timeOut));
        log(response.request!.headers.toString());
        log(response.request!.url.toString());
        /* if (response.statusCode == 200) {
          var getData = json.decode(response.body);
          String error = getData["error"];
          if (error == "false") {
            totalUser = int.parse(getData["total"]);
            if ((offsetUser) < totalUser) {
              tempList.clear();
              var data = getData["data"];
              tempList = (data as List)
                  .map((data) => new News.fromJson(data))
                  .toList();
              userNewsList.addAll(tempList);
              offsetUser = offsetUser + perPage;
            }
          } else {
            _isUserLoadMore = false;
          }
          if (mounted)
            setState(() {
              _isUserLoading = false;
            });
        }*/
        log("response: " + response.body.toString());

        if (response.statusCode == 200) {
          var getData = json.decode(response.body);

          String error = getData["error"];
          if (error == "false") {
            errorMessage = "";
            errorrrr = false;

            totalRecent = int.parse(getData["total"]);

            if ((offsetRecent) < totalRecent) {
              tempList.clear();
              var data = getData["data"];
              log("newsData" + response.body.toString());
              tempList = (data as List)
                  .map((data) => new News.fromJson(data))
                  .toList();

              recentNewsList.addAll(tempList);

              offsetRecent = offsetRecent + perPage;
            }
          } else {
            errorMessage = getData["message"];
            errorrrr = true;
            setState(() {});
            _isRecentLoadMore = false;
          }
          if (mounted)
            setState(() {
              _isRecentLoading = false;
            });
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
        setState(() {
          _isRecentLoading = false;
          _isRecentLoadMore = false;
        });
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg')!);
      setState(() {
        _isRecentLoading = false;
        _isRecentLoadMore = false;
      });
    }
  }

  Future<void> getCity() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var param = {
          ACCESS_KEY: access_key,
        };

        log(get_city.toString());
        log(param.toString());
        http.Response response = await http
            .post(Uri.parse(get_city), body: param, headers: headers)
            .timeout(Duration(seconds: timeOut));
        var getData = json.decode(response.body);
        // selectedCity
        cityList.clear();
        List tempList = getData["data"];
        cityList.add(select);
        if (tempList.isNotEmpty) {
          tempList.forEach((element) {
            cityList
                .add(element["name"] + splitText + element["id"].toString());
          });
        }
        // log("city: "+ getData.toString());
        if (mounted)
          setState(() {
            _isLoading = false;
          });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg')!);
      setState(() {
        _isLoading = false;
      });
    }
  }
  
}
 