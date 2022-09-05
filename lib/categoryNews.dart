import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

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
import 'package:readmore/readmore.dart';
import 'package:shimmer/shimmer.dart';
import 'Helper/PushNotificationService.dart';
import 'Live.dart';
import 'Login.dart';
import 'Model/Category.dart';
import 'Model/WeatherData.dart';
import 'NewsDetails.dart';
import 'SubHome.dart';
import 'main.dart';

class CategoryNews extends StatefulWidget {
  final String categoryId;

  const CategoryNews({Key? key, required this.categoryId}) : super(key: key);
  @override
  CategoryNewsState createState() => CategoryNewsState();
}

class CategoryNewsState extends State<CategoryNews>
    with TickerProviderStateMixin {
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
  List<Map<String, dynamic>> _tabs = [];
  List<News> recentNewsList = [];
  List<News> recenttempList = [];
  List<News> tempUserNews = [];
  List<News> userNewsList = [];
  bool _isBreakLoading = true;
  bool _isUserLoading = true;
  bool _isUserLoadMore = true;
  bool _isRecentLoading = true;
  bool _isRecentLoadMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = true;
  bool _isNetworkAvail = true;
  bool weatherLoad = true;
  List<Category> catList = [];
  int tcIndex = 0;

  var scrollController = ScrollController();
  List bookMarkValue = [];
  List<News> bookmarkList = [];
  List<String> allImage = [];
  final _pageController = PageController();
  int _curSlider = 0;
  int? selectSubCat = 0;

  bool isFirst = false;
  var isliveNews;

  List<News> newsList = [];
  List<News> tempNewsList = [];

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
    loadWeather();

    controller.addListener(_scrollListener);
    controller1.addListener(_scrollListener1);

    callApi();

    super.initState();
  }

  Future<void> callApi() async {
    getSetting();
    await getLiveNews();
    await getBreakingNews();
    await getNews();
    await getUserByCatNews();
    await getCat();
    await _getBookmark();
  }

  //get user selected category newslist
  Future<void> getUserByCatNews() async {
    if (CUR_USERID != "" && CATID != "") {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          var param = {
            ACCESS_KEY: access_key,
            CATEGORY_ID: CATID,
            USER_ID: CUR_USERID,
            LIMIT: perPage.toString(),
            OFFSET: offsetUser.toString(),
          };
          http.Response response = await http
              .post(Uri.parse(getNewsByUserCatApi),
                  body: param, headers: headers)
              .timeout(Duration(seconds: timeOut));
          if (response.statusCode == 200) {
            var getData = json.decode(response.body);
            String error = getData["error"];
            if (error == "false") {
              totalUser = int.parse(getData["total"]);
              if ((offsetUser) < totalUser) {
                tempUserNews.clear();
                var data = getData["data"];
                tempUserNews = (data as List)
                    .map((data) => new News.fromJson(data))
                    .toList();
                userNewsList.addAll(tempUserNews);
                offsetUser = offsetUser + perPage;
              }
            } else {
              _isUserLoadMore = false;
            }
            if (mounted)
              setState(() {
                _isUserLoading = false;
              });
          }
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!);
          setState(() {
            _isUserLoading = false;
            _isUserLoadMore = false;
          });
        }
      } else {
        setSnackbar(getTranslated(context, 'internetmsg')!);
        setState(() {
          _isUserLoading = false;
          _isUserLoadMore = false;
        });
      }
    }
  }

  //set bookmark of news using api
  _setBookmark(String status, String id) async {
    if (bookMarkValue.contains(id)) {
      setState(() {
        bookMarkValue = List.from(bookMarkValue)..remove(id);
      });
    } else {
      setState(() {
        bookMarkValue = List.from(bookMarkValue)..add(id);
      });
    }

    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
        USER_ID: CUR_USERID,
        NEWS_ID: id,
        STATUS: status,
      };

      http.Response response = await http
          .post(Uri.parse(setBookmarkApi), body: param, headers: headers)
          .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      String error = getdata["error"];

      String msg = getdata["message"];

      if (error == "false") {
        if (status == "0") {
          setSnackbar(msg);
        } else {
          setSnackbar(msg);
        }
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg')!);
    }
  }

  //add tab bar category title
  _addInitailTab() async {
    setState(() {
      for (int i = 0; i < catList.length; i++) {
        _tabs.add({
          'text': catList[i].categoryName,
        });
        catId = catList[i].id;
      }

      _tc = TabController(
        vsync: this,
        length: _tabs.length,
      )..addListener(() {
          setState(() {
            isTab = true;

            tcIndex = _tc!.index;
            selectSubCat = 0;
          });
        });
    });
  }

  catShimmer() {
    return Container(
        child: Shimmer.fromColors(
            baseColor: Colors.grey.withOpacity(0.4),
            highlightColor: Colors.grey.withOpacity(0.4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  children: [0, 1, 2, 3, 4, 5, 6]
                      .map((i) => Padding(
                          padding: EdgeInsetsDirectional.only(
                              start: i == 0 ? 0 : 15),
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: Colors.grey),
                            height: 32.0,
                            width: 110.0,
                          )))
                      .toList()),
            )));
  }

  tabBarData() {
    return TabBar(
      //indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: Theme.of(context).textTheme.subtitle1?.copyWith(
            fontWeight: FontWeight.w600,
          ),
      unselectedLabelColor:
          Theme.of(context).colorScheme.fontColor.withOpacity(0.8),
      isScrollable: true,
      indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          // Creates border
          color: colors.primary.withOpacity(0.08)),
      tabs: _tabs
          .map((tab) => Container(
              height: 32,
              padding: EdgeInsetsDirectional.only(top: 5.0, bottom: 5.0),
              child: Tab(
                text: tab['text'],
              )))
          .toList(),
      labelColor: colors.primary,
      controller: _tc,
      unselectedLabelStyle: Theme.of(context).textTheme.subtitle1?.copyWith(),
    );
  }

  subTabData() {
    return catList.length != 0
        ? catList[_tc!.index].subData!.length != 0
            ? Padding(
                padding: EdgeInsetsDirectional.only(top: 10.0),
                child: Container(
                    height: 27,
                    alignment: Alignment.center,
                    child: ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: catList[_tc!.index].subData!.length,
                        itemBuilder: (context, index) {
                          return Padding(
                              padding: EdgeInsetsDirectional.only(
                                  start: index == 0 ? 0 : 10),
                              child: InkWell(
                                child: Container(
                                    alignment: Alignment.center,
                                    padding: EdgeInsetsDirectional.only(
                                        start: 7.0,
                                        end: 7.0,
                                        top: 2.5,
                                        bottom: 2.5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color: selectSubCat == index
                                          ? colors.primary.withOpacity(0.07)
                                          : Theme.of(context)
                                              .colorScheme
                                              .fontColor
                                              .withOpacity(0.13),
                                    ),
                                    child: Text(
                                      catList[_tc!.index]
                                          .subData![index]
                                          .subCatName!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle2
                                          ?.copyWith(
                                              color: selectSubCat == index
                                                  ? colors.primary
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .fontColor
                                                      .withOpacity(0.9),
                                              fontSize: 12,
                                              fontWeight: selectSubCat == index
                                                  ? FontWeight.w600
                                                  : FontWeight.normal),
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                    )),
                                onTap: () async {
                                  this.setState(() {
                                    isTab = false;
                                    selectSubCat = index;

                                    if (index == 0) {
                                      subHome = SubHome(
                                        subCatId: "0",
                                        curTabId: catList[tcIndex].id!,
                                        index: tcIndex,
                                        isSubCat: true,
                                        catList: catList,
                                        scrollController: scrollController,
                                      );
                                    } else {
                                      subHome = SubHome(
                                        subCatId: catList[tcIndex]
                                            .subData![index]
                                            .id!,
                                        curTabId: "0",
                                        index: tcIndex,
                                        isSubCat: true,
                                        catList: catList,
                                        scrollController: scrollController,
                                      );
                                    }
                                  });
                                },
                              ));
                        })))
            : Container()
        : Container();
  }

  bool pageIsScrolling = false;
  final PageController pageController = PageController();
  void _onScroll(double offset) {
    if (pageIsScrolling == false) {
      pageIsScrolling = true;
      if (offset > 0) {
        pageController
            .nextPage(
                duration: Duration(milliseconds: 300), curve: Curves.easeInOut)
            .then((value) => pageIsScrolling = false);

        print('scroll down');
      } else {
        pageController
            .previousPage(
                duration: Duration(milliseconds: 300), curve: Curves.easeInOut)
            .then((value) => pageIsScrolling = false);
        print('scroll up');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    deviceWidth = MediaQuery.of(context).size.width;
    deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
        backgroundColor: colors.bgColor,
        key: _scaffoldKey,
        body: SafeArea(
          child: !errorrrr && recentNewsList.isEmpty
              ? newsShimmer()
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
                        // GestureDetector(
                        //     onPanUpdate: (details) {
                        //       _onScroll(details.delta.dy * -1);
                        //     },
                        //     child: Listener(
                        //       onPointerSignal: (pointerSignal) {
                        //         if (pointerSignal is PointerScrollEvent) {
                        //           _onScroll(pointerSignal.scrollDelta.dy);
                        //           setState(() {});
                        //         }
                        //       },
                        //       child: PageView.builder(
                        //         controller: pageController,
                        //         itemCount: recentNewsList.length,
                        //         scrollDirection: Axis.vertical,
                        //         physics: NeverScrollableScrollPhysics(),
                        //         pageSnapping: true,
                        //         onPageChanged: (_) {
                        //           setState(() {});
                        //         },
                        //         // physics: ClampingScrollPhysics(),
                        //         itemBuilder: (BuildContext context, int index) =>
                        //             itemView(index),
                        //       ),
                        //     ),
                        //   ),
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
                                itemView(index),
                          ),
                  ],
                ),

          // child: Padding(
          //     padding: EdgeInsetsDirectional.only(
          //         top: 10.0, start: 15.0, end: 15.0, bottom: 10.0),
          //     child: NestedScrollView(
          //         physics: BouncingScrollPhysics(
          //             parent: AlwaysScrollableScrollPhysics()),
          //         controller: scrollController,
          //         headerSliverBuilder:
          //             (BuildContext context, bool innerBoxIsScrolled) {
          //           return <Widget>[
          //             new SliverList(
          //               delegate: new SliverChildListDelegate([
          //                 // weatherDataView(),
          //                 liveWithSearchView(),
          //                 // viewBreakingNews(),
          //                 viewRecentContent(),
          //                 CUR_USERID != "" &&
          //                         CATID != "" &&
          //                         userNewsList.length > 0
          //                     ? viewUserNewsContent()
          //                     : Container(),
          //                 catText(),
          //               ]),
          //             ),
          //             SliverAppBar(
          //               toolbarHeight: 0,
          //               titleSpacing: 0,
          //               pinned: true,
          //               bottom: catList.length != 0
          //                   ? PreferredSize(
          //                       preferredSize: Size.fromHeight(
          //                           catList[_tc!.index].subData!.length != 0
          //                               ? 71
          //                               : 34),
          //                       child: Column(
          //                           children: [tabBarData(), subTabData()]))
          //                   : PreferredSize(
          //                       preferredSize: Size.fromHeight(34),
          //                       child: catShimmer()),
          //               backgroundColor:
          //                   isDark! ? colors.darkModeColor : colors.bgColor,
          //               elevation: 0,
          //               floating: true,
          //             )
          //           ];
          //         },
          //         body: catList.length != 0
          //             ? TabBarView(
          //                 controller: _tc,
          //                 //key: _key,
          //                 children: new List<Widget>.generate(_tc!.length,
          //                     (int index) {
          //                   //return viewContent();
          //                   return isTab
          //                       ? SubHome(
          //                           curTabId: catList[index].id,
          //                           isSubCat: false,
          //                           scrollController: scrollController,
          //                           catList: catList,
          //                           subCatId: "0",
          //                           index: index,
          //                         )
          //                       : subHome;
          //                 }))
          //             : contentShimmer(context)))
        ));
  }

  Widget itemView(int index) {
    List<String> tagList = [];
    DateTime time1 = DateTime.parse(recentNewsList[index].date!);
    if (recentNewsList[index].tagName! != "") {
      final tagName = recentNewsList[index].tagName!;
      tagList = tagName.split(',');
    }

    List<String> tagId = [];

    if (recentNewsList[index].tagId! != "") {
      tagId = recentNewsList[index].tagId!.split(",");
    }

    allImage.clear();

    allImage.add(recentNewsList[index].image!);
    if (recentNewsList[index].imageDataList!.length != 0) {
      for (int i = 0; i < recentNewsList[index].imageDataList!.length; i++) {
        allImage.add(recentNewsList[index].imageDataList![i].otherImage!);
      }
    }
    return InkWell(
      onTap: () {
        News model = recentNewsList[index];
        List<News> recList = [];
        recList.addAll(recentNewsList);
        recList.removeAt(index);
        Navigator.of(context).push(MaterialPageRoute(
            builder: (BuildContext context) => NewsDetails(
                  model: model,
                  index: index,
                  updateParent: updateHomePage,
                  id: model.id,
                  isFav: false,
                  isDetails: true,
                  news: recList,
                )));
      },
      child: Container(
          width: deviceWidth,
          height: deviceHeight,
          // margin: EdgeInsets.symmetric(vertical: deviceWidth! * 0.005),
          child: Stack(
            children: [
              Container(
                width: deviceWidth,
                height: deviceHeight,
                child: ClipRRect(
                    // borderRadius: BorderRadius.circular(10.0),
                    child: FadeInImage(
                        fadeInDuration: Duration(milliseconds: 150),
                        image: CachedNetworkImageProvider(
                            recentNewsList[index].image!),
                        height: 250.0,
                        width: 450.0,
                        fit: BoxFit.cover,
                        imageErrorBuilder: (context, error, stackTrace) =>
                            errorWidget(250, 450),
                        placeholder: AssetImage(
                          placeHolder,
                        ))),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                          child: Container(
                              // height: deviceWidth! * 0.4,
                              padding: EdgeInsets.only(left: 20.0),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                        margin: EdgeInsets.symmetric(
                                            vertical: deviceWidth! * 0.0),
                                        child: Text(
                                          recentNewsList[index].title!,
                                          textAlign: TextAlign.start,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2
                                              ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: deviceWidth! * 0.05,
                                                  height: 1.0),
                                          maxLines: 3,
                                          softWrap: true,
                                          overflow: TextOverflow.ellipsis,
                                        )),
                                    IgnorePointer(
                                      child: Container(
                                        // height: deviceWidth! * 0.15,

                                        margin: EdgeInsets.symmetric(
                                            vertical: deviceWidth! * 0.025),
                                        child: ReadMoreText(
                                          recentNewsList[index].desc!,
                                          trimLines: 2,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2
                                              ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize:
                                                      deviceWidth! * 0.035,
                                                  height: 1.0),
                                          textAlign: TextAlign.start,
                                          trimMode: TrimMode.Line,
                                          colorClickableText: Colors.white,
                                          trimCollapsedText: 'Read more',
                                          trimExpandedText: 'Read more',
                                          lessStyle: TextStyle(
                                              fontSize: deviceWidth! * 0.04,
                                              fontWeight: FontWeight.bold),
                                          moreStyle: TextStyle(
                                              fontSize: deviceWidth! * 0.04,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        // child: Html(
                                        //   data: recentNewsList[index].desc!,
                                        //   shrinkWrap: true,
                                        //   style: {
                                        //     // tables will have the below background color
                                        //     "div": Style(
                                        //       color: Colors.white,
                                        //     ),
                                        //     "p": Style(
                                        //       color: Colors.white,
                                        //     ),
                                        //     "b ": Style(
                                        //       color: Colors.white,
                                        //     ),
                                        //   },
                                        // )
                                      ),
                                    ),
                                    SizedBox(
                                      height: 15,
                                    ),
                                    Row(children: [
                                      // Icon(
                                      //   Icons.person,
                                      //   size: 15.0,
                                      //   color: Colors.white,
                                      // ),
                                      // Container(
                                      //   margin: EdgeInsets.symmetric(
                                      //       horizontal: deviceWidth! * 0.03),
                                      //   child: Text("Creator Name",
                                      //       style: TextStyle(
                                      //           color: Colors.white,
                                      //           fontSize: 14.0)),
                                      // ),
                                      // Container(
                                      //   margin: EdgeInsets.only(
                                      //       right: deviceWidth! * 0.03),
                                      //   child: Text(
                                      //     convertToAgo(time1, 0)!,
                                      //     style: Theme.of(context)
                                      //         .textTheme
                                      //         .caption
                                      //         ?.copyWith(
                                      //             color: Colors.white,
                                      //             fontSize: 10.0),
                                      //   ),
                                      // )
                                      Container(
                                        margin: EdgeInsets.only(
                                            right: deviceWidth! * 0.03),
                                        child: Row(
                                          children: [
                                            Container(
                                              child: Image.asset(
                                                "assets/images/onlycon.png",
                                                height: deviceWidth! * 0.05,
                                                width: deviceWidth! * 0.05,
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(
                                                  left: deviceWidth! * 0.03,
                                                  right: deviceWidth! * 0.01),
                                              child: Text(
                                                "Desi Diaries",
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                            Text(
                                              " ( " +
                                                  convertToAgo(time1, 0)! +
                                                  " )",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .caption
                                                  ?.copyWith(
                                                      color: Colors.white,
                                                      fontSize: 10.0),
                                            ),
                                            Text(
                                              " ( " +
                                                  (recentNewsList[index]
                                                      .totalLikes = (int.parse(
                                                              recentNewsList[
                                                                      index]
                                                                  .totalLikes!) +
                                                          1)
                                                      .toString()) +
                                                  " ) ",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .caption
                                                  ?.copyWith(
                                                      color: Colors.white,
                                                      fontSize: 10.0),
                                            ),
                                          ],
                                        ),
                                      )
                                    ]),
                                    SizedBox(
                                      height: 10,
                                    ),
                                  ]))),
                      Container(
                        width: 100.0,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          InkWell(
                            onTap: () async {
                              _isNetworkAvail = await isNetworkAvailable();

                              if (CUR_USERID != "") {
                                if (_isNetworkAvail) {
                                  if (!isFirst) {
                                    setState(() {
                                      isFirst = true;
                                    });
                                    if (recentNewsList[index].like == "1") {
                                      _setLikesDisLikes("0",
                                          recentNewsList[index].id!, index, 1);

                                      setState(() {});
                                    } else {
                                      _setLikesDisLikes("1",
                                          recentNewsList[index].id!, index, 1);
                                      setState(() {});
                                    }
                                  } else {
                                    setSnackbar(
                                        getTranslated(context, 'internetmsg')!);
                                  }
                                } else {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Login(),
                                      ));
                                }
                              }
                            },
                            child: Container(
                                margin: EdgeInsets.only(top: 15.0),
                                width: 60.0,
                                height: 60.0,
                                child: Column(children: [
                                  SvgPicture.asset(
                                    recentNewsList[index].like == "1"
                                        ? "assets/images/likefilled_button.svg"
                                        : "assets/images/Like_icon.svg",
                                    semanticsLabel: 'like icon',
                                    color: Colors.white,
                                    height: 30,
                                    width: 30,
                                  ),
                                  // Padding(
                                  //   padding: EdgeInsets.only(top: 8.0),
                                  //   child: Text("Like",
                                  //       style: TextStyle(
                                  //           color: Colors.white,
                                  //           fontWeight: FontWeight.w500,
                                  //           fontSize: 14.0)),
                                  // )
                                ])),
                          ),

                          Container(
                              margin: EdgeInsets.only(top: 15.0),
                              width: 60.0,
                              height: 60.0,
                              child: Column(children: [
                                SvgPicture.asset(
                                  "assets/images/comment_icon.svg",
                                  semanticsLabel: 'comment',
                                  color: Colors.white,
                                  height: 30,
                                  width: 30,
                                ),
                                // Padding(
                                //   padding: EdgeInsets.only(top: 8.0),
                                //   child: Text("Comment",
                                //       style: TextStyle(
                                //           color: Colors.white,
                                //           fontWeight: FontWeight.w500,
                                //           fontSize: 14.0)),
                                // )
                              ])),

                          InkWell(
                            onTap: () async {
                              _isNetworkAvail = await isNetworkAvailable();
                              if (_isNetworkAvail) {
                                createDynamicLink(recentNewsList[index].id!,
                                    index, recentNewsList[index].title!);
                              } else {
                                setSnackbar(
                                    getTranslated(context, 'internetmsg')!);
                              }
                            },
                            child: Container(
                                margin: EdgeInsets.only(top: 15.0),
                                width: 60.0,
                                height: 60.0,
                                child: Column(children: [
                                  SvgPicture.asset(
                                    "assets/images/share_icon.svg",
                                    semanticsLabel: 'share icon',
                                    color: Colors.white,
                                    height: 30,
                                    width: 30,
                                  ),
                                  // Padding(
                                  //   padding: EdgeInsets.only(top: 8.0),
                                  //   child: Text("Share",
                                  //       style: TextStyle(
                                  //           color: Colors.white,
                                  //           fontWeight: FontWeight.w500,
                                  //           fontSize: 14.0)),
                                  // )
                                ])),
                          ),
                          InkWell(
                            onTap: () async {
                              _isNetworkAvail = await isNetworkAvailable();
                              if (CUR_USERID != "") {
                                if (_isNetworkAvail) {
                                  setState(() {
                                    bookMarkValue
                                            .contains(recentNewsList[index].id!)
                                        ? _setBookmark(
                                            "0", recentNewsList[index].id!)
                                        : _setBookmark(
                                            "1", recentNewsList[index].id!);
                                  });
                                } else {
                                  setSnackbar(
                                      getTranslated(context, 'internetmsg')!);
                                }
                              } else {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Login(),
                                    ));
                              }
                            },
                            child: Container(
                                margin: EdgeInsets.only(top: 15.0),
                                width: 60.0,
                                height: 60.0,
                                child: Column(children: [
                                  SvgPicture.asset(
                                    bookMarkValue
                                            .contains(recentNewsList[index].id)
                                        ? "assets/images/bookmarkfilled_icon.svg"
                                        : "assets/images/bookmark_icon.svg",
                                    semanticsLabel: 'bookmark_icon',
                                    color: Colors.white,
                                    height: 30,
                                    width: 30,
                                  ),
                                  // Padding(
                                  //   padding: EdgeInsets.only(top: 8.0),
                                  //   child: Text("Bookmark",
                                  //       style: TextStyle(
                                  //           color: Colors.white,
                                  //           fontWeight: FontWeight.w500,
                                  //           fontSize: 14.0)),
                                  // )
                                ])),
                          )

                          // CircleImageAnimation(
                          //   child: _getMusicPlayerAction(userPic),
                          // )
                        ]),
                      )
                    ],
                  ),
                  SizedBox(height: 20)
                ],
              ),
            ],
          )),
    );
  }

  Widget _getSocialAction(
      {required String title, required IconData icon, bool isShare = false}) {
    return Container(
        margin: EdgeInsets.only(top: 15.0),
        width: 60.0,
        height: 60.0,
        child: Column(children: [
          Icon(icon, size: isShare ? 25.0 : 35.0, color: Colors.grey[300]),
          Padding(
            padding: EdgeInsets.only(top: isShare ? 8.0 : 8.0),
            child: Text(title,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: isShare ? 14.0 : 14.0)),
          )
        ]));
  }

  Widget weatherDataView() {
    DateTime now = DateTime.now();
    String day = DateFormat('EEEE').format(now);
    return !weatherLoad
        ? Container(
            padding: EdgeInsets.all(15.0),
            height: 110,
            //width: deviceWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              color: Theme.of(context).colorScheme.lightColor,
              boxShadow: [
                BoxShadow(
                    blurRadius: 10.0,
                    offset: const Offset(12.0, 15.0),
                    color: colors.tempdarkColor.withOpacity(0.2),
                    spreadRadius: -7),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Column(
                    children: <Widget>[
                      Text(
                        getTranslated(context, 'weather_lbl')!,
                        style: Theme.of(this.context)
                            .textTheme
                            .subtitle2
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .fontColor
                                  .withOpacity(0.8),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                      weatherData != null
                          ? Row(
                              children: <Widget>[
                                Image.network(
                                  "https:${weatherData!.icon!}",
                                  width: 40.0,
                                  height: 40.0,
                                ),
                                Padding(
                                    padding:
                                        EdgeInsetsDirectional.only(start: 7.0),
                                    child: Text(
                                      "${weatherData!.tempC!.toString()}\u2103",
                                      style: Theme.of(this.context)
                                          .textTheme
                                          .headline6
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor
                                                .withOpacity(0.8),
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                      maxLines: 1,
                                    ))
                              ],
                            )
                          : Container()
                    ],
                  ),
                ),
                Spacer(),
                weatherData != null
                    ? Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              "${weatherData!.name!},${weatherData!.region!},${weatherData!.country!}",
                              style: Theme.of(this.context)
                                  .textTheme
                                  .subtitle2
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                      fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              maxLines: 1,
                            ),
                            Padding(
                                padding: EdgeInsetsDirectional.only(top: 3.0),
                                child: Text(
                                  day,
                                  style: Theme.of(this.context)
                                      .textTheme
                                      .caption
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor
                                            .withOpacity(0.8),
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  maxLines: 1,
                                )),
                            Padding(
                                padding: EdgeInsetsDirectional.only(top: 3.0),
                                child: Text(
                                  weatherData!.text!,
                                  style: Theme.of(this.context)
                                      .textTheme
                                      .caption
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor
                                            .withOpacity(0.8),
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                )),
                            Padding(
                                padding: EdgeInsetsDirectional.only(top: 3.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    Icon(Icons.arrow_upward_outlined,
                                        size: 13.0,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor),
                                    Text(
                                      "H:${weatherData!.maxTempC!.toString()}\u2103",
                                      style: Theme.of(this.context)
                                          .textTheme
                                          .caption
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor
                                                .withOpacity(0.8),
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                    ),
                                    Padding(
                                        padding: EdgeInsetsDirectional.only(
                                            start: 8.0),
                                        child: Icon(
                                            Icons.arrow_downward_outlined,
                                            size: 13.0,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor)),
                                    Text(
                                      "L:${weatherData!.minTempC!.toString()}\u2103",
                                      style: Theme.of(this.context)
                                          .textTheme
                                          .caption
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor
                                                .withOpacity(0.8),
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                    ),
                                  ],
                                ))
                          ],
                        ),
                      )
                    : Container()
              ],
            ))
        : weatherShimmer();
  }

  weatherShimmer() {
    return Shimmer.fromColors(
        baseColor: Colors.grey.withOpacity(0.4),
        highlightColor: Colors.grey.withOpacity(0.4),
        child: Container(
          height: 98,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: Theme.of(context).colorScheme.lightColor,
          ),
        ));
  }

  //get live news video
  Future<void> getLiveNews() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var parameter = {ACCESS_KEY: access_key};

      http.Response response = await http
          .post(Uri.parse(getLiveStreamingApi),
              body: parameter, headers: headers)
          .timeout(Duration(seconds: timeOut));
      var getdata = json.decode(response.body);
      String error = getdata["error"];

      if (error == "false") {
        isliveNews = getdata["data"];
      } else {
        isliveNews = "";
      }
    } else
      setSnackbar(getTranslated(context, 'internetmsg')!);
  }

  Widget liveWithSearchView() {
    return Padding(
        padding: EdgeInsets.only(top: 20.0),
        child: Row(
          children: [
            liveStreaming_mode == "1" && isliveNews != "" && isliveNews != null
                ? Expanded(
                    flex: 9,
                    child: InkWell(
                      child: Padding(
                          padding: EdgeInsetsDirectional.only(end: 0.0),
                          child: Container(
                              height: 60,
                              // width: _folded ? deviceWidth! - 120 : 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: Theme.of(context).colorScheme.lightColor,
                                boxShadow: [
                                  BoxShadow(
                                      blurRadius: 10.0,
                                      offset: const Offset(12.0, 15.0),
                                      color:
                                          colors.tempdarkColor.withOpacity(0.2),
                                      spreadRadius: -7),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    "assets/images/live_news.svg",
                                    semanticsLabel: 'live news',
                                    height: 21.0,
                                    width: 21.0,
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                  ),
                                  Padding(
                                      padding: EdgeInsetsDirectional.only(
                                          start: 8.0),
                                      child: Text(
                                        getTranslated(context, 'liveNews')!,
                                        style: Theme.of(this.context)
                                            .textTheme
                                            .subtitle1
                                            ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .fontColor,
                                                fontWeight: FontWeight.w600),
                                      ))
                                ],
                              ))),
                      onTap: () {
                        if (_isNetworkAvail) {
                          if (isliveNews != "" && isliveNews != null) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Live(
                                    liveNews: isliveNews,
                                  ),
                                ));
                          }
                        } else {
                          setSnackbar(getTranslated(context, 'internetmsg')!);
                        }
                      },
                    ))
                : Container(),
            liveStreaming_mode == "1" && isliveNews != "" && isliveNews != null
                ? Expanded(
                    flex: 3,
                    child: Padding(
                        padding: EdgeInsetsDirectional.only(start: 10.0),
                        child: InkWell(
                          child: Container(
                              alignment: Alignment.center,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: Theme.of(context).colorScheme.lightColor,
                                boxShadow: [
                                  BoxShadow(
                                      blurRadius: 10.0,
                                      offset: const Offset(12.0, 15.0),
                                      color:
                                          colors.tempdarkColor.withOpacity(0.2),
                                      spreadRadius: -7),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsetsDirectional.only(start: 0.0),
                                child: SvgPicture.asset(
                                  "assets/images/search_icon.svg",
                                  height: 18,
                                  width: 18,
                                  color:
                                      Theme.of(context).colorScheme.fontColor,
                                ),
                              )),
                          onTap: () {
                            // setState(() {
                            // _folded = !_folded;
                            //});
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) => Search()));
                          },
                        )))
                : InkWell(
                    child: Container(
                      width: deviceWidth! - 30,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                              alignment: Alignment.center,
                              height: 60,
                              child: Image.asset(
                                "assets/images/splash_Icon.png",
                              )),
                          Container(
                              alignment: Alignment.center,
                              height: 60,
                              width: 60,
                              // width: deviceWidth! - 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: Theme.of(context).colorScheme.lightColor,
                                boxShadow: [
                                  BoxShadow(
                                      blurRadius: 10.0,
                                      offset: const Offset(12.0, 15.0),
                                      color:
                                          colors.tempdarkColor.withOpacity(0.2),
                                      spreadRadius: -7),
                                ],
                              ),
                              child: Padding(
                                  padding:
                                      EdgeInsetsDirectional.only(start: 0.0),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          "assets/images/search_icon.svg",
                                          height: 18,
                                          width: 18,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor,
                                        ),
                                      ]))),
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) => Search()));
                    },
                  )
          ],
        ));
  }

  updateHome() {
    setState(() {});
  }

  loadWeather() async {
    loc.LocationData locationData;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled!) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled!) {
        return;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    locationData = await _location.getLocation();

    error = null;

    final lat = locationData.latitude;
    final lon = locationData.longitude;
    final weatherResponse = await http.get(Uri.parse(
        'https://api.weatherapi.com/v1/forecast.json?key=d0f2f4dbecc043e78d6123135212408&q=${lat.toString()},${lon.toString()}&days=1&aqi=no&alerts=no'));

    if (weatherResponse.statusCode == 200) {
      if (this.mounted)
        return setState(() {
          weatherData =
              new WeatherData.fromJson(jsonDecode(weatherResponse.body));
          weatherLoad = false;
        });
    }

    setState(() {
      weatherLoad = false;
    });
  }

  Widget viewBreakingNews() {
    return Padding(
        padding: EdgeInsetsDirectional.only(
          top: 15.0,
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: EdgeInsetsDirectional.only(start: 8.0),
                  child: Text(
                    getTranslated(context, 'breakingNews_lbl')!,
                    style: Theme.of(context).textTheme.subtitle1?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .fontColor
                            .withOpacity(0.9),
                        fontWeight: FontWeight.w600),
                  )),
              _isBreakLoading
                  ? newsShimmer()
                  : breakingNewsList.length == 0
                      ? Center(
                          child: Text(
                              getTranslated(context, 'breaking_not_avail')!,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.8))))
                      : SizedBox(
                          height: 250.0,
                          child: ListView.builder(
                            physics: AlwaysScrollableScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            itemCount: breakingNewsList.length,
                            itemBuilder: (context, index) {
                              return breakingNewsItem(index);
                            },
                          ))
            ]));
  }

  Widget viewRecentContent() {
    return Padding(
        padding: EdgeInsetsDirectional.only(
          top: 15.0,
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: EdgeInsetsDirectional.only(start: 8.0),
                  child: Text(
                    getTranslated(context, 'recentNews_lbl')!,
                    style: Theme.of(context).textTheme.subtitle1?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .fontColor
                            .withOpacity(0.9),
                        fontWeight: FontWeight.w600),
                  )),
              _isRecentLoading
                  ? newsShimmer()
                  : recentNewsList.length == 0
                      ? Center(
                          child: Text(getTranslated(context, 'recent_no_news')!,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.8))))
                      : SizedBox(
                          height: 250.0,
                          child: ListView.builder(
                            physics: AlwaysScrollableScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            controller: controller,
                            itemCount: (offsetRecent < totalRecent)
                                ? recentNewsList.length + 1
                                : recentNewsList.length,
                            itemBuilder: (context, index) {
                              return (index == recentNewsList.length &&
                                      _isRecentLoadMore)
                                  ? Center(child: CircularProgressIndicator())
                                  : recentNewsItem(index);
                            },
                          ))
            ]));
  }

  Widget viewUserNewsContent() {
    return Padding(
        padding: EdgeInsetsDirectional.only(
          top: 15.0,
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: EdgeInsetsDirectional.only(start: 8.0),
                  child: Text(
                    getTranslated(context, 'forYou_lbl')!,
                    style: Theme.of(context).textTheme.subtitle1?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .fontColor
                            .withOpacity(0.9),
                        fontWeight: FontWeight.w600),
                  )),
              _isUserLoading
                  ? newsShimmer()
                  : userNewsList.length == 0
                      ? Center(
                          child: Text(userNews_not_avail,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.8))))
                      : SizedBox(
                          height: 250.0,
                          child: ListView.builder(
                            physics: AlwaysScrollableScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            controller: controller1,
                            itemCount: (offsetUser < totalUser)
                                ? userNewsList.length + 1
                                : userNewsList.length,
                            itemBuilder: (context, index) {
                              return (index == userNewsList.length &&
                                      _isUserLoadMore)
                                  ? Center(child: CircularProgressIndicator())
                                  : userNewsItem(index);
                            },
                          ))
            ]));
  }

  Widget catText() {
    return Padding(
        padding: EdgeInsetsDirectional.only(top: 20.0, bottom: 20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
                flex: 2,
                child: Divider(
                  color:
                      Theme.of(context).colorScheme.fontColor.withOpacity(0.7),
                  endIndent: 20,
                  thickness: 1.0,
                )),
            Text(
              getTranslated(context, 'category_lbl')!,
              style: Theme.of(context).textTheme.subtitle1?.merge(TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .fontColor
                        .withOpacity(0.7),
                  )),
            ),
            Expanded(
                flex: 7,
                child: Divider(
                  color:
                      Theme.of(context).colorScheme.fontColor.withOpacity(0.7),
                  indent: 20,
                  thickness: 1.0,
                )),
          ],
        ));
  }

  newsShimmer() {
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

  // newsShimmer() {
  //   return Shimmer.fromColors(
  //       baseColor: Colors.grey.withOpacity(0.6),
  //       highlightColor: Colors.grey,
  //       child: SingleChildScrollView(
  //         //padding: EdgeInsetsDirectional.only(start: 5.0, top: 20.0),
  //         scrollDirection: Axis.horizontal,
  //         child: Row(
  //             children: [0, 1, 2, 3, 4, 5, 6]
  //                 .map((i) => Padding(
  //                     padding: EdgeInsetsDirectional.only(
  //                         top: 15.0, start: i == 0 ? 0 : 6.0),
  //                     child: Stack(children: [
  //                       Container(
  //                         decoration: BoxDecoration(
  //                             borderRadius: BorderRadius.circular(10.0),
  //                             color: Colors.grey.withOpacity(0.6)),
  //                         height: 240.0,
  //                         width: 195.0,
  //                       ),
  //                       Positioned.directional(
  //                           textDirection: Directionality.of(context),
  //                           bottom: 7.0,
  //                           start: 7,
  //                           end: 7,
  //                           height: 99,
  //                           child: Container(
  //                             decoration: BoxDecoration(
  //                               borderRadius: BorderRadius.circular(10.0),
  //                               color: Colors.grey,
  //                             ),
  //                           )),
  //                     ])))
  //                 .toList()),
  //       ));
  // }

  recentNewsItem(int index) {
    List<String> tagList = [];
    DateTime time1 = DateTime.parse(recentNewsList[index].date!);
    if (recentNewsList[index].tagName! != "") {
      final tagName = recentNewsList[index].tagName!;
      tagList = tagName.split(',');
    }

    List<String> tagId = [];

    if (recentNewsList[index].tagId! != "") {
      tagId = recentNewsList[index].tagId!.split(",");
    }

    allImage.clear();

    allImage.add(recentNewsList[index].image!);
    if (recentNewsList[index].imageDataList!.length != 0) {
      for (int i = 0; i < recentNewsList[index].imageDataList!.length; i++) {
        allImage.add(recentNewsList[index].imageDataList![i].otherImage!);
      }
    }

    return Padding(
      padding:
          EdgeInsetsDirectional.only(top: 15.0, start: index == 0 ? 0 : 6.0),
      child: Hero(
        tag: recentNewsList[index].id!,
        child: InkWell(
          child: Stack(
            children: <Widget>[
              ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: FadeInImage(
                      fadeInDuration: Duration(milliseconds: 150),
                      image: CachedNetworkImageProvider(
                          recentNewsList[index].image!),
                      height: 250.0,
                      width: 450.0,
                      fit: BoxFit.cover,
                      imageErrorBuilder: (context, error, stackTrace) =>
                          errorWidget(250, 450),
                      placeholder: AssetImage(
                        placeHolder,
                      ))),
              Positioned.directional(
                  textDirection: Directionality.of(context),
                  bottom: 7.0,
                  start: 7,
                  end: 7,
                  height: 99,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: colors.tempboxColor.withOpacity(0.85),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  convertToAgo(time1, 0)!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption
                                      ?.copyWith(
                                          color: colors.tempdarkColor,
                                          fontSize: 10.0),
                                ),
                                Padding(
                                    padding: EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      recentNewsList[index].title!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle2
                                          ?.copyWith(
                                              color: colors.tempdarkColor
                                                  .withOpacity(0.9),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12.5,
                                              height: 1.0),
                                      maxLines: 3,
                                      softWrap: true,
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                Padding(
                                    padding: EdgeInsets.only(top: 4.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        recentNewsList[index].tagName! != ""
                                            ? SizedBox(
                                                height: 16.0,
                                                child: ListView.builder(
                                                    physics:
                                                        AlwaysScrollableScrollPhysics(),
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    shrinkWrap: true,
                                                    itemCount:
                                                        tagList.length >= 2
                                                            ? 2
                                                            : tagList.length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      return Padding(
                                                          padding: EdgeInsetsDirectional
                                                              .only(
                                                                  start:
                                                                      index == 0
                                                                          ? 0
                                                                          : 1.5),
                                                          child: InkWell(
                                                            child: Container(
                                                                height: 16.0,
                                                                width: 45,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                padding: EdgeInsetsDirectional
                                                                    .only(
                                                                        start:
                                                                            3.0,
                                                                        end:
                                                                            3.0,
                                                                        top:
                                                                            2.5,
                                                                        bottom:
                                                                            2.5),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              3.0),
                                                                  color: colors
                                                                      .primary
                                                                      .withOpacity(
                                                                          0.08),
                                                                ),
                                                                child: Text(
                                                                  tagList[
                                                                      index],
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .bodyText2
                                                                      ?.copyWith(
                                                                        color: colors
                                                                            .primary,
                                                                        fontSize:
                                                                            9.5,
                                                                      ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  softWrap:
                                                                      true,
                                                                )),
                                                            onTap: () async {
                                                              Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            NewsTag(
                                                                      tadId: tagId[
                                                                          index],
                                                                      tagName:
                                                                          tagList[
                                                                              index],
                                                                      updateParent:
                                                                          updateHomePage,
                                                                    ),
                                                                  ));
                                                            },
                                                          ));
                                                    }))
                                            : Container(),
                                        Spacer(),
                                        InkWell(
                                          child: SvgPicture.asset(
                                            bookMarkValue.contains(
                                                    recentNewsList[index].id)
                                                ? "assets/images/bookmarkfilled_icon.svg"
                                                : "assets/images/bookmark_icon.svg",
                                            semanticsLabel: 'bookmark icon',
                                            height: 14,
                                            width: 14,
                                          ),
                                          onTap: () async {
                                            _isNetworkAvail =
                                                await isNetworkAvailable();
                                            if (CUR_USERID != "") {
                                              if (_isNetworkAvail) {
                                                setState(() {
                                                  bookMarkValue.contains(
                                                          recentNewsList[index]
                                                              .id!)
                                                      ? _setBookmark(
                                                          "0",
                                                          recentNewsList[index]
                                                              .id!)
                                                      : _setBookmark(
                                                          "1",
                                                          recentNewsList[index]
                                                              .id!);
                                                });
                                              } else {
                                                setSnackbar(getTranslated(
                                                    context, 'internetmsg')!);
                                              }
                                            } else {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        Login(),
                                                  ));
                                            }
                                          },
                                        ),
                                        Padding(
                                          padding: EdgeInsetsDirectional.only(
                                              start: 8.0),
                                          child: InkWell(
                                            child: SvgPicture.asset(
                                              "assets/images/share_icon.svg",
                                              semanticsLabel: 'share icon',
                                              height: 13,
                                              width: 13,
                                            ),
                                            onTap: () async {
                                              _isNetworkAvail =
                                                  await isNetworkAvailable();
                                              if (_isNetworkAvail) {
                                                createDynamicLink(
                                                    recentNewsList[index].id!,
                                                    index,
                                                    recentNewsList[index]
                                                        .title!);
                                              } else {
                                                setSnackbar(getTranslated(
                                                    context, 'internetmsg')!);
                                              }
                                            },
                                          ),
                                        )
                                      ],
                                    ))
                              ],
                            ),
                          )))),
              Positioned.directional(
                  textDirection: Directionality.of(context),
                  bottom: (250 - 80) / 2,
                  start: 400 - 65,
                  child: InkWell(
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(40.0),
                        child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              height: 40,
                              width: 40,
                              padding: EdgeInsets.all(10.5),
                              decoration: BoxDecoration(
                                  color: colors.tempboxColor.withOpacity(0.7),
                                  shape: BoxShape.circle),
                              child: SvgPicture.asset(
                                recentNewsList[index].like == "1"
                                    ? "assets/images/likefilled_button.svg"
                                    : "assets/images/Like_icon.svg",
                                semanticsLabel: 'like icon',
                              ),
                            ))),
                    onTap: () async {
                      _isNetworkAvail = await isNetworkAvailable();

                      if (CUR_USERID != "") {
                        if (_isNetworkAvail) {
                          if (!isFirst) {
                            setState(() {
                              isFirst = true;
                            });
                            if (recentNewsList[index].like == "1") {
                              _setLikesDisLikes(
                                  "0", recentNewsList[index].id!, index, 1);

                              setState(() {});
                            } else {
                              _setLikesDisLikes(
                                  "1", recentNewsList[index].id!, index, 1);
                              setState(() {});
                            }
                          } else {
                            setSnackbar(getTranslated(context, 'internetmsg')!);
                          }
                        } else {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Login(),
                              ));
                        }
                      }
                    },
                  ))
            ],
          ),
          onTap: () {
            News model = recentNewsList[index];
            List<News> recList = [];
            recList.addAll(recentNewsList);
            recList.removeAt(index);
            Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) => NewsDetails(
                      model: model,
                      index: index,
                      updateParent: updateHomePage,
                      id: model.id,
                      isFav: false,
                      isDetails: true,
                      news: recList,
                    )));
          },
        ),
      ),
    );
  }

  userNewsItem(int index) {
    List<String> tagList = [];
    DateTime time1 = DateTime.parse(userNewsList[index].date!);
    if (userNewsList[index].tagName! != "") {
      final tagName = userNewsList[index].tagName!;
      tagList = tagName.split(',');
    }

    List<String> tagId = [];

    if (userNewsList[index].tagId! != "") {
      tagId = userNewsList[index].tagId!.split(",");
    }

    allImage.clear();

    allImage.add(userNewsList[index].image!);
    if (userNewsList[index].imageDataList!.length != 0) {
      for (int i = 0; i < userNewsList[index].imageDataList!.length; i++) {
        allImage.add(userNewsList[index].imageDataList![i].otherImage!);
      }
    }

    return Padding(
      padding:
          EdgeInsetsDirectional.only(top: 15.0, start: index == 0 ? 0 : 6.0),
      child: Hero(
        tag: userNewsList[index].id!,
        child: InkWell(
          child: Stack(
            children: <Widget>[
              ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: FadeInImage(
                      fadeInDuration: Duration(milliseconds: 150),
                      image: CachedNetworkImageProvider(
                          userNewsList[index].image!),
                      height: 250.0,
                      width: 193.0,
                      fit: BoxFit.cover,
                      imageErrorBuilder: (context, error, stackTrace) =>
                          errorWidget(250, 193),
                      placeholder: AssetImage(
                        placeHolder,
                      ))),
              Positioned.directional(
                  textDirection: Directionality.of(context),
                  bottom: 7.0,
                  start: 7,
                  end: 7,
                  height: 99,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: colors.tempboxColor.withOpacity(0.85),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  convertToAgo(time1, 0)!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption
                                      ?.copyWith(
                                          color: colors.tempdarkColor,
                                          fontSize: 10.0),
                                ),
                                Padding(
                                    padding: EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      userNewsList[index].title!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle2
                                          ?.copyWith(
                                              color: colors.tempdarkColor
                                                  .withOpacity(0.9),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12.5,
                                              height: 1.0),
                                      maxLines: 3,
                                      softWrap: true,
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                Padding(
                                    padding: EdgeInsets.only(top: 4.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        userNewsList[index].tagName! != ""
                                            ? SizedBox(
                                                height: 16.0,
                                                child: ListView.builder(
                                                    physics:
                                                        AlwaysScrollableScrollPhysics(),
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    shrinkWrap: true,
                                                    itemCount:
                                                        tagList.length >= 2
                                                            ? 2
                                                            : tagList.length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      return Padding(
                                                          padding: EdgeInsetsDirectional
                                                              .only(
                                                                  start:
                                                                      index == 0
                                                                          ? 0
                                                                          : 1.5),
                                                          child: InkWell(
                                                            child: Container(
                                                                height: 16.0,
                                                                width: 45,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                padding: EdgeInsetsDirectional
                                                                    .only(
                                                                        start:
                                                                            3.0,
                                                                        end:
                                                                            3.0,
                                                                        top:
                                                                            2.5,
                                                                        bottom:
                                                                            2.5),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              3.0),
                                                                  color: colors
                                                                      .primary
                                                                      .withOpacity(
                                                                          0.08),
                                                                ),
                                                                child: Text(
                                                                  tagList[
                                                                      index],
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .bodyText2
                                                                      ?.copyWith(
                                                                        color: colors
                                                                            .primary,
                                                                        fontSize:
                                                                            9.5,
                                                                      ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  softWrap:
                                                                      true,
                                                                )),
                                                            onTap: () {
                                                              Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            NewsTag(
                                                                      tadId: tagId[
                                                                          index],
                                                                      tagName:
                                                                          tagList[
                                                                              index],
                                                                      updateParent:
                                                                          updateHomePage,
                                                                    ),
                                                                  ));
                                                            },
                                                          ));
                                                    }))
                                            : Container(),
                                        Spacer(),
                                        InkWell(
                                          child: SvgPicture.asset(
                                            bookMarkValue.contains(
                                                    userNewsList[index].id)
                                                ? "assets/images/bookmarkfilled_icon.svg"
                                                : "assets/images/bookmark_icon.svg",
                                            semanticsLabel: 'bookmark icon',
                                            height: 14,
                                            width: 14,
                                          ),
                                          onTap: () async {
                                            _isNetworkAvail =
                                                await isNetworkAvailable();
                                            if (CUR_USERID != "") {
                                              if (_isNetworkAvail) {
                                                setState(() {
                                                  bookMarkValue.contains(
                                                          userNewsList[index]
                                                              .id!)
                                                      ? _setBookmark(
                                                          "0",
                                                          userNewsList[index]
                                                              .id!)
                                                      : _setBookmark(
                                                          "1",
                                                          userNewsList[index]
                                                              .id!);
                                                });
                                              } else {
                                                setSnackbar(getTranslated(
                                                    context, 'internetmsg')!);
                                              }
                                            } else {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        Login(),
                                                  ));
                                            }
                                          },
                                        ),
                                        Padding(
                                          padding: EdgeInsetsDirectional.only(
                                              start: 8.0),
                                          child: InkWell(
                                            child: SvgPicture.asset(
                                              "assets/images/share_icon.svg",
                                              semanticsLabel: 'share icon',
                                              height: 13,
                                              width: 13,
                                            ),
                                            onTap: () async {
                                              _isNetworkAvail =
                                                  await isNetworkAvailable();
                                              if (_isNetworkAvail) {
                                                createDynamicLink(
                                                    userNewsList[index].id!,
                                                    index,
                                                    userNewsList[index].title!);
                                              } else {
                                                setSnackbar(getTranslated(
                                                    context, 'internetmsg')!);
                                              }
                                            },
                                          ),
                                        )
                                      ],
                                    ))
                              ],
                            ),
                          )))),
              Positioned.directional(
                  textDirection: Directionality.of(context),
                  bottom: (250 - 80) / 2,
                  start: 190 - 65,
                  child: InkWell(
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(40.0),
                        child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              height: 40,
                              width: 40,
                              padding: EdgeInsets.all(10.5),
                              decoration: BoxDecoration(
                                  color: colors.tempboxColor.withOpacity(0.7),
                                  shape: BoxShape.circle),
                              child: SvgPicture.asset(
                                userNewsList[index].like == "1"
                                    ? "assets/images/likefilled_button.svg"
                                    : "assets/images/Like_icon.svg",
                                semanticsLabel: 'like icon',
                              ),
                            ))),
                    onTap: () async {
                      _isNetworkAvail = await isNetworkAvailable();

                      if (CUR_USERID != "") {
                        if (_isNetworkAvail) {
                          if (userNewsList[index].like == "1") {
                            _setLikesDisLikes(
                                "0", userNewsList[index].id!, index, 2);
                            setState(() {});
                          } else {
                            _setLikesDisLikes(
                                "1", userNewsList[index].id!, index, 2);
                            setState(() {});
                          }
                        } else {
                          setSnackbar(getTranslated(context, 'internetmsg')!);
                        }
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Login(),
                            ));
                      }
                    },
                  ))
            ],
          ),
          onTap: () {
            News model = userNewsList[index];
            List<News> usList = [];
            usList.addAll(userNewsList);
            usList.removeAt(index);
            Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) => NewsDetails(
                      model: model,
                      index: index,
                      updateParent: updateHomePage,
                      id: model.id,
                      isFav: false,
                      isDetails: true,
                      news: usList,
                    )));
          },
        ),
      ),
    );
  }

  breakingNewsItem(int index) {
    return Padding(
      padding:
          EdgeInsetsDirectional.only(top: 15.0, start: index == 0 ? 0 : 6.0),
      child: Hero(
        tag: breakingNewsList[index].id!,
        child: InkWell(
          child: Stack(
            children: <Widget>[
              ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: FadeInImage(
                      fadeInDuration: Duration(milliseconds: 150),
                      image: CachedNetworkImageProvider(
                          breakingNewsList[index].image!),
                      height: 250.0,
                      width: 193.0,
                      fit: BoxFit.cover,
                      imageErrorBuilder: (context, error, stackTrace) =>
                          errorWidget(250, 193),
                      placeholder: AssetImage(
                        placeHolder,
                      ))),
              Positioned.directional(
                  textDirection: Directionality.of(context),
                  bottom: 7.0,
                  start: 7,
                  end: 7,
                  height: 62,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: colors.tempboxColor.withOpacity(0.85),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  breakingNewsList[index].title!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle2
                                      ?.copyWith(
                                          color: colors.tempdarkColor
                                              .withOpacity(0.9),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                          height: 1.0),
                                  maxLines: 3,
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          )))),
            ],
          ),
          onTap: () {
            BreakingNewsModel model = breakingNewsList[index];
            List<BreakingNewsModel> tempBreak = [];
            tempBreak.addAll(breakingNewsList);
            tempBreak.removeAt(index);
            Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) => NewsDetails(
                      model1: model,
                      index: index,
                      updateParent: updateHomePage,
                      id: model.id,
                      isFav: false,
                      isDetails: false,
                      news1: tempBreak,
                      //updateHome: updateHome,
                    )));
          },
        ),
      ),
    );
  }

//set likes of news using api
  _setLikesDisLikes(String status, String id, int index, int from) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
        USER_ID: CUR_USERID,
        NEWS_ID: id,
        STATUS: status,
      };

      http.Response response = await http
          .post(Uri.parse(setLikesDislikesApi), body: param, headers: headers)
          .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      String error = getdata["error"];

      String msg = getdata["message"];

      if (error == "false") {
        if (status == "1") {
          if (from == 1) {
            recentNewsList[index].like = "1";
            recentNewsList[index].totalLikes =
                (int.parse(recentNewsList[index].totalLikes!) + 1).toString();
          } else {
            userNewsList[index].like = "1";
            userNewsList[index].totalLikes =
                (int.parse(userNewsList[index].totalLikes!) + 1).toString();
          }
          setSnackbar(getTranslated(context, 'like_succ')!);
        } else if (status == "0") {
          if (from == 1) {
            recentNewsList[index].like = "0";
            recentNewsList[index].totalLikes =
                (int.parse(recentNewsList[index].totalLikes!) - 1).toString();
          } else {
            userNewsList[index].like = "0";
            userNewsList[index].totalLikes =
                (int.parse(userNewsList[index].totalLikes!) - 1).toString();
          }
          setSnackbar(getTranslated(context, 'dislike_succ')!);
        }
        setState(() {
          isFirst = false;
        });
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg')!);
    }
  }

  updateHomePage() {
    setState(() {
      bookmarkList.clear();
      bookMarkValue.clear();
      _getBookmark();
    });
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

  //get breaking news data list
  Future<void> getBreakingNews() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var param = {
          ACCESS_KEY: access_key,
        };
        http.Response response = await http
            .post(Uri.parse(getBreakingNewsApi), body: param, headers: headers)
            .timeout(Duration(seconds: timeOut));
        if (response.statusCode == 200) {
          var getData = json.decode(response.body);
          String error = getData["error"];
          if (error == "false") {
            tempBreakList.clear();
            var data = getData["data"];
            tempBreakList = (data as List)
                .map((data) => new BreakingNewsModel.fromJson(data))
                .toList();

            breakingNewsList.addAll(tempBreakList);

            setState(() {
              _isBreakLoading = false;
            });
          }
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
        setState(() {
          _isBreakLoading = false;
        });
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg')!);
      setState(() {
        _isBreakLoading = false;
      });
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

  _scrollListener1() {
    if (controller1.offset >= controller1.position.maxScrollExtent &&
        !controller1.position.outOfRange) {
      if (this.mounted) {
        setState(() {
          _isUserLoadMore = true;

          if (offsetUser < totalUser) getUserByCatNews();
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
          "category_id": widget.categoryId,
          USER_ID: CUR_USERID != "" ? CUR_USERID : "0"
        };
        log(getNewsApi.toString());
        log(param.toString());
        http.Response response = await http
            .post(Uri.parse(getNewsByCatApi), body: param, headers: headers)
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

//get all category using api
  Future<void> getCat() async {
    if (category_mode == "1") {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          var param = {
            ACCESS_KEY: access_key,
          };

          http.Response response = await http
              .post(Uri.parse(getCatApi), body: param, headers: headers)
              .timeout(Duration(seconds: timeOut));
          var getData = json.decode(response.body);
          log("Cat " + response.body.toString());
          log(getData.toString());
          String error = getData["error"];
          if (error == "false") {
            tempCatList.clear();
            var data = getData["data"];
            tempCatList = (data as List)
                .map((data) => new Category.fromJson(data))
                .toList();
            catList.addAll(tempCatList);
            for (int i = 0; i < catList.length; i++) {
              if (catList[i].subData!.length != 0) {
                catList[i].subData!.insert(
                    0,
                    SubCategory(
                        id: "0",
                        subCatName:
                            "${getTranslated(context, 'all_lbl')! + "\t" + catList[i].categoryName!}"));
              }
            }

            _tabs.clear();
            this._addInitailTab();
          }
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
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  //get bookmark news list id using api
  Future<void> _getBookmark() async {
    if (CUR_USERID != "") {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          var param = {
            ACCESS_KEY: access_key,
            USER_ID: CUR_USERID,
          };
          http.Response response = await http
              .post(Uri.parse(getBookmarkApi), body: param, headers: headers)
              .timeout(Duration(seconds: timeOut));

          var getdata = json.decode(response.body);

          String error = getdata["error"];
          if (error == "false") {
            bookmarkList.clear();
            var data = getdata["data"];

            bookmarkList =
                (data as List).map((data) => new News.fromJson(data)).toList();
            bookMarkValue.clear();

            for (int i = 0; i < bookmarkList.length; i++) {
              setState(() {
                bookMarkValue.add(bookmarkList[i].newsId);
              });
            }
            if (mounted)
              setState(() {
                _isLoading = false;
              });
          } else {
            setState(() {
              _isLoadingMore = false;
              _isLoading = false;
            });
          }
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!);
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setSnackbar(getTranslated(context, 'internetmsg')!);
      }
    }
  }
}

// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:ui';

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_svg/svg.dart';

// import 'package:http/http.dart' as http;

// import 'package:intl/intl.dart';
// import 'package:location/location.dart' as loc;
// import 'package:location/location.dart';
// import 'package:news/Bookmark.dart';
// import 'package:news/Helper/Color.dart';
// import 'package:news/Helper/Constant.dart';
// import 'package:news/Helper/Session.dart';
// import 'package:news/Helper/String.dart';
// import 'package:news/Model/BreakingNews.dart';
// import 'package:news/Model/News.dart';
// import 'package:news/NewsTag.dart';
// import 'package:news/NotificationList.dart';
// import 'package:news/Search.dart';
// import 'package:news/Setting.dart';
// import 'package:shimmer/shimmer.dart';
// import 'Helper/PushNotificationService.dart';
// import 'Live.dart';
// import 'Login.dart';
// import 'Model/Category.dart';
// import 'Model/WeatherData.dart';
// import 'NewsDetails.dart';
// import 'SubHome.dart';
// import 'main.dart';

// class Home extends StatefulWidget {
//   @override
//   HomeState createState() => HomeState();
// }

// int _selectedIndex = 0;

// class HomeState extends State<Home> {
//   final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
//   List<Widget>? fragments;
//   DateTime? currentBackPressTime;
//   bool _isNetworkAvail = true;

//   @override
//   void initState() {
//     super.initState();
//     getUserDetails();
//     initDynamicLinks();
//     fragments = [
//       HomePage(),
//       Bookmark(),
//       NotificationList(),
//       Setting(),
//     ];
//     firNotificationInitialize();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   Future<void> getUserDetails() async {
//     CUR_USERID = (await getPrefrence(ID)) ?? "";
//     CATID = (await getPrefrence(cur_catId)) ?? "";

//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
//         overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);
//     return WillPopScope(
//         onWillPop: onWillPop,
//         child: Scaffold(
//           key: _scaffoldKey,
//           backgroundColor: colors.bgColor,
//           //extendBodyBehindAppBar: true,
//           extendBody: true,
//           bottomNavigationBar: bottomBar(),
//           body: fragments?[_selectedIndex],
//         ));
//   }

//   void firNotificationInitialize() {
//     //for firebase push notification
//     FlutterLocalNotificationsPlugin();
// // initialise the plugin. ic_launcher needs to be a added as a drawable resource to the Android head project
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//     final IOSInitializationSettings initializationSettingsIOS =
//         IOSInitializationSettings(
//             requestAlertPermission: true,
//             requestBadgePermission: true,
//             requestSoundPermission: true);
//     final MacOSInitializationSettings initializationSettingsMacOS =
//         MacOSInitializationSettings();
//     final InitializationSettings initializationSettings =
//         InitializationSettings(
//             android: initializationSettingsAndroid,
//             iOS: initializationSettingsIOS,
//             macOS: initializationSettingsMacOS);

//     PushNotificationService.flutterLocalNotificationsPlugin.initialize(
//         initializationSettings, onSelectNotification: (String? payload) async {
//       if (payload != null && payload != "") {
//         debugPrint('notification payload: $payload');
//         getNewsById(payload);
//       } else {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => MyApp()),
//         );
//       }
//     });
//   }

//   //when home page in back click press
//   Future<bool> onWillPop() {
//     DateTime now = DateTime.now();
//     if (_selectedIndex != 0) {
//       _selectedIndex = 0;

//       return Future.value(false);
//     } else if (currentBackPressTime == null ||
//         now.difference(currentBackPressTime!) > Duration(seconds: 2)) {
//       currentBackPressTime = now;
//       setSnackbar(getTranslated(context, 'EXIT_WR')!);

//       return Future.value(false);
//     }
//     return Future.value(true);
//   }

//   _onItemTapped(index) async {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   //when dynamic link share that's open in app used this function
//   void initDynamicLinks() async {
//     FirebaseDynamicLinks.instance.onLink.listen((dynamicLink) {
//       final Uri? deepLink = dynamicLink.link;

//       if (deepLink != null) {
//         if (deepLink.queryParameters.length > 0) {
//           String id = deepLink.queryParameters['id']!;
//           getNewsById(id);
//         }
//       }
//     }, onError: (e) async {
//       print(e.message);
//     });
//   }

//   updateParent() {
//     //setState(() {});
//   }

//   //show snackbar msg
//   setSnackbar(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
//       content: new Text(
//         msg,
//         textAlign: TextAlign.center,
//         style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
//       ),
//       backgroundColor: isDark! ? colors.tempdarkColor : colors.bgColor,
//       elevation: 1.0,
//     ));
//   }

//   //when open dynamic link news index and id can used for fetch specific news
//   Future<void> getNewsById(String id) async {
//     _isNetworkAvail = await isNetworkAvailable();
//     if (_isNetworkAvail) {
//       var param = {
//         NEWS_ID: id,
//         ACCESS_KEY: access_key,
//         USER_ID: CUR_USERID != null && CUR_USERID != "" ? CUR_USERID : "0"
//       };
//       http.Response response = await http
//           .post(Uri.parse(getNewsByIdApi), body: param, headers: headers)
//           .timeout(Duration(seconds: timeOut));
//       var getdata = json.decode(response.body);
// log(getdata.toString());
//       String error = getdata["error"];

//       if (error == "false") {
//         var data = getdata["data"];
//         List<News> news = [];
//         news = (data as List).map((data) => new News.fromJson(data)).toList();
//         Navigator.of(context).push(MaterialPageRoute(
//             builder: (BuildContext context) => NewsDetails(
//                   model: news[0],
//                   index: int.parse(id),
//                   updateParent: updateParent,
//                   id: news[0].id,
//                   isFav: false,
//                   isDetails: true,
//                   news: [],
//                   // updateHome: updateParent,
//                 )));
//       }
//     } else {
//       setSnackbar(getTranslated(context, 'internetmsg')!);
//     }
//   }

//   bottomBar() {
//     return Padding(
//         padding: EdgeInsetsDirectional.only(
//             start: 15.0, end: 15.0, bottom: 15.0, top: 10.0),
//         child: Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(10.0),
//               boxShadow: [
//                 BoxShadow(
//                     blurRadius: 10.0,
//                     offset: const Offset(5.0, 5.0),
//                     color: Theme.of(context)
//                         .colorScheme
//                         .fontColor
//                         .withOpacity(0.1),
//                     spreadRadius: 1.0),
//               ],
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(10.0),
//               child: BottomNavigationBar(
//                 showSelectedLabels: false,
//                 showUnselectedLabels: false,
//                 currentIndex: _selectedIndex,
//                 onTap: (int index) {
//                   _onItemTapped(index);
//                 },
//                 backgroundColor: Theme.of(context).colorScheme.boxColor,
//                 type: BottomNavigationBarType.fixed,
//                 items: <BottomNavigationBarItem>[
//                   BottomNavigationBarItem(
//                       icon: SvgPicture.asset("assets/images/home_icon.svg",
//                           semanticsLabel: 'home',
//                           height: 20.0,
//                           width: 20.0,
//                           color: _selectedIndex == 0
//                               ? colors.primary
//                               : Theme.of(context).colorScheme.fontColor),
//                       label: "Home"),
//                   BottomNavigationBarItem(
//                       icon: SvgPicture.asset("assets/images/saved_icon.svg",
//                           semanticsLabel: 'saved',
//                           height: 20.0,
//                           width: 20.0,
//                           color: _selectedIndex == 1
//                               ? colors.primary
//                               : Theme.of(context).colorScheme.fontColor),
//                       label: "Saved Bookmark"),
//                   BottomNavigationBarItem(
//                       icon: Icon(
//                         Icons.notifications,
//                         color: _selectedIndex == 2
//                             ? colors.primary
//                             : Theme.of(context).colorScheme.fontColor,
//                       ),
//                       label: "Notification"),
//                   BottomNavigationBarItem(
//                       icon: Icon(
//                         Icons.settings,
//                         color: _selectedIndex == 3
//                             ? colors.primary
//                             : Theme.of(context).colorScheme.fontColor,
//                       ),
//                       label: "Setting"),
//                 ],
//               ),
//             )));
//   }
// }

// class HomePage extends StatefulWidget {
//   @override
//   HomePageState createState() => HomePageState();
// }

// class HomePageState extends State<HomePage> with TickerProviderStateMixin {
//   final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

//   List<News> tempList = [];
//   List<Category> tempCatList = [];
//   List<BreakingNewsModel> tempBreakList = [];
//   List<BreakingNewsModel> breakingNewsList = [];
//   WeatherData? weatherData;
//   loc.Location _location = new loc.Location();
//   String? error;
//   bool? _serviceEnabled;
//   PermissionStatus? _permissionGranted;
//   final TextEditingController textController = TextEditingController();
//   TabController? _tc;
//   int offsetRecent = 0;
//   int totalRecent = 0;
//   int offsetUser = 0;
//   int totalUser = 0;
//   String? catId = "";
//   List<Map<String, dynamic>> _tabs = [];
//   List<News> recentNewsList = [];
//   List<News> recenttempList = [];
//   List<News> tempUserNews = [];
//   List<News> userNewsList = [];
//   bool _isBreakLoading = true;
//   bool _isUserLoading = true;
//   bool _isUserLoadMore = true;
//   bool _isRecentLoading = true;
//   bool _isRecentLoadMore = true;
//   bool _isLoading = true;
//   bool _isLoadingMore = true;
//   bool _isNetworkAvail = true;
//   bool weatherLoad = true;
//   List<Category> catList = [];
//   int tcIndex = 0;

//   var scrollController = ScrollController();
//   List bookMarkValue = [];
//   List<News> bookmarkList = [];
//   List<String> allImage = [];
//   final _pageController = PageController();
//   int _curSlider = 0;
//   int? selectSubCat = 0;

//   bool isFirst = false;
//   var isliveNews;

//   List<News> newsList = [];
//   List<News> tempNewsList = [];
//   int offset = 0;
//   int total = 0;
//   bool enabled = true;
//   ScrollController controller = new ScrollController();
//   ScrollController controller1 = new ScrollController();
//   bool isTab = true;
//   SubHome subHome = SubHome();

//   @override
//   void initState() {
//     loadWeather();

//     controller.addListener(_scrollListener);
//     controller1.addListener(_scrollListener1);

//     callApi();

//     super.initState();
//   }

//   Future<void> callApi() async {
//     getSetting();

//     await getLiveNews();
//     await getBreakingNews();
//     await getNews();
//     await getUserByCatNews();
//     await getCat();
//     await _getBookmark();
//   }

//   //get user selected category newslist
//   Future<void> getUserByCatNews() async {

//     if (CUR_USERID != "" && CATID != "") {
//       _isNetworkAvail = await isNetworkAvailable();
//       if (_isNetworkAvail) {
//         try {
//           var param = {
//             ACCESS_KEY: access_key,
//             CATEGORY_ID: CATID,
//             USER_ID: CUR_USERID,
//             LIMIT: perPage.toString(),
//             OFFSET: offsetUser.toString(),
//           };
//           http.Response response = await http
//               .post(Uri.parse(getNewsByUserCatApi),
//                   body: param, headers: headers)
//               .timeout(Duration(seconds: timeOut));
//           if (response.statusCode == 200) {
//             var getData = json.decode(response.body);
//             String error = getData["error"];
//             if (error == "false") {
//               totalUser = int.parse(getData["total"]);
//               if ((offsetUser) < totalUser) {
//                 tempUserNews.clear();
//                 var data = getData["data"];
//                 tempUserNews = (data as List)
//                     .map((data) => new News.fromJson(data))
//                     .toList();
//                 userNewsList.addAll(tempUserNews);
//                 offsetUser = offsetUser + perPage;
//               }
//             } else {
//               _isUserLoadMore = false;
//             }
//             if (mounted)
//               setState(() {
//                 _isUserLoading = false;
//               });
//           }
//         } on TimeoutException catch (_) {
//           setSnackbar(getTranslated(context, 'somethingMSg')!);
//           setState(() {
//             _isUserLoading = false;
//             _isUserLoadMore = false;
//           });
//         }
//       } else {
//         setSnackbar(getTranslated(context, 'internetmsg')!);
//         setState(() {
//           _isUserLoading = false;
//           _isUserLoadMore = false;
//         });
//       }
//     }
//   }

//   //set bookmark of news using api
//   _setBookmark(String status, String id) async {
//     if (bookMarkValue.contains(id)) {
//       setState(() {
//         bookMarkValue = List.from(bookMarkValue)..remove(id);
//       });
//     } else {
//       setState(() {
//         bookMarkValue = List.from(bookMarkValue)..add(id);
//       });
//     }

//     _isNetworkAvail = await isNetworkAvailable();
//     if (_isNetworkAvail) {
//       var param = {
//         ACCESS_KEY: access_key,
//         USER_ID: CUR_USERID,
//         NEWS_ID: id,
//         STATUS: status,
//       };

//       http.Response response = await http
//           .post(Uri.parse(setBookmarkApi), body: param, headers: headers)
//           .timeout(Duration(seconds: timeOut));

//       var getdata = json.decode(response.body);

//       String error = getdata["error"];

//       String msg = getdata["message"];

//       if (error == "false") {
//         if (status == "0") {
//           setSnackbar(msg);
//         } else {
//           setSnackbar(msg);
//         }
//       }
//     } else {
//       setSnackbar(getTranslated(context, 'internetmsg')!);
//     }
//   }

//   //add tab bar category title
//   _addInitailTab() async {
//     setState(() {
//       for (int i = 0; i < catList.length; i++) {
//         _tabs.add({
//           'text': catList[i].categoryName,
//         });
//         catId = catList[i].id;
//       }

//       _tc = TabController(
//         vsync: this,
//         length: _tabs.length,
//       )..addListener(() {
//           setState(() {
//             isTab = true;

//             tcIndex = _tc!.index;
//             selectSubCat = 0;
//           });
//         });
//     });
//   }

//   catShimmer() {
//     return Container(
//         child: Shimmer.fromColors(
//             baseColor: Colors.grey.withOpacity(0.4),
//             highlightColor: Colors.grey.withOpacity(0.4),
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                   children: [0, 1, 2, 3, 4, 5, 6]
//                       .map((i) => Padding(
//                           padding: EdgeInsetsDirectional.only(
//                               start: i == 0 ? 0 : 15),
//                           child: Container(
//                             decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(5.0),
//                                 color: Colors.grey),
//                             height: 32.0,
//                             width: 110.0,
//                           )))
//                       .toList()),
//             )));
//   }

//   tabBarData() {
//     return TabBar(
//       //indicatorSize: TabBarIndicatorSize.tab,
//       labelStyle: Theme.of(context).textTheme.subtitle1?.copyWith(
//             fontWeight: FontWeight.w600,
//           ),
//       unselectedLabelColor:
//           Theme.of(context).colorScheme.fontColor.withOpacity(0.8),
//       isScrollable: true,
//       indicator: BoxDecoration(
//           borderRadius: BorderRadius.circular(5),
//           // Creates border
//           color: colors.primary.withOpacity(0.08)),
//       tabs: _tabs
//           .map((tab) => Container(
//               height: 32,
//               padding: EdgeInsetsDirectional.only(top: 5.0, bottom: 5.0),
//               child: Tab(
//                 text: tab['text'],
//               )))
//           .toList(),
//       labelColor: colors.primary,
//       controller: _tc,
//       unselectedLabelStyle: Theme.of(context).textTheme.subtitle1?.copyWith(),
//     );
//   }

//   subTabData() {
//     return catList.length != 0
//         ? catList[_tc!.index].subData!.length != 0
//             ? Padding(
//                 padding: EdgeInsetsDirectional.only(top: 10.0),
//                 child: Container(
//                     height: 27,
//                     alignment: Alignment.center,
//                     child: ListView.builder(
//                         shrinkWrap: true,
//                         scrollDirection: Axis.horizontal,
//                         itemCount: catList[_tc!.index].subData!.length,
//                         itemBuilder: (context, index) {
//                           return Padding(
//                               padding: EdgeInsetsDirectional.only(
//                                   start: index == 0 ? 0 : 10),
//                               child: InkWell(
//                                 child: Container(
//                                     alignment: Alignment.center,
//                                     padding: EdgeInsetsDirectional.only(
//                                         start: 7.0,
//                                         end: 7.0,
//                                         top: 2.5,
//                                         bottom: 2.5),
//                                     decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(5.0),
//                                       color: selectSubCat == index
//                                           ? colors.primary.withOpacity(0.07)
//                                           : Theme.of(context)
//                                               .colorScheme
//                                               .fontColor
//                                               .withOpacity(0.13),
//                                     ),
//                                     child: Text(
//                                       catList[_tc!.index]
//                                           .subData![index]
//                                           .subCatName!,
//                                       style: Theme.of(context)
//                                           .textTheme
//                                           .subtitle2
//                                           ?.copyWith(
//                                               color: selectSubCat == index
//                                                   ? colors.primary
//                                                   : Theme.of(context)
//                                                       .colorScheme
//                                                       .fontColor
//                                                       .withOpacity(0.9),
//                                               fontSize: 12,
//                                               fontWeight: selectSubCat == index
//                                                   ? FontWeight.w600
//                                                   : FontWeight.normal),
//                                       overflow: TextOverflow.ellipsis,
//                                       softWrap: true,
//                                     )),
//                                 onTap: () async {
//                                   this.setState(() {
//                                     isTab = false;
//                                     selectSubCat = index;

//                                     if (index == 0) {
//                                       subHome = SubHome(
//                                         subCatId: "0",
//                                         curTabId: catList[tcIndex].id!,
//                                         index: tcIndex,
//                                         isSubCat: true,
//                                         catList: catList,
//                                         scrollController: scrollController,
//                                       );
//                                     } else {
//                                       subHome = SubHome(
//                                         subCatId: catList[tcIndex]
//                                             .subData![index]
//                                             .id!,
//                                         curTabId: "0",
//                                         index: tcIndex,
//                                         isSubCat: true,
//                                         catList: catList,
//                                         scrollController: scrollController,
//                                       );
//                                     }
//                                   });
//                                 },
//                               ));
//                         })))
//             : Container()
//         : Container();
//   }

//   @override
//   Widget build(BuildContext context) {
//     deviceWidth = MediaQuery.of(context).size.width;
//     deviceHeight = MediaQuery.of(context).size.height;
//     return Scaffold(
//         key: _scaffoldKey,
//         body: SafeArea(
//             child: Padding(
//                 padding: EdgeInsetsDirectional.only(
//                     top: 10.0, start: 15.0, end: 15.0, bottom: 10.0),
//                 child: NestedScrollView(
//                     physics: BouncingScrollPhysics(
//                         parent: AlwaysScrollableScrollPhysics()),
//                     controller: scrollController,
//                     headerSliverBuilder:
//                         (BuildContext context, bool innerBoxIsScrolled) {
//                       return <Widget>[
//                         new SliverList(
//                           delegate: new SliverChildListDelegate([
//                             // weatherDataView(),
//                             liveWithSearchView(),
//                             // viewBreakingNews(),
//                             viewRecentContent(),
//                             CUR_USERID != "" &&
//                                     CATID != "" &&
//                                     userNewsList.length > 0
//                                 ? viewUserNewsContent()
//                                 : Container(),
//                             catText(),
//                           ]),
//                         ),
//                         SliverAppBar(
//                           toolbarHeight: 0,
//                           titleSpacing: 0,
//                           pinned: true,
//                           bottom: catList.length != 0
//                               ? PreferredSize(
//                                   preferredSize: Size.fromHeight(
//                                       catList[_tc!.index].subData!.length !=
//                                               0
//                                           ? 71
//                                           : 34),
//                                   child: Column(children: [
//                                     tabBarData(),
//                                     subTabData()
//                                   ]))
//                               : PreferredSize(
//                                   preferredSize: Size.fromHeight(34),
//                                   child: catShimmer()),
//                           backgroundColor: isDark!
//                               ? colors.darkModeColor
//                               : colors.bgColor,
//                           elevation: 0,
//                           floating: true,
//                         )
//                       ];
//                     },
//                     body: catList.length != 0
//                         ? TabBarView(
//                             controller: _tc,
//                             //key: _key,
//                             children: new List<Widget>.generate(_tc!.length,
//                                 (int index) {
//                               //return viewContent();
//                               return isTab
//                                   ? SubHome(
//                                       curTabId: catList[index].id,
//                                       isSubCat: false,
//                                       scrollController: scrollController,
//                                       catList: catList,
//                                       subCatId: "0",
//                                       index: index,
//                                     )
//                                   : subHome;
//                             }))
//                         : contentShimmer(context)))));
//   }

//   Widget weatherDataView() {
//     DateTime now = DateTime.now();
//     String day = DateFormat('EEEE').format(now);
//     return !weatherLoad
//         ? Container(
//             padding: EdgeInsets.all(15.0),
//             height: 110,
//             //width: deviceWidth,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(10.0),
//               color: Theme.of(context).colorScheme.lightColor,
//               boxShadow: [
//                 BoxShadow(
//                     blurRadius: 10.0,
//                     offset: const Offset(12.0, 15.0),
//                     color: colors.tempdarkColor.withOpacity(0.2),
//                     spreadRadius: -7),
//               ],
//             ),
//             child: Row(
//               children: <Widget>[
//                 Expanded(
//                   flex: 3,
//                   child: Column(
//                     children: <Widget>[
//                       Text(
//                         getTranslated(context, 'weather_lbl')!,
//                         style:
//                             Theme.of(this.context).textTheme.subtitle2?.copyWith(
//                                   color: Theme.of(context)
//                                       .colorScheme
//                                       .fontColor
//                                       .withOpacity(0.8),
//                                 ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         softWrap: true,
//                       ),
//                       weatherData != null
//                           ? Row(
//                               children: <Widget>[
//                                 Image.network(
//                                   "https:${weatherData!.icon!}",
//                                   width: 40.0,
//                                   height: 40.0,
//                                 ),
//                                 Padding(
//                                     padding:
//                                         EdgeInsetsDirectional.only(start: 7.0),
//                                     child: Text(
//                                       "${weatherData!.tempC!.toString()}\u2103",
//                                       style: Theme.of(this.context)
//                                           .textTheme
//                                           .headline6
//                                           ?.copyWith(
//                                             color: Theme.of(context)
//                                                 .colorScheme
//                                                 .fontColor
//                                                 .withOpacity(0.8),
//                                           ),
//                                       overflow: TextOverflow.ellipsis,
//                                       softWrap: true,
//                                       maxLines: 1,
//                                     ))
//                               ],
//                             )
//                           : Container()
//                     ],
//                   ),
//                 ),
//                 Spacer(),
//                 weatherData != null
//                     ? Expanded(
//                   flex: 4,
//                       child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: <Widget>[
//                             Text(
//                               "${weatherData!.name!},${weatherData!.region!},${weatherData!.country!}",
//                               style: Theme.of(this.context)
//                                   .textTheme
//                                   .subtitle2
//                                   ?.copyWith(
//                                       color:
//                                           Theme.of(context).colorScheme.fontColor,
//                                       fontWeight: FontWeight.w600),
//                               overflow: TextOverflow.ellipsis,
//                               softWrap: true,
//                               maxLines: 1,
//                             ),
//                             Padding(
//                                 padding: EdgeInsetsDirectional.only(top: 3.0),
//                                 child: Text(
//                                   day,
//                                   style: Theme.of(this.context)
//                                       .textTheme
//                                       .caption
//                                       ?.copyWith(
//                                         color: Theme.of(context)
//                                             .colorScheme
//                                             .fontColor
//                                             .withOpacity(0.8),
//                                       ),
//                                   overflow: TextOverflow.ellipsis,
//                                   softWrap: true,
//                                   maxLines: 1,
//                                 )),
//                             Padding(
//                                 padding: EdgeInsetsDirectional.only(top: 3.0),
//                                 child: Text(
//                                   weatherData!.text!,
//                                   style: Theme.of(this.context)
//                                       .textTheme
//                                       .caption
//                                       ?.copyWith(
//                                         color: Theme.of(context)
//                                             .colorScheme
//                                             .fontColor
//                                             .withOpacity(0.8),
//                                       ),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                   softWrap: true,
//                                 )),
//                             Padding(
//                                 padding: EdgeInsetsDirectional.only(top: 3.0),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   mainAxisAlignment: MainAxisAlignment.end,
//                                   children: <Widget>[
//                                     Icon(Icons.arrow_upward_outlined,
//                                         size: 13.0,
//                                         color: Theme.of(context)
//                                             .colorScheme
//                                             .fontColor),
//                                     Text(
//                                       "H:${weatherData!.maxTempC!.toString()}\u2103",
//                                       style: Theme.of(this.context)
//                                           .textTheme
//                                           .caption
//                                           ?.copyWith(
//                                             color: Theme.of(context)
//                                                 .colorScheme
//                                                 .fontColor
//                                                 .withOpacity(0.8),
//                                           ),
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                       softWrap: true,
//                                     ),
//                                     Padding(
//                                         padding: EdgeInsetsDirectional.only(
//                                             start: 8.0),
//                                         child: Icon(Icons.arrow_downward_outlined,
//                                             size: 13.0,
//                                             color: Theme.of(context)
//                                                 .colorScheme
//                                                 .fontColor)),
//                                     Text(
//                                       "L:${weatherData!.minTempC!.toString()}\u2103",
//                                       style: Theme.of(this.context)
//                                           .textTheme
//                                           .caption
//                                           ?.copyWith(
//                                             color: Theme.of(context)
//                                                 .colorScheme
//                                                 .fontColor
//                                                 .withOpacity(0.8),
//                                           ),
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                       softWrap: true,
//                                     ),
//                                   ],
//                                 ))
//                           ],
//                         ),
//                     )
//                     : Container()
//               ],
//             ))
//         : weatherShimmer();
//   }

//   weatherShimmer() {
//     return Shimmer.fromColors(
//         baseColor: Colors.grey.withOpacity(0.4),
//         highlightColor: Colors.grey.withOpacity(0.4),
//         child: Container(
//           height: 98,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(10.0),
//             color: Theme.of(context).colorScheme.lightColor,
//           ),
//         ));
//   }

//   //get live news video
//   Future<void> getLiveNews() async {
//     _isNetworkAvail = await isNetworkAvailable();
//     if (_isNetworkAvail) {
//       var parameter = {ACCESS_KEY: access_key};

//       http.Response response = await http
//           .post(Uri.parse(getLiveStreamingApi),
//               body: parameter, headers: headers)
//           .timeout(Duration(seconds: timeOut));
//       var getdata = json.decode(response.body);
//       String error = getdata["error"];

//       if (error == "false") {
//         isliveNews = getdata["data"];
//       } else {
//         isliveNews = "";
//       }
//     } else
//       setSnackbar(getTranslated(context, 'internetmsg')!);
//   }

//   Widget liveWithSearchView() {
//     return Padding(
//         padding: EdgeInsets.only(top: 20.0),
//         child: Row(
//           children: [
//             liveStreaming_mode == "1" && isliveNews != "" && isliveNews != null
//                 ? Expanded(
//                     flex: 9,
//                     child: InkWell(
//                       child: Padding(
//                           padding: EdgeInsetsDirectional.only(end: 0.0),
//                           child: Container(
//                               height: 60,
//                               // width: _folded ? deviceWidth! - 120 : 80,
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(10.0),
//                                 color: Theme.of(context).colorScheme.lightColor,
//                                 boxShadow: [
//                                   BoxShadow(
//                                       blurRadius: 10.0,
//                                       offset: const Offset(12.0, 15.0),
//                                       color:
//                                           colors.tempdarkColor.withOpacity(0.2),
//                                       spreadRadius: -7),
//                                 ],
//                               ),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   SvgPicture.asset(
//                                     "assets/images/live_news.svg",
//                                     semanticsLabel: 'live news',
//                                     height: 21.0,
//                                     width: 21.0,
//                                     color:
//                                         Theme.of(context).colorScheme.fontColor,
//                                   ),
//                                   Padding(
//                                       padding: EdgeInsetsDirectional.only(
//                                           start: 8.0),
//                                       child: Text(
//                                         getTranslated(context, 'liveNews')!,
//                                         style: Theme.of(this.context)
//                                             .textTheme
//                                             .subtitle1
//                                             ?.copyWith(
//                                                 color: Theme.of(context)
//                                                     .colorScheme
//                                                     .fontColor,
//                                                 fontWeight: FontWeight.w600),
//                                       ))
//                                 ],
//                               ))),
//                       onTap: () {
//                         if (_isNetworkAvail) {
//                           if (isliveNews != "" && isliveNews != null) {
//                             Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => Live(
//                                     liveNews: isliveNews,
//                                   ),
//                                 ));
//                           }
//                         } else {
//                           setSnackbar(getTranslated(context, 'internetmsg')!);
//                         }
//                       },
//                     ))
//                 : Container(),
//             liveStreaming_mode == "1" && isliveNews != "" && isliveNews != null
//                 ? Expanded(
//                     flex: 3,
//                     child: Padding(
//                         padding: EdgeInsetsDirectional.only(start: 10.0),
//                         child: InkWell(
//                           child: Container(
//                               alignment: Alignment.center,
//                               height: 60,
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(10.0),
//                                 color: Theme.of(context).colorScheme.lightColor,
//                                 boxShadow: [
//                                   BoxShadow(
//                                       blurRadius: 10.0,
//                                       offset: const Offset(12.0, 15.0),
//                                       color:
//                                           colors.tempdarkColor.withOpacity(0.2),
//                                       spreadRadius: -7),
//                                 ],
//                               ),
//                               child: Padding(
//                                 padding: EdgeInsetsDirectional.only(start: 0.0),
//                                 child: SvgPicture.asset(
//                                   "assets/images/search_icon.svg",
//                                   height: 18,
//                                   width: 18,
//                                   color:
//                                       Theme.of(context).colorScheme.fontColor,
//                                 ),
//                               )),
//                           onTap: () {
//                             // setState(() {
//                             // _folded = !_folded;
//                             //});
//                             Navigator.of(context).push(MaterialPageRoute(
//                                 builder: (BuildContext context) => Search()));
//                           },
//                         )))
//                 : InkWell(
//                     child: Container(
//                             width: deviceWidth! - 30,

//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Container(

//                               alignment: Alignment.center,
//                               height: 60,
//                     child:Image.asset("assets/images/splash_Icon.png",)
//                           ),
//                           Container(
//                               alignment: Alignment.center,
//                               height: 60,
//                               width: 60,
//                               // width: deviceWidth! - 30,
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(10.0),
//                                 color: Theme.of(context).colorScheme.lightColor,
//                                 boxShadow: [
//                                   BoxShadow(
//                                       blurRadius: 10.0,
//                                       offset: const Offset(12.0, 15.0),
//                                       color: colors.tempdarkColor.withOpacity(0.2),
//                                       spreadRadius: -7),
//                                 ],
//                               ),
//                               child: Padding(
//                                   padding: EdgeInsetsDirectional.only(start: 0.0),
//                                   child: Row(
//                                       mainAxisAlignment: MainAxisAlignment.center,
//                                       children: [
//                                         SvgPicture.asset(
//                                           "assets/images/search_icon.svg",
//                                           height: 18,
//                                           width: 18,
//                                           color:
//                                               Theme.of(context).colorScheme.fontColor,
//                                         ),
//                                       ]))),
//                         ],
//                       ),
//                     ),
//                     onTap: () {
//                       Navigator.of(context).push(MaterialPageRoute(
//                           builder: (BuildContext context) => Search()));
//                     },
//                   )
//           ],
//         ));
//   }

//   updateHome() {
//     setState(() {});
//   }

//   loadWeather() async {
//     loc.LocationData locationData;

//     _serviceEnabled = await _location.serviceEnabled();
//     if (!_serviceEnabled!) {
//       _serviceEnabled = await _location.requestService();
//       if (!_serviceEnabled!) {
//         return;
//       }
//     }

//     _permissionGranted = await _location.hasPermission();
//     if (_permissionGranted == PermissionStatus.denied) {
//       _permissionGranted = await _location.requestPermission();
//       if (_permissionGranted != PermissionStatus.granted) {
//         return;
//       }
//     }
//     locationData = await _location.getLocation();

//     error = null;

//     final lat = locationData.latitude;
//     final lon = locationData.longitude;
//     final weatherResponse = await http.get(Uri.parse(
//         'https://api.weatherapi.com/v1/forecast.json?key=d0f2f4dbecc043e78d6123135212408&q=${lat.toString()},${lon.toString()}&days=1&aqi=no&alerts=no'));

//     if (weatherResponse.statusCode == 200) {
//       if (this.mounted)
//         return setState(() {
//           weatherData =
//               new WeatherData.fromJson(jsonDecode(weatherResponse.body));
//           weatherLoad = false;
//         });
//     }

//     setState(() {
//       weatherLoad = false;
//     });
//   }

//   Widget viewBreakingNews() {
//     return Padding(
//         padding: EdgeInsetsDirectional.only(
//           top: 15.0,
//         ),
//         child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                   padding: EdgeInsetsDirectional.only(start: 8.0),
//                   child: Text(
//                     getTranslated(context, 'breakingNews_lbl')!,
//                     style: Theme.of(context).textTheme.subtitle1?.copyWith(
//                         color: Theme.of(context)
//                             .colorScheme
//                             .fontColor
//                             .withOpacity(0.9),
//                         fontWeight: FontWeight.w600),
//                   )),
//               _isBreakLoading
//                   ? newsShimmer()
//                   : breakingNewsList.length == 0
//                       ? Center(
//                           child: Text(
//                               getTranslated(context, 'breaking_not_avail')!,
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .subtitle1
//                                   ?.copyWith(
//                                       color: Theme.of(context)
//                                           .colorScheme
//                                           .fontColor
//                                           .withOpacity(0.8))))
//                       : SizedBox(
//                           height: 250.0,
//                           child: ListView.builder(
//                             physics: AlwaysScrollableScrollPhysics(),
//                             scrollDirection: Axis.horizontal,
//                             shrinkWrap: true,
//                             itemCount: breakingNewsList.length,
//                             itemBuilder: (context, index) {
//                               return breakingNewsItem(index);
//                             },
//                           ))
//             ]));
//   }

//   Widget viewRecentContent() {
//     return Padding(
//         padding: EdgeInsetsDirectional.only(
//           top: 15.0,
//         ),
//         child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                   padding: EdgeInsetsDirectional.only(start: 8.0),
//                   child: Text(
//                     getTranslated(context, 'recentNews_lbl')!,
//                     style: Theme.of(context).textTheme.subtitle1?.copyWith(
//                         color: Theme.of(context)
//                             .colorScheme
//                             .fontColor
//                             .withOpacity(0.9),
//                         fontWeight: FontWeight.w600),
//                   )),
//               _isRecentLoading
//                   ? newsShimmer()
//                   : recentNewsList.length == 0
//                       ? Center(
//                           child: Text(getTranslated(context, 'recent_no_news')!,
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .subtitle1
//                                   ?.copyWith(
//                                       color: Theme.of(context)
//                                           .colorScheme
//                                           .fontColor
//                                           .withOpacity(0.8))))
//                       : SizedBox(
//                           height: 250.0,
//                           child: ListView.builder(
//                             physics: AlwaysScrollableScrollPhysics(),
//                             scrollDirection: Axis.horizontal,
//                             shrinkWrap: true,
//                             controller: controller,
//                             itemCount: (offsetRecent < totalRecent)
//                                 ? recentNewsList.length + 1
//                                 : recentNewsList.length,
//                             itemBuilder: (context, index) {
//                               return (index == recentNewsList.length &&
//                                       _isRecentLoadMore)
//                                   ? Center(child: CircularProgressIndicator())
//                                   : recentNewsItem(index);
//                             },
//                           ))
//             ]));
//   }

//   Widget viewUserNewsContent() {
//     return Padding(
//         padding: EdgeInsetsDirectional.only(
//           top: 15.0,
//         ),
//         child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                   padding: EdgeInsetsDirectional.only(start: 8.0),
//                   child: Text(
//                     getTranslated(context, 'forYou_lbl')!,
//                     style: Theme.of(context).textTheme.subtitle1?.copyWith(
//                         color: Theme.of(context)
//                             .colorScheme
//                             .fontColor
//                             .withOpacity(0.9),
//                         fontWeight: FontWeight.w600),
//                   )),
//               _isUserLoading
//                   ? newsShimmer()
//                   : userNewsList.length == 0
//                       ? Center(
//                           child: Text(userNews_not_avail,
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .subtitle1
//                                   ?.copyWith(
//                                       color: Theme.of(context)
//                                           .colorScheme
//                                           .fontColor
//                                           .withOpacity(0.8))))
//                       : SizedBox(
//                           height: 250.0,
//                           child: ListView.builder(
//                             physics: AlwaysScrollableScrollPhysics(),
//                             scrollDirection: Axis.horizontal,
//                             shrinkWrap: true,
//                             controller: controller1,
//                             itemCount: (offsetUser < totalUser)
//                                 ? userNewsList.length + 1
//                                 : userNewsList.length,
//                             itemBuilder: (context, index) {
//                               return (index == userNewsList.length &&
//                                       _isUserLoadMore)
//                                   ? Center(child: CircularProgressIndicator())
//                                   : userNewsItem(index);
//                             },
//                           ))
//             ]));
//   }

//   Widget catText() {
//     return Padding(
//         padding: EdgeInsetsDirectional.only(top: 20.0, bottom: 20.0),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Expanded(
//                 flex: 2,
//                 child: Divider(
//                   color:
//                       Theme.of(context).colorScheme.fontColor.withOpacity(0.7),
//                   endIndent: 20,
//                   thickness: 1.0,
//                 )),
//             Text(
//               getTranslated(context, 'category_lbl')!,
//               style: Theme.of(context).textTheme.subtitle1?.merge(TextStyle(
//                     color: Theme.of(context)
//                         .colorScheme
//                         .fontColor
//                         .withOpacity(0.7),
//                   )),
//             ),
//             Expanded(
//                 flex: 7,
//                 child: Divider(
//                   color:
//                       Theme.of(context).colorScheme.fontColor.withOpacity(0.7),
//                   indent: 20,
//                   thickness: 1.0,
//                 )),
//           ],
//         ));
//   }

//   newsShimmer() {
//     return Shimmer.fromColors(
//         baseColor: Colors.grey.withOpacity(0.6),
//         highlightColor: Colors.grey,
//         child: SingleChildScrollView(
//           //padding: EdgeInsetsDirectional.only(start: 5.0, top: 20.0),
//           scrollDirection: Axis.horizontal,
//           child: Row(
//               children: [0, 1, 2, 3, 4, 5, 6]
//                   .map((i) => Padding(
//                       padding: EdgeInsetsDirectional.only(
//                           top: 15.0, start: i == 0 ? 0 : 6.0),
//                       child: Stack(children: [
//                         Container(
//                           decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(10.0),
//                               color: Colors.grey.withOpacity(0.6)),
//                           height: 240.0,
//                           width: 195.0,
//                         ),
//                         Positioned.directional(
//                             textDirection: Directionality.of(context),
//                             bottom: 7.0,
//                             start: 7,
//                             end: 7,
//                             height: 99,
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(10.0),
//                                 color: Colors.grey,
//                               ),
//                             )),
//                       ])))
//                   .toList()),
//         ));
//   }

//   recentNewsItem(int index) {
//     List<String> tagList = [];
//     DateTime time1 = DateTime.parse(recentNewsList[index].date!);
//     if (recentNewsList[index].tagName! != "") {
//       final tagName = recentNewsList[index].tagName!;
//       tagList = tagName.split(',');
//     }

//     List<String> tagId = [];

//     if (recentNewsList[index].tagId! != "") {
//       tagId = recentNewsList[index].tagId!.split(",");
//     }

//     allImage.clear();

//     allImage.add(recentNewsList[index].image!);
//     if (recentNewsList[index].imageDataList!.length != 0) {
//       for (int i = 0; i < recentNewsList[index].imageDataList!.length; i++) {
//         allImage.add(recentNewsList[index].imageDataList![i].otherImage!);
//       }
//     }

//     return Padding(
//       padding:
//           EdgeInsetsDirectional.only(top: 15.0, start: index == 0 ? 0 : 6.0),
//       child: Hero(
//         tag: recentNewsList[index].id!,
//         child: InkWell(
//           child: Stack(
//             children: <Widget>[
//               ClipRRect(
//                   borderRadius: BorderRadius.circular(10.0),
//                   child: FadeInImage(
//                       fadeInDuration: Duration(milliseconds: 150),
//                       image: CachedNetworkImageProvider(
//                           recentNewsList[index].image!),
//                       height: 250.0,
//                       width: 450.0,
//                       fit: BoxFit.cover,
//                       imageErrorBuilder: (context, error, stackTrace) =>
//                           errorWidget(250, 450),
//                       placeholder: AssetImage(
//                         placeHolder,
//                       ))),
//               Positioned.directional(
//                   textDirection: Directionality.of(context),
//                   bottom: 7.0,
//                   start: 7,
//                   end: 7,
//                   height: 99,
//                   child: ClipRRect(
//                       borderRadius: BorderRadius.circular(10.0),
//                       child: BackdropFilter(
//                           filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
//                           child: Container(
//                             alignment: Alignment.center,
//                             padding: EdgeInsets.all(10.0),
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(10.0),
//                               color: colors.tempboxColor.withOpacity(0.85),
//                             ),
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: <Widget>[
//                                 Text(
//                                   convertToAgo(time1, 0)!,
//                                   style: Theme.of(context)
//                                       .textTheme
//                                       .caption
//                                       ?.copyWith(
//                                           color: colors.tempdarkColor,
//                                           fontSize: 10.0),
//                                 ),
//                                 Padding(
//                                     padding: EdgeInsets.only(top: 4.0),
//                                     child: Text(
//                                       recentNewsList[index].title!,
//                                       style: Theme.of(context)
//                                           .textTheme
//                                           .subtitle2
//                                           ?.copyWith(
//                                               color: colors.tempdarkColor
//                                                   .withOpacity(0.9),
//                                               fontWeight: FontWeight.w600,
//                                               fontSize: 12.5,
//                                               height: 1.0),
//                                       maxLines: 3,
//                                       softWrap: true,
//                                       overflow: TextOverflow.ellipsis,
//                                     )),
//                                 Padding(
//                                     padding: EdgeInsets.only(top: 4.0),
//                                     child: Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: <Widget>[
//                                         recentNewsList[index].tagName! != ""
//                                             ? SizedBox(
//                                                 height: 16.0,
//                                                 child: ListView.builder(
//                                                     physics:
//                                                         AlwaysScrollableScrollPhysics(),
//                                                     scrollDirection:
//                                                         Axis.horizontal,
//                                                     shrinkWrap: true,
//                                                     itemCount:
//                                                         tagList.length >= 2
//                                                             ? 2
//                                                             : tagList.length,
//                                                     itemBuilder:
//                                                         (context, index) {
//                                                       return Padding(
//                                                           padding: EdgeInsetsDirectional
//                                                               .only(
//                                                                   start:
//                                                                       index == 0
//                                                                           ? 0
//                                                                           : 1.5),
//                                                           child: InkWell(
//                                                             child: Container(
//                                                                 height: 16.0,
//                                                                 width: 45,
//                                                                 alignment:
//                                                                     Alignment
//                                                                         .center,
//                                                                 padding: EdgeInsetsDirectional
//                                                                     .only(
//                                                                         start:
//                                                                             3.0,
//                                                                         end:
//                                                                             3.0,
//                                                                         top:
//                                                                             2.5,
//                                                                         bottom:
//                                                                             2.5),
//                                                                 decoration:
//                                                                     BoxDecoration(
//                                                                   borderRadius:
//                                                                       BorderRadius
//                                                                           .circular(
//                                                                               3.0),
//                                                                   color: colors
//                                                                       .primary
//                                                                       .withOpacity(
//                                                                           0.08),
//                                                                 ),
//                                                                 child: Text(
//                                                                   tagList[
//                                                                       index],
//                                                                   style: Theme.of(
//                                                                           context)
//                                                                       .textTheme
//                                                                       .bodyText2
//                                                                       ?.copyWith(
//                                                                         color: colors
//                                                                             .primary,
//                                                                         fontSize:
//                                                                             9.5,
//                                                                       ),
//                                                                   overflow:
//                                                                       TextOverflow
//                                                                           .ellipsis,
//                                                                   softWrap:
//                                                                       true,
//                                                                 )),
//                                                             onTap: () async {
//                                                               Navigator.push(
//                                                                   context,
//                                                                   MaterialPageRoute(
//                                                                     builder:
//                                                                         (context) =>
//                                                                             NewsTag(
//                                                                       tadId: tagId[
//                                                                           index],
//                                                                       tagName:
//                                                                           tagList[
//                                                                               index],
//                                                                       updateParent:
//                                                                           updateHomePage,
//                                                                     ),
//                                                                   ));
//                                                             },
//                                                           ));
//                                                     }))
//                                             : Container(),
//                                         Spacer(),
//                                         InkWell(
//                                           child: SvgPicture.asset(
//                                             bookMarkValue.contains(
//                                                     recentNewsList[index].id)
//                                                 ? "assets/images/bookmarkfilled_icon.svg"
//                                                 : "assets/images/bookmark_icon.svg",
//                                             semanticsLabel: 'bookmark icon',
//                                             height: 14,
//                                             width: 14,
//                                           ),
//                                           onTap: () async {
//                                             _isNetworkAvail =
//                                                 await isNetworkAvailable();
//                                             if (CUR_USERID != "") {
//                                               if (_isNetworkAvail) {
//                                                 setState(() {
//                                                   bookMarkValue.contains(
//                                                           recentNewsList[index]
//                                                               .id!)
//                                                       ? _setBookmark(
//                                                           "0",
//                                                           recentNewsList[index]
//                                                               .id!)
//                                                       : _setBookmark(
//                                                           "1",
//                                                           recentNewsList[index]
//                                                               .id!);
//                                                 });
//                                               } else {
//                                                 setSnackbar(getTranslated(
//                                                     context, 'internetmsg')!);
//                                               }
//                                             } else {
//                                               Navigator.push(
//                                                   context,
//                                                   MaterialPageRoute(
//                                                     builder: (context) =>
//                                                         Login(),
//                                                   ));
//                                             }
//                                           },
//                                         ),
//                                         Padding(
//                                           padding: EdgeInsetsDirectional.only(
//                                               start: 8.0),
//                                           child: InkWell(
//                                             child: SvgPicture.asset(
//                                               "assets/images/share_icon.svg",
//                                               semanticsLabel: 'share icon',
//                                               height: 13,
//                                               width: 13,
//                                             ),
//                                             onTap: () async {
//                                               _isNetworkAvail =
//                                                   await isNetworkAvailable();
//                                               if (_isNetworkAvail) {
//                                                 createDynamicLink(
//                                                     recentNewsList[index].id!,
//                                                     index,
//                                                     recentNewsList[index]
//                                                         .title!);
//                                               } else {
//                                                 setSnackbar(getTranslated(
//                                                     context, 'internetmsg')!);
//                                               }
//                                             },
//                                           ),
//                                         )
//                                       ],
//                                     ))
//                               ],
//                             ),
//                           )))),
//               Positioned.directional(
//                   textDirection: Directionality.of(context),
//                   bottom: (250 - 80) / 2,
//                   start: 400 - 65,
//                   child: InkWell(
//                     child: ClipRRect(
//                         borderRadius: BorderRadius.circular(40.0),
//                         child: BackdropFilter(
//                             filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                             child: Container(
//                               height: 40,
//                               width: 40,
//                               padding: EdgeInsets.all(10.5),
//                               decoration: BoxDecoration(
//                                   color: colors.tempboxColor.withOpacity(0.7),
//                                   shape: BoxShape.circle),
//                               child: SvgPicture.asset(
//                                 recentNewsList[index].like == "1"
//                                     ? "assets/images/likefilled_button.svg"
//                                     : "assets/images/Like_icon.svg",
//                                 semanticsLabel: 'like icon',
//                               ),
//                             ))),
//                     onTap: () async {
//                       _isNetworkAvail = await isNetworkAvailable();

//                       if (CUR_USERID != "") {
//                         if (_isNetworkAvail) {
//                           if (!isFirst) {
//                             setState(() {
//                               isFirst = true;
//                             });
//                             if (recentNewsList[index].like == "1") {
//                               _setLikesDisLikes(
//                                   "0", recentNewsList[index].id!, index, 1);

//                               setState(() {});
//                             } else {
//                               _setLikesDisLikes(
//                                   "1", recentNewsList[index].id!, index, 1);
//                               setState(() {});
//                             }
//                           } else {
//                             setSnackbar(getTranslated(context, 'internetmsg')!);
//                           }
//                         } else {
//                           Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => Login(),
//                               ));
//                         }
//                       }
//                     },
//                   ))
//             ],
//           ),
//           onTap: () {
//             News model = recentNewsList[index];
//             List<News> recList = [];
//             recList.addAll(recentNewsList);
//             recList.removeAt(index);
//             Navigator.of(context).push(MaterialPageRoute(
//                 builder: (BuildContext context) => NewsDetails(
//                       model: model,
//                       index: index,
//                       updateParent: updateHomePage,
//                       id: model.id,
//                       isFav: false,
//                       isDetails: true,
//                       news: recList,
//                     )));
//           },
//         ),
//       ),
//     );
//   }

//   userNewsItem(int index) {
//     List<String> tagList = [];
//     DateTime time1 = DateTime.parse(userNewsList[index].date!);
//     if (userNewsList[index].tagName! != "") {
//       final tagName = userNewsList[index].tagName!;
//       tagList = tagName.split(',');
//     }

//     List<String> tagId = [];

//     if (userNewsList[index].tagId! != "") {
//       tagId = userNewsList[index].tagId!.split(",");
//     }

//     allImage.clear();

//     allImage.add(userNewsList[index].image!);
//     if (userNewsList[index].imageDataList!.length != 0) {
//       for (int i = 0; i < userNewsList[index].imageDataList!.length; i++) {
//         allImage.add(userNewsList[index].imageDataList![i].otherImage!);
//       }
//     }

//     return Padding(
//       padding:
//           EdgeInsetsDirectional.only(top: 15.0, start: index == 0 ? 0 : 6.0),
//       child: Hero(
//         tag: userNewsList[index].id!,
//         child: InkWell(
//           child: Stack(
//             children: <Widget>[
//               ClipRRect(
//                   borderRadius: BorderRadius.circular(10.0),
//                   child: FadeInImage(
//                       fadeInDuration: Duration(milliseconds: 150),
//                       image: CachedNetworkImageProvider(
//                           userNewsList[index].image!),
//                       height: 250.0,
//                       width: 193.0,
//                       fit: BoxFit.cover,
//                       imageErrorBuilder: (context, error, stackTrace) =>
//                           errorWidget(250, 193),
//                       placeholder: AssetImage(
//                         placeHolder,
//                       ))),
//               Positioned.directional(
//                   textDirection: Directionality.of(context),
//                   bottom: 7.0,
//                   start: 7,
//                   end: 7,
//                   height: 99,
//                   child: ClipRRect(
//                       borderRadius: BorderRadius.circular(10.0),
//                       child: BackdropFilter(
//                           filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
//                           child: Container(
//                             alignment: Alignment.center,
//                             padding: EdgeInsets.all(10.0),
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(10.0),
//                               color: colors.tempboxColor.withOpacity(0.85),
//                             ),
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: <Widget>[
//                                 Text(
//                                   convertToAgo(time1, 0)!,
//                                   style: Theme.of(context)
//                                       .textTheme
//                                       .caption
//                                       ?.copyWith(
//                                           color: colors.tempdarkColor,
//                                           fontSize: 10.0),
//                                 ),
//                                 Padding(
//                                     padding: EdgeInsets.only(top: 4.0),
//                                     child: Text(
//                                       userNewsList[index].title!,
//                                       style: Theme.of(context)
//                                           .textTheme
//                                           .subtitle2
//                                           ?.copyWith(
//                                               color: colors.tempdarkColor
//                                                   .withOpacity(0.9),
//                                               fontWeight: FontWeight.w600,
//                                               fontSize: 12.5,
//                                               height: 1.0),
//                                       maxLines: 3,
//                                       softWrap: true,
//                                       overflow: TextOverflow.ellipsis,
//                                     )),
//                                 Padding(
//                                     padding: EdgeInsets.only(top: 4.0),
//                                     child: Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: <Widget>[
//                                         userNewsList[index].tagName! != ""
//                                             ? SizedBox(
//                                                 height: 16.0,
//                                                 child: ListView.builder(
//                                                     physics:
//                                                         AlwaysScrollableScrollPhysics(),
//                                                     scrollDirection:
//                                                         Axis.horizontal,
//                                                     shrinkWrap: true,
//                                                     itemCount:
//                                                         tagList.length >= 2
//                                                             ? 2
//                                                             : tagList.length,
//                                                     itemBuilder:
//                                                         (context, index) {
//                                                       return Padding(
//                                                           padding: EdgeInsetsDirectional
//                                                               .only(
//                                                                   start:
//                                                                       index == 0
//                                                                           ? 0
//                                                                           : 1.5),
//                                                           child: InkWell(
//                                                             child: Container(
//                                                                 height: 16.0,
//                                                                 width: 45,
//                                                                 alignment:
//                                                                     Alignment
//                                                                         .center,
//                                                                 padding: EdgeInsetsDirectional
//                                                                     .only(
//                                                                         start:
//                                                                             3.0,
//                                                                         end:
//                                                                             3.0,
//                                                                         top:
//                                                                             2.5,
//                                                                         bottom:
//                                                                             2.5),
//                                                                 decoration:
//                                                                     BoxDecoration(
//                                                                   borderRadius:
//                                                                       BorderRadius
//                                                                           .circular(
//                                                                               3.0),
//                                                                   color: colors
//                                                                       .primary
//                                                                       .withOpacity(
//                                                                           0.08),
//                                                                 ),
//                                                                 child: Text(
//                                                                   tagList[
//                                                                       index],
//                                                                   style: Theme.of(
//                                                                           context)
//                                                                       .textTheme
//                                                                       .bodyText2
//                                                                       ?.copyWith(
//                                                                         color: colors
//                                                                             .primary,
//                                                                         fontSize:
//                                                                             9.5,
//                                                                       ),
//                                                                   overflow:
//                                                                       TextOverflow
//                                                                           .ellipsis,
//                                                                   softWrap:
//                                                                       true,
//                                                                 )),
//                                                             onTap: () {
//                                                               Navigator.push(
//                                                                   context,
//                                                                   MaterialPageRoute(
//                                                                     builder:
//                                                                         (context) =>
//                                                                             NewsTag(
//                                                                       tadId: tagId[
//                                                                           index],
//                                                                       tagName:
//                                                                           tagList[
//                                                                               index],
//                                                                       updateParent:
//                                                                           updateHomePage,
//                                                                     ),
//                                                                   ));
//                                                             },
//                                                           ));
//                                                     }))
//                                             : Container(),
//                                         Spacer(),
//                                         InkWell(
//                                           child: SvgPicture.asset(
//                                             bookMarkValue.contains(
//                                                     userNewsList[index].id)
//                                                 ? "assets/images/bookmarkfilled_icon.svg"
//                                                 : "assets/images/bookmark_icon.svg",
//                                             semanticsLabel: 'bookmark icon',
//                                             height: 14,
//                                             width: 14,
//                                           ),
//                                           onTap: () async {
//                                             _isNetworkAvail =
//                                                 await isNetworkAvailable();
//                                             if (CUR_USERID != "") {
//                                               if (_isNetworkAvail) {
//                                                 setState(() {
//                                                   bookMarkValue.contains(
//                                                           userNewsList[index]
//                                                               .id!)
//                                                       ? _setBookmark(
//                                                           "0",
//                                                           userNewsList[index]
//                                                               .id!)
//                                                       : _setBookmark(
//                                                           "1",
//                                                           userNewsList[index]
//                                                               .id!);
//                                                 });
//                                               } else {
//                                                 setSnackbar(getTranslated(
//                                                     context, 'internetmsg')!);
//                                               }
//                                             } else {
//                                               Navigator.push(
//                                                   context,
//                                                   MaterialPageRoute(
//                                                     builder: (context) =>
//                                                         Login(),
//                                                   ));
//                                             }
//                                           },
//                                         ),
//                                         Padding(
//                                           padding: EdgeInsetsDirectional.only(
//                                               start: 8.0),
//                                           child: InkWell(
//                                             child: SvgPicture.asset(
//                                               "assets/images/share_icon.svg",
//                                               semanticsLabel: 'share icon',
//                                               height: 13,
//                                               width: 13,
//                                             ),
//                                             onTap: () async {
//                                               _isNetworkAvail =
//                                                   await isNetworkAvailable();
//                                               if (_isNetworkAvail) {
//                                                 createDynamicLink(
//                                                     userNewsList[index].id!,
//                                                     index,
//                                                     userNewsList[index].title!);
//                                               } else {
//                                                 setSnackbar(getTranslated(
//                                                     context, 'internetmsg')!);
//                                               }
//                                             },
//                                           ),
//                                         )
//                                       ],
//                                     ))
//                               ],
//                             ),
//                           )))),
//               Positioned.directional(
//                   textDirection: Directionality.of(context),
//                   bottom: (250 - 80) / 2,
//                   start: 190 - 65,
//                   child: InkWell(
//                     child: ClipRRect(
//                         borderRadius: BorderRadius.circular(40.0),
//                         child: BackdropFilter(
//                             filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                             child: Container(
//                               height: 40,
//                               width: 40,
//                               padding: EdgeInsets.all(10.5),
//                               decoration: BoxDecoration(
//                                   color: colors.tempboxColor.withOpacity(0.7),
//                                   shape: BoxShape.circle),
//                               child: SvgPicture.asset(
//                                 userNewsList[index].like == "1"
//                                     ? "assets/images/likefilled_button.svg"
//                                     : "assets/images/Like_icon.svg",
//                                 semanticsLabel: 'like icon',
//                               ),
//                             ))),
//                     onTap: () async {
//                       _isNetworkAvail = await isNetworkAvailable();

//                       if (CUR_USERID != "") {
//                         if (_isNetworkAvail) {
//                           if (userNewsList[index].like == "1") {
//                             _setLikesDisLikes(
//                                 "0", userNewsList[index].id!, index, 2);
//                             setState(() {});
//                           } else {
//                             _setLikesDisLikes(
//                                 "1", userNewsList[index].id!, index, 2);
//                             setState(() {});
//                           }
//                         } else {
//                           setSnackbar(getTranslated(context, 'internetmsg')!);
//                         }
//                       } else {
//                         Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => Login(),
//                             ));
//                       }
//                     },
//                   ))
//             ],
//           ),
//           onTap: () {
//             News model = userNewsList[index];
//             List<News> usList = [];
//             usList.addAll(userNewsList);
//             usList.removeAt(index);
//             Navigator.of(context).push(MaterialPageRoute(
//                 builder: (BuildContext context) => NewsDetails(
//                       model: model,
//                       index: index,
//                       updateParent: updateHomePage,
//                       id: model.id,
//                       isFav: false,
//                       isDetails: true,
//                       news: usList,
//                     )));
//           },
//         ),
//       ),
//     );
//   }

//   breakingNewsItem(int index) {
//     return Padding(
//       padding:
//           EdgeInsetsDirectional.only(top: 15.0, start: index == 0 ? 0 : 6.0),
//       child: Hero(
//         tag: breakingNewsList[index].id!,
//         child: InkWell(
//           child: Stack(
//             children: <Widget>[
//               ClipRRect(
//                   borderRadius: BorderRadius.circular(10.0),
//                   child: FadeInImage(
//                       fadeInDuration: Duration(milliseconds: 150),
//                       image: CachedNetworkImageProvider(
//                           breakingNewsList[index].image!),
//                       height: 250.0,
//                       width: 193.0,
//                       fit: BoxFit.cover,
//                       imageErrorBuilder: (context, error, stackTrace) =>
//                           errorWidget(250, 193),
//                       placeholder: AssetImage(
//                         placeHolder,
//                       ))),
//               Positioned.directional(
//                   textDirection: Directionality.of(context),
//                   bottom: 7.0,
//                   start: 7,
//                   end: 7,
//                   height: 62,
//                   child: ClipRRect(
//                       borderRadius: BorderRadius.circular(10.0),
//                       child: BackdropFilter(
//                           filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
//                           child: Container(
//                             alignment: Alignment.center,
//                             padding: EdgeInsets.all(10.0),
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(10.0),
//                               color: colors.tempboxColor.withOpacity(0.85),
//                             ),
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: <Widget>[
//                                 Text(
//                                   breakingNewsList[index].title!,
//                                   style: Theme.of(context)
//                                       .textTheme
//                                       .subtitle2
//                                       ?.copyWith(
//                                           color: colors.tempdarkColor
//                                               .withOpacity(0.9),
//                                           fontWeight: FontWeight.w600,
//                                           fontSize: 12.5,
//                                           height: 1.0),
//                                   maxLines: 3,
//                                   softWrap: true,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ],
//                             ),
//                           )))),
//             ],
//           ),
//           onTap: () {
//             BreakingNewsModel model = breakingNewsList[index];
//             List<BreakingNewsModel> tempBreak = [];
//             tempBreak.addAll(breakingNewsList);
//             tempBreak.removeAt(index);
//             Navigator.of(context).push(MaterialPageRoute(
//                 builder: (BuildContext context) => NewsDetails(
//                       model1: model,
//                       index: index,
//                       updateParent: updateHomePage,
//                       id: model.id,
//                       isFav: false,
//                       isDetails: false,
//                       news1: tempBreak,
//                       //updateHome: updateHome,
//                     )));
//           },
//         ),
//       ),
//     );
//   }

// //set likes of news using api
//   _setLikesDisLikes(String status, String id, int index, int from) async {
//     _isNetworkAvail = await isNetworkAvailable();
//     if (_isNetworkAvail) {
//       var param = {
//         ACCESS_KEY: access_key,
//         USER_ID: CUR_USERID,
//         NEWS_ID: id,
//         STATUS: status,
//       };

//       http.Response response = await http
//           .post(Uri.parse(setLikesDislikesApi), body: param, headers: headers)
//           .timeout(Duration(seconds: timeOut));

//       var getdata = json.decode(response.body);

//       String error = getdata["error"];

//       String msg = getdata["message"];

//       if (error == "false") {
//         if (status == "1") {
//           if (from == 1) {
//             recentNewsList[index].like = "1";
// recentNewsList[index].totalLikes =
//     (int.parse(recentNewsList[index].totalLikes!) + 1).toString();
//           } else {
//             userNewsList[index].like = "1";
//             userNewsList[index].totalLikes =
//                 (int.parse(userNewsList[index].totalLikes!) + 1).toString();
//           }
//           setSnackbar(getTranslated(context, 'like_succ')!);
//         } else if (status == "0") {
//           if (from == 1) {
//             recentNewsList[index].like = "0";
//             recentNewsList[index].totalLikes =
//                 (int.parse(recentNewsList[index].totalLikes!) - 1).toString();
//           } else {
//             userNewsList[index].like = "0";
//             userNewsList[index].totalLikes =
//                 (int.parse(userNewsList[index].totalLikes!) - 1).toString();
//           }
//           setSnackbar(getTranslated(context, 'dislike_succ')!);
//         }
//         setState(() {
//           isFirst = false;
//         });
//       }
//     } else {
//       setSnackbar(getTranslated(context, 'internetmsg')!);
//     }
//   }

//   updateHomePage() {
//     setState(() {
//       bookmarkList.clear();
//       bookMarkValue.clear();
//       _getBookmark();
//     });
//   }

// //show snackbar msg
//   setSnackbar(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
//       content: new Text(
//         msg,
//         textAlign: TextAlign.center,
//         style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
//       ),
//       backgroundColor: isDark! ? colors.tempdarkColor : colors.bgColor,
//       elevation: 1.0,
//     ));
//   }

// //get settings api
//   Future<void> getSetting() async {
//     _isNetworkAvail = await isNetworkAvailable();
//     if (_isNetworkAvail) {
//       try {
//         var param = {
//           ACCESS_KEY: access_key,
//         };
//         http.Response response = await http
//             .post(Uri.parse(getSettingApi), body: param, headers: headers)
//             .timeout(Duration(seconds: timeOut));
//         if (response.statusCode == 200) {
//           var getData = json.decode(response.body);
//           String error = getData["error"];
//           if (error == "false") {
//             var data = getData["data"];
//             category_mode = data[CATEGORY_MODE];
//             comments_mode = data[COMM_MODE];
//             breakingNews_mode = data[BREAK_NEWS_MODE];
//             liveStreaming_mode = data[LIVE_STREAM_MODE];
//             subCategory_mode = data[SUBCAT_MODE];
//             if (data.toString().contains(FB_REWARDED_ID)) {
//               fbRewardedVideoId = data[FB_REWARDED_ID];
//             }
//             if (data.toString().contains(FB_INTER_ID)) {
//               fbInterstitialId = data[FB_INTER_ID];
//             }
//             if (data.toString().contains(FB_BANNER_ID)) {
//               fbBannerId = data[FB_BANNER_ID];
//             }
//             if (data.toString().contains(FB_NATIVE_ID)) {
//               fbNativeUnitId = data[FB_NATIVE_ID];
//             }
//             if (data.toString().contains(IOS_FB_REWARDED_ID)) {
//               iosFbRewardedVideoId = data[IOS_FB_REWARDED_ID];
//             }
//             if (data.toString().contains(IOS_FB_INTER_ID)) {
//               iosFbInterstitialId = data[IOS_FB_INTER_ID];
//             }
//             if (data.toString().contains(IOS_FB_BANNER_ID)) {
//               iosFbBannerId = data[IOS_FB_BANNER_ID];
//             }
//             if (data.toString().contains(IOS_FB_NATIVE_ID)) {
//               iosFbNativeUnitId = data[IOS_FB_NATIVE_ID];
//             }

//             if (data.toString().contains(GO_REWARDED_ID)) {
//               goRewardedVideoId = data[GO_REWARDED_ID];
//             }
//             if (data.toString().contains(GO_INTER_ID)) {
//               goInterstitialId = data[GO_INTER_ID];
//             }
//             if (data.toString().contains(GO_BANNER_ID)) {
//               goBannerId = data[GO_BANNER_ID];
//             }
//             if (data.toString().contains(GO_NATIVE_ID)) {
//               goNativeUnitId = data[GO_NATIVE_ID];
//             }
//             if (data.toString().contains(IOS_GO_REWARDED_ID)) {
//               iosGoRewardedVideoId = data[IOS_GO_REWARDED_ID];
//             }
//             if (data.toString().contains(IOS_GO_INTER_ID)) {
//               iosGoInterstitialId = data[IOS_GO_INTER_ID];
//             }
//             if (data.toString().contains(IOS_GO_BANNER_ID)) {
//               iosGoBannerId = data[IOS_GO_BANNER_ID];
//             }
//             if (data.toString().contains(IOS_GO_NATIVE_ID)) {
//               iosGoNativeUnitId = data[IOS_GO_NATIVE_ID];
//             }

//           }
//         }
//       } on TimeoutException catch (_) {
//         setSnackbar(getTranslated(context, 'somethingMSg')!);
//       }
//     } else {
//       setSnackbar(getTranslated(context, 'internetmsg')!);
//     }
//   }

//   //get breaking news data list
//   Future<void> getBreakingNews() async {
//     _isNetworkAvail = await isNetworkAvailable();
//     if (_isNetworkAvail) {
//       try {
//         var param = {
//           ACCESS_KEY: access_key,
//         };
//         http.Response response = await http
//             .post(Uri.parse(getBreakingNewsApi), body: param, headers: headers)
//             .timeout(Duration(seconds: timeOut));
//         if (response.statusCode == 200) {
//           var getData = json.decode(response.body);
//           String error = getData["error"];
//           if (error == "false") {
//             tempBreakList.clear();
//             var data = getData["data"];
//             tempBreakList = (data as List)
//                 .map((data) => new BreakingNewsModel.fromJson(data))
//                 .toList();

//             breakingNewsList.addAll(tempBreakList);

//             setState(() {
//               _isBreakLoading = false;
//             });
//           }
//         }
//       } on TimeoutException catch (_) {
//         setSnackbar(getTranslated(context, 'somethingMSg')!);
//         setState(() {
//           _isBreakLoading = false;
//         });
//       }
//     } else {
//       setSnackbar(getTranslated(context, 'internetmsg')!);
//       setState(() {
//         _isBreakLoading = false;
//       });
//     }
//   }

//   _scrollListener() {
//     if (controller.offset >= controller.position.maxScrollExtent &&
//         !controller.position.outOfRange) {
//       if (this.mounted) {
//         setState(() {
//           _isRecentLoadMore = true;

//           if (offsetRecent < totalRecent) getNews();
//         });
//       }
//     }
//   }

//   _scrollListener1() {
//     if (controller1.offset >= controller1.position.maxScrollExtent &&
//         !controller1.position.outOfRange) {
//       if (this.mounted) {
//         setState(() {
//           _isUserLoadMore = true;

//           if (offsetUser < totalUser) getUserByCatNews();
//         });
//       }
//     }
//   }

// //get latest news data list
//   Future<void> getNews() async {
//     _isNetworkAvail = await isNetworkAvailable();
//     if (_isNetworkAvail) {
//       try {
//         var param = {
//           ACCESS_KEY: access_key,
//           LIMIT: perPage.toString(),
//           OFFSET: offsetRecent.toString(),
//           USER_ID: CUR_USERID != "" ? CUR_USERID : "0"
//         };

//         http.Response response = await http
//             .post(Uri.parse(getNewsApi), body: param, headers: headers)
//             .timeout(Duration(seconds: timeOut));

//         /* if (response.statusCode == 200) {
//           var getData = json.decode(response.body);
//           String error = getData["error"];
//           if (error == "false") {
//             totalUser = int.parse(getData["total"]);
//             if ((offsetUser) < totalUser) {
//               tempList.clear();
//               var data = getData["data"];
//               tempList = (data as List)
//                   .map((data) => new News.fromJson(data))
//                   .toList();
//               userNewsList.addAll(tempList);
//               offsetUser = offsetUser + perPage;
//             }
//           } else {
//             _isUserLoadMore = false;
//           }
//           if (mounted)
//             setState(() {
//               _isUserLoading = false;
//             });
//         }*/

//         if (response.statusCode == 200) {
//           var getData = json.decode(response.body);

//           String error = getData["error"];
//           if (error == "false") {
//             totalRecent = int.parse(getData["total"]);

//             if ((offsetRecent) < totalRecent) {
//               tempList.clear();
//               var data = getData["data"];
//               tempList = (data as List)
//                   .map((data) => new News.fromJson(data))
//                   .toList();

//               recentNewsList.addAll(tempList);

//               offsetRecent = offsetRecent + perPage;
//             }
//           } else {
//             _isRecentLoadMore = false;
//           }
//           if (mounted)
//             setState(() {
//               _isRecentLoading = false;
//             });
//         }
//       } on TimeoutException catch (_) {
//         setSnackbar(getTranslated(context, 'somethingMSg')!);
//         setState(() {
//           _isRecentLoading = false;
//           _isRecentLoadMore = false;
//         });
//       }
//     } else {
//       setSnackbar(getTranslated(context, 'internetmsg')!);
//       setState(() {
//         _isRecentLoading = false;
//         _isRecentLoadMore = false;
//       });
//     }
//   }

// //get all category using api
//   Future<void> getCat() async {
//     if (category_mode == "1") {
//       _isNetworkAvail = await isNetworkAvailable();
//       if (_isNetworkAvail) {
//         try {
//           var param = {
//             ACCESS_KEY: access_key,
//           };

//           http.Response response = await http
//               .post(Uri.parse(getCatApi), body: param, headers: headers)
//               .timeout(Duration(seconds: timeOut));
//           var getData = json.decode(response.body);
// log(getData.toString());
//           String error = getData["error"];
//           if (error == "false") {
//             tempCatList.clear();
//             var data = getData["data"];
//             tempCatList = (data as List)
//                 .map((data) => new Category.fromJson(data))
//                 .toList();
//             catList.addAll(tempCatList);
//             for (int i = 0; i < catList.length; i++) {
//               if (catList[i].subData!.length != 0) {
//                 catList[i].subData!.insert(
//                     0,
//                     SubCategory(
//                         id: "0",
//                         subCatName:
//                             "${getTranslated(context, 'all_lbl')! + "\t" + catList[i].categoryName!}"));
//               }
//             }

//             _tabs.clear();
//             this._addInitailTab();
//           }
//           if (mounted)
//             setState(() {
//               _isLoading = false;
//             });
//         } on TimeoutException catch (_) {
//           setSnackbar(getTranslated(context, 'somethingMSg')!);
//           setState(() {
//             _isLoading = false;
//             _isLoadingMore = false;
//           });
//         }
//       } else {
//         setSnackbar(getTranslated(context, 'internetmsg')!);
//         setState(() {
//           _isLoading = false;
//           _isLoadingMore = false;
//         });
//       }
//     } else {
//       setState(() {
//         _isLoading = false;
//         _isLoadingMore = false;
//       });
//     }
//   }

//   //get bookmark news list id using api
//   Future<void> _getBookmark() async {
//     if (CUR_USERID != "") {
//       _isNetworkAvail = await isNetworkAvailable();
//       if (_isNetworkAvail) {
//         try {
//           var param = {
//             ACCESS_KEY: access_key,
//             USER_ID: CUR_USERID,
//           };
//           http.Response response = await http
//               .post(Uri.parse(getBookmarkApi), body: param, headers: headers)
//               .timeout(Duration(seconds: timeOut));

//           var getdata = json.decode(response.body);

//           String error = getdata["error"];
//           if (error == "false") {
//             bookmarkList.clear();
//             var data = getdata["data"];

//             bookmarkList =
//                 (data as List).map((data) => new News.fromJson(data)).toList();
//             bookMarkValue.clear();

//             for (int i = 0; i < bookmarkList.length; i++) {
//               setState(() {
//                 bookMarkValue.add(bookmarkList[i].newsId);
//               });
//             }
//             if (mounted)
//               setState(() {
//                 _isLoading = false;
//               });
//           } else {
//             setState(() {
//               _isLoadingMore = false;
//               _isLoading = false;
//             });
//           }
//         } on TimeoutException catch (_) {
//           setSnackbar(getTranslated(context, 'somethingMSg')!);
//           setState(() {
//             _isLoading = false;
//           });
//         }
//       } else {
//         setSnackbar(getTranslated(context, 'internetmsg')!);
//       }
//     }
//   }
// }
