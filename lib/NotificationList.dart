import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart' as intl;
import 'package:news/Helper/Constant.dart';
import 'package:news/Helper/Session.dart';
import 'package:news/Helper/Color.dart';
import 'package:news/ListItemNotification.dart';
import 'package:news/Model/Notification.dart';
import 'package:news/appBarTitle.dart';
import 'package:shimmer/shimmer.dart';
import 'Helper/String.dart';
import 'Model/News.dart';
import 'NewsDetails.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NotificationList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => StateNoti();
}

class StateNoti extends State<NotificationList> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  ScrollController controller = new ScrollController();
  ScrollController controller1 = new ScrollController();

  List<NotificationModel> tempList = [];
  bool _isNetworkAvail = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey1 =
      new GlobalKey<RefreshIndicatorState>();
  TabController? _tc;
  List<NotificationModel> notiList = [];
  List<String> title = [
    "Things in general",
    "Particular groups of things",
    "The Myth of Multitasking",
    "How to Focus and Increase Your Attention Span",
    "Warren Buffett’s “2 List” Strategy for Focused Attention"
        "Things in general",
    "Particular groups of things",
    "The Myth of Multitasking",
    "How to Focus and Increase Your Attention Span",
    "Warren Buffett’s “2 List” Strategy for Focused Attention"
  ];
  List<String> desc = [
    "One of my favorite methods for focusing your attention on what matters and eliminating what doesn't comes from the famous investor Warren Buffett.",
    "Buffett uses a simple 3-step productivity strategy to help his employees determine their priorities and actions. You may find this method useful for making decisions and",
    "Buffett started by asking the pilot, named Mike Flint, to write down his top 25 career goals. So, Flint took some time and wrote them down. (Note: You could also",
    "Then, Buffett asked Flint to review his list and circle his top 5 goals. Again, Flint took some time, made his way through the list, and eventually decided on his 5 most important goals.",
    "At this point, Flint had two lists. The 5 items he had circled were List A, and the 20 items he had not circled were List B.",
    "One of my favorite methods for focusing your attention on what matters and eliminating what doesn't comes from the famous investor Warren Buffett.",
    "Buffett uses a simple 3-step productivity strategy to help his employees determine their priorities and actions. You may find this method useful for making decisions and",
    "Buffett started by asking the pilot, named Mike Flint, to write down his top 25 career goals. So, Flint took some time and wrote them down. (Note: You could also",
    "Then, Buffett asked Flint to review his list and circle his top 5 goals. Again, Flint took some time, made his way through the list, and eventually decided on his 5 most important goals.",
    "At this point, Flint had two lists. The 5 items he had circled were List A, and the 20 items he had not circled were List B.",
  ];
  List<String> images = [
    "https://www.simplilearn.com/ice9/free_resources_article_thumb/what_is_image_Processing.jpg",
    "https://www.pixsy.com/wp-content/uploads/2021/04/ben-sweet-2LowviVHZ-E-unsplash-1.jpeg",
    "https://avatars.mds.yandex.net/i?id=84dbd50839c3d640ebfc0de20994c30d-4473719-images-taas-consumers&n=27&h=480&w=480",
    "https://static.vecteezy.com/packs/media/components/global/search-explore-nav/img/photos/term-bg-1-c98135712157fb21286eafd480f610f9.jpg",
    "https://cdn.eso.org/images/thumb300y/eso1907a.jpg",
    "https://cdn.jpegmini.com/user/images/slider_puffin_before_mobile.jpg",
    "https://imagekit.io/blog/content/images/2019/12/image-optimization.jpg",
    "https://upload.wikimedia.org/wikipedia/commons/7/78/Image.jpg",
    "https://play-lh.googleusercontent.com/ZyWNGIfzUyoajtFcD7NhMksHEZh37f-MkHVGr5Yfefa-IX7yj9SMfI82Z7a2wpdKCA=w240-h480-rw",
    "https://img.bfmtv.com/c/630/420/871/7b9f41477da5f240b24bd67216dd7.jpg"
  ];
  int offset = 0;
  int total = 0;
  int perOffset = 0;
  int perTotal = 0;
  bool isLoadingmore = true;
  bool _isLoading = true;
  bool isPerLoadingmore = true;
  bool _isPerLoading = true;
  List<NotificationModel> tempUserList = [];
  List<NotificationModel> userNoti = [];
  List<String> _tabs = [];
  List<String> selectedList = [];

  @override
  void initState() {
    getUserNotification();
    getNotification();
    controller.addListener(_scrollListener);
    controller1.addListener(_scrollListener1);
    new Future.delayed(Duration.zero, () {
      _tabs = [
        getTranslated(context, 'personal_lbl')!,
        getTranslated(context, 'news_lbl')!,
      ];
    });
    _tc = TabController(length: 2, vsync: this, initialIndex: 0);
    _tc!.addListener(_handleTabControllerTick);
    _refreshKey = GlobalKey<RefreshIndicatorState>();
    updateTitleRSS("");
    loadRSS();
    super.initState();
  }

  void _handleTabControllerTick() {
    setState(() {
      selectedList.clear();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    controller1.dispose();
    super.dispose();
  }

  Widget tabShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.withOpacity(0.6),
      highlightColor: Colors.grey,
      child: Padding(
          padding: EdgeInsetsDirectional.only(start: 20.0, top: 20.0),
          child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
            Container(
              width: 70,
              height: 15.0,
              color: Colors.grey,
            ),
            // Spacer(),
            Padding(
                padding: EdgeInsetsDirectional.only(start: 40.0),
                child: Container(
                  width: 70,
                  height: 15.0,
                  color: Colors.grey,
                )),
          ])),
    );
  }

  //refresh function used in refresh notification
  Future<void> _refresh() async {
    setState(() {
      _isPerLoading = true;
    });
    perOffset = 0;
    perTotal = 0;
    userNoti.clear();
    getUserNotification();
  }

  Future<void> _refresh1() async {
    setState(() {
      _isLoading = true;
    });
    offset = 0;
    total = 0;
    notiList.clear();
    getNotification();
  }

  setAppBar() {
    return PreferredSize(
        preferredSize: Size(double.infinity, 150),
        child: Padding(
            padding: EdgeInsets.only(top: 0.0),
            child: Column(children: [
              // Text(
              //   getTranslated(context, 'notification_lbl')!,
              //   style: Theme.of(context).textTheme.headline6?.copyWith(
              //       color: colors.primary,
              //       fontWeight: FontWeight.w600,
              //       letterSpacing: 0.5),
              // ),
              Container(child: appBarTitle()),
              _tabs.length != 0
                  ? DefaultTabController(
                      length: 2,
                      child: Row(children: [
                        Container(
                            padding: EdgeInsetsDirectional.only(
                                start: 10.0, top: 15.0),
                            width: deviceWidth! / 1.8,
                            height: 60.0,
                            child: TabBar(
                              controller: _tc,

                              labelStyle: Theme.of(context)
                                  .textTheme
                                  .subtitle2
                                  ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5),
                              labelPadding: EdgeInsets.zero,
                              labelColor: colors.primary,
                              unselectedLabelColor: Theme.of(context)
                                  .colorScheme
                                  .fontColor
                                  .withOpacity(0.7),
                              indicatorColor: colors.primary,
                              //indicatorSize: TabBarIndicatorSize.tab,
                              indicator: UnderlineTabIndicator(
                                  borderSide: BorderSide(
                                      width: 3.0, color: colors.primary),
                                  insets:
                                      EdgeInsets.symmetric(horizontal: 10.0)),
                              tabs: _tabs.map((e) => Tab(text: e)).toList(),
                            )),
                      ]))
                  : tabShimmer(),
              Padding(
                  padding: EdgeInsetsDirectional.only(
                      end: 15.0, start: 15.0, top: 1.0),
                  child: Divider(
                    thickness: 1.5,
                    height: 1.0,
                    color: Theme.of(context)
                        .colorScheme
                        .fontColor
                        .withOpacity(0.3),
                  ))
            ])));
  }

  deleteNoti(String id) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {ACCESS_KEY: access_key, ID: id};
      Response response = await post(Uri.parse(deleteUserNotiApi),
              body: param, headers: headers)
          .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);
      String error = getdata["error"];

      String msg = getdata["message"];
      if (error == "false") {
        setState(() {
          for (int i = 0; i < selectedList.length; i++) {
            userNoti.removeWhere((item) => item.id == selectedList[i]);
          }
        });
        selectedList.clear();
        setSnackbar(getTranslated(context, 'delete_noti')!);
      } else {
        setSnackbar(msg);
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg')!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: colors.bgColor,
        key: _scaffoldKey,
        // appBar: setAppBar(),
        // appBar: PreferredSize(
        //     preferredSize: Size(double.infinity, 45 + 60),
        //     child: AppBar(
        //       leadingWidth: 50,
        //       leading: Container(width: 0),
        //       elevation: 0.0,
        //       toolbarHeight: 45 + 60,
        //       centerTitle: true,
        //       backgroundColor: Colors.transparent,
        //       title: appBarTitle(),
        //       // title:Column(children: [

        //       //  appBarTitle(),
        //       //   _tabs.length != 0
        //       // ? DefaultTabController(
        //       //     length: 2,
        //       //     child: Row(children: [
        //       //       Container(
        //       //           // padding: EdgeInsetsDirectional.only(
        //       //           //     start: 10.0, top: 15.0),
        //       //           width: deviceWidth!/2 ,
        //       //           height: 60.0,
        //       //           child: TabBar(
        //       //             controller: _tc,
        //       //             labelStyle: Theme.of(context)
        //       //                 .textTheme
        //       //                 .subtitle2
        //       //                 ?.copyWith(
        //       //                     fontWeight: FontWeight.w600,
        //       //                     letterSpacing: 0.5),
        //       //             labelPadding: EdgeInsets.zero,
        //       //             labelColor: colors.primary,
        //       //             unselectedLabelColor: Theme.of(context)
        //       //                 .colorScheme
        //       //                 .fontColor
        //       //                 .withOpacity(0.7),
        //       //             indicatorColor: colors.primary,
        //       //             //indicatorSize: TabBarIndicatorSize.tab,
        //       //             indicator: UnderlineTabIndicator(
        //       //                 borderSide: BorderSide(
        //       //                     width: 3.0, color: colors.primary),
        //       //                 insets:
        //       //                     EdgeInsets.symmetric(horizontal: 10.0)),
        //       //             tabs: _tabs.map((e) => Tab(text: e)).toList(),
        //       //           )),
        //       //     ]))
        //       // :Container(
        //       //   height: 60,
        //       //   child:tabShimmer()
        //       // ) ,

        //       // Padding(
        //       //     padding: EdgeInsetsDirectional.only(
        //       //         // end: 15.0, start: 15.0, top: 1.0),
        //       //         end: 0, start: 0, top: 1.0),
        //       //     child: Divider(
        //       //       thickness: 1.5,
        //       //       height: 1.0,
        //       //       color: Theme.of(context)
        //       //           .colorScheme
        //       //           .fontColor
        //       //           .withOpacity(0.3),
        //       //     )),
        //       //     ],)
        //       bottom: PreferredSize(
        //           preferredSize: Size(double.infinity, 60),
        //           child: Column(children: [
        //             _tabs.length != 0
        //                 ? DefaultTabController(
        //                     length: 2,
        //                     child: Row(children: [
        //                       Container(
        //                           padding: EdgeInsetsDirectional.only(
        //                               start: 05.0, top: 15.0),
        //                           width: deviceWidth! / 2,
        //                           height: 60.0,
        //                           child: TabBar(
        //                             controller: _tc,
        //                             labelStyle: Theme.of(context)
        //                                 .textTheme
        //                                 .subtitle2
        //                                 ?.copyWith(
        //                                     fontWeight: FontWeight.w600,
        //                                     letterSpacing: 0.5),
        //                             labelPadding: EdgeInsets.zero,
        //                             labelColor: colors.primary,
        //                             unselectedLabelColor: Theme.of(context)
        //                                 .colorScheme
        //                                 .fontColor
        //                                 .withOpacity(0.7),
        //                             indicatorColor: colors.primary,
        //                             //indicatorSize: TabBarIndicatorSize.tab,
        //                             indicator: UnderlineTabIndicator(
        //                                 borderSide: BorderSide(
        //                                     width: 3.0, color: colors.primary),
        //                                 insets: EdgeInsets.symmetric(
        //                                     horizontal: 10.0)),
        //                             tabs:
        //                                 _tabs.map((e) => Tab(text: e)).toList(),
        //                           )),
        //                     ]))
        //                 : Container(height: 60, child: tabShimmer()),
        //             Padding(
        //                 padding: EdgeInsetsDirectional.only(
        //                     end: 15.0, start: 15.0, top: 1.0),
        //                 child: Divider(
        //                   thickness: 1.5,
        //                   height: 1.0,
        //                   color: Theme.of(context)
        //                       .colorScheme
        //                       .fontColor
        //                       .withOpacity(0.3),
        //                 )),
        //           ])),
        //     )),
        appBar: PreferredSize(
            preferredSize: Size(double.infinity, 45),
            child: AppBar(
              leadingWidth: 50,
              actions: [
                Container(
                  width: 50,
                )
              ],
              elevation: 0.0,
              centerTitle: true,
              backgroundColor: Colors.transparent,
              title: appBarTitle(),
              leading: Container(width: 0),
            )),
        body: Scaffold(
          appBar: PreferredSize(
              preferredSize: Size(double.infinity, 70),
              child: AppBar(
                leadingWidth: 50,
                toolbarHeight: 70,
                leading: Container(width: 0),
                elevation: 0.0,
                backgroundColor: Colors.transparent,
                bottom: PreferredSize(
                    preferredSize: Size(double.infinity, 60),
                    child: Column(children: [
                      _tabs.length != 0
                          ? DefaultTabController(
                              length: 2,
                              child: Row(children: [
                                Container(
                                    padding: EdgeInsetsDirectional.only(
                                        start: 05.0, top: 15.0),
                                    width: deviceWidth! / 1.5,
                                    height: 60.0,
                                    child: TabBar(
                                      controller: _tc,
                                      labelStyle: Theme.of(context)
                                          .textTheme
                                          .subtitle2
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5),
                                      labelPadding: EdgeInsets.zero,
                                      labelColor: colors.primary,
                                      unselectedLabelColor: Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.7),
                                      indicatorColor: colors.primary,
                                      //indicatorSize: TabBarIndicatorSize.tab,
                                      indicator: UnderlineTabIndicator(
                                          borderSide: BorderSide(
                                              width: 3.0,
                                              color: colors.primary),
                                          insets: EdgeInsets.symmetric(
                                              horizontal: 10.0)),
                                      tabs: _tabs
                                          .map((e) => Tab(text: e))
                                          .toList(),
                                    )),
                              ]))
                          : Container(height: 60, child: tabShimmer()),
                      Padding(
                          padding: EdgeInsetsDirectional.only(
                              end: 15.0, start: 15.0, top: 1.0),
                          child: Divider(
                            thickness: 1.5,
                            height: 1.0,
                            color: Theme.of(context)
                                .colorScheme
                                .fontColor
                                .withOpacity(0.3),
                          )),
                    ])),
              )),
          body: TabBarView(controller: _tc, children: [
            _isPerLoading
                ? shimmer1(context)
                : userNoti.length == 0
                    ? Padding(
                        padding: const EdgeInsetsDirectional.only(
                            bottom: kToolbarHeight),
                        child: Center(
                            child:
                                Text(getTranslated(context, 'noti_nt_avail')!)))
                    : RefreshIndicator(
                        key: _refreshIndicatorKey1,
                        onRefresh: _refresh,
                        child: Padding(
                            padding: EdgeInsetsDirectional.only(
                                start: 15.0, end: 15.0, bottom: 10.0),
                            child: Column(children: <Widget>[
                              selectedList.length > 0
                                  ? Align(
                                      alignment: Alignment.topRight,
                                      child: IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () {
                                          deleteNoti(selectedList.join(','));
                                        },
                                      ),
                                    )
                                  : Container(),
                              Expanded(
                                  child: ListView.builder(
                                controller: controller1,
                                itemCount: userNoti.length,
                                physics: AlwaysScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return (index == userNoti.length &&
                                          isPerLoadingmore)
                                      ? Center(
                                          child: CircularProgressIndicator())
                                      : ListItemNoti(
                                          userNoti: userNoti[index],
                                          isSelected: (bool value) {
                                            setState(() {
                                              if (value) {
                                                selectedList
                                                    .add(userNoti[index].id!);
                                              } else {
                                                selectedList.remove(
                                                    userNoti[index].id!);
                                              }
                                            });
                                          },
                                          key: Key(
                                              userNoti[index].id.toString()));
                                },
                              ))
                            ]))),
            // _isLoading
            //     ? shimmer(context)
            //     : notiList.length == 0
            //         ? Padding(
            //             padding: const EdgeInsetsDirectional.only(
            //                 top: kToolbarHeight),
            //             child: Center(
            //                 child:
            //                     Text(getTranslated(context, 'noti_nt_avail')!)))
            //         : RefreshIndicator(
            //             key: _refreshIndicatorKey,
            //             onRefresh: _refresh1,
            //             child: Padding(
            //                 padding: EdgeInsetsDirectional.only(
            //                     start: 15.0,
            //                     end: 15.0,
            //                     top: 10.0,
            //                     bottom: 10.0),
            //                 child: ListView.builder(
            //                   controller: controller,
            //                   itemCount: notiList.length,
            //                   physics: AlwaysScrollableScrollPhysics(),
            //                   itemBuilder: (context, index) {
            //                     return (index == notiList.length &&
            //                             isLoadingmore)
            //                         ? Center(child: CircularProgressIndicator())
            //                         : listItem(index);
            //                   },
            //                 ))),
            ListView.builder(
                itemCount: 9,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) => Container(
                      margin: EdgeInsets.symmetric(
                        vertical: deviceWidth! * 0.015,
                        horizontal: deviceWidth! * 0.015,
                      ),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7)),
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            vertical: deviceWidth! * 0.015,
                            horizontal: deviceWidth! * 0.015,
                          ),
                          child: Row(
                            children: [
                              Container(
                                  width: deviceWidth! * 0.13,
                                  height: deviceWidth! * 0.13,
                                  margin: EdgeInsets.all(deviceWidth! * 0.002),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(1000),
                                    child: FadeInImage(
                                        fadeInDuration:
                                            Duration(milliseconds: 150),
                                        image: CachedNetworkImageProvider(
                                            images[index]),
                                        fit: BoxFit.cover,
                                        imageErrorBuilder:
                                            (context, error, stackTrace) =>
                                                errorWidget(250, 450),
                                        placeholder: AssetImage(
                                          placeHolder,
                                        )),
                                  )),
                              Container(
                                margin: EdgeInsets.only(
                                  left: deviceWidth! * 0.03,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.symmetric(
                                        vertical: deviceWidth! * 0.003,
                                      ),
                                      width: deviceWidth! * 0.7,
                                      child: Text(
                                        title[index],
                                        textAlign: TextAlign.start,
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle1
                                            ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .fontColor,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                                fontSize: 20),
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.symmetric(
                                        vertical: deviceWidth! * 0.003,
                                      ),
                                      width: deviceWidth! * 0.7,
                                      child: Text(
                                        desc[index],
                                        textAlign: TextAlign.start,
                                        maxLines: 2,
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle1
                                            ?.copyWith(
                                                color: Colors.grey,
                                                fontSize: 17),
                                      ),
                                    ),
                                     Container(
                                      margin: EdgeInsets.symmetric(
                                        vertical: deviceWidth! * 0.02,
                                      ),
                                      width: deviceWidth! * 0.7,
                                    color: Colors.grey.withOpacity(0.3),
                                    height: 1,
                                    ),
                                    Container(
                                      margin: EdgeInsets.symmetric(
                                        vertical: deviceWidth! * 0.003,
                                      ),
                                      width: deviceWidth! * 0.7,
                                      child: Text(
                                        intl.DateFormat().format(DateTime.now()),
                                        textAlign: TextAlign.start,
                                        maxLines: 2,
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle1
                                            ?.copyWith(
                                                color: Colors.grey,
                                                fontSize: 17),
                                      ),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ))
          ]),
        ));
  }

  //shimmer effects
  Widget shimmer(BuildContext context) {
    var isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.only(
          start: 15.0, end: 15.0, top: 20.0, bottom: 10.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.withOpacity(0.6),
        highlightColor: Colors.grey,
        child: SingleChildScrollView(
          child: Column(
            children: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
                .map((_) => Padding(
                    padding: EdgeInsetsDirectional.only(
                      top: 5.0,
                      bottom: 10.0,
                    ),
                    child: Container(
                      padding: EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.withOpacity(0.6),
                      ),
                      child: Row(
                        //crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5.0),
                              color: Colors.grey,
                            ),
                            width: 80.0,
                            height: 80.0,
                          ),
                          Expanded(
                              child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                start: 13.0, end: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 13.0,
                                  color: Colors.grey,
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 3.0),
                                ),
                                Container(
                                  width: double.infinity,
                                  height: 13.0,
                                  color: Colors.grey,
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                ),
                                Container(
                                  width: 100,
                                  height: 10.0,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ))
                        ],
                      ),
                    )))
                .toList(),
          ),
        ),
      ),
    );
  }

  //shimmer effects
  Widget shimmer1(BuildContext context) {
    var isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.only(
          start: 15.0, end: 15.0, top: 20.0, bottom: 10.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.withOpacity(0.6),
        highlightColor: Colors.grey,
        child: SingleChildScrollView(
          child: Column(
            children: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
                .map((_) => Padding(
                    padding: EdgeInsetsDirectional.only(
                      top: 5.0,
                      bottom: 10.0,
                    ),
                    child: Container(
                      padding: EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.withOpacity(0.6),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                              padding: EdgeInsetsDirectional.only(start: 5.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5.0),
                                  color: Colors.grey,
                                ),
                                width: 25.0,
                                height: 25.0,
                              )),
                          Expanded(
                              child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                start: 13.0, end: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 13.0,
                                  color: Colors.grey,
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 3.0),
                                ),
                                Container(
                                  width: double.infinity,
                                  height: 13.0,
                                  color: Colors.grey,
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                ),
                                Container(
                                  width: 100,
                                  height: 10.0,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ))
                        ],
                      ),
                    )))
                .toList(),
          ),
        ),
      ),
    );
  }

  //list of notification shown
  Widget listItem(int index) {
    NotificationModel model = notiList[index];

    DateTime time1 = DateTime.parse(model.date_sent!);

    return Hero(
        tag: model.id!,
        child: Padding(
            padding: EdgeInsetsDirectional.only(
              top: 5.0,
              bottom: 10.0,
            ),
            child: InkWell(
              child: Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.boxColor,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                          blurRadius: 10.0,
                          offset: const Offset(5.0, 5.0),
                          color: Theme.of(context)
                              .colorScheme
                              .fontColor
                              .withOpacity(0.1),
                          spreadRadius: 1.0),
                    ],
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    children: <Widget>[
                      model.image != null || model.image != ''
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(5.0),
                              child: model.image! != ""
                                  ? FadeInImage.assetNetwork(
                                      fadeInDuration:
                                          Duration(milliseconds: 150),
                                      image: model.image!,
                                      height: 80.0,
                                      width: 80,
                                      fit: BoxFit.cover,
                                      placeholder: placeHolder,
                                      imageErrorBuilder:
                                          (context, error, stackTrace) {
                                        return errorWidget(80, 80);
                                      },
                                    )
                                  : Image.asset(
                                      "assets/images/read.png",
                                      height: 80.0,
                                      width: 80,
                                      fit: BoxFit.cover,
                                    ),
                            )
                          : Container(
                              height: 0,
                            ),
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                            start: 13.0, end: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(model.title!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor
                                            .withOpacity(0.9),
                                        fontSize: 15.0,
                                        letterSpacing: 0.1)),
                            Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(top: 8.0),
                                child: Text(convertToAgo(time1, 2)!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .caption
                                        ?.copyWith(
                                            fontWeight: FontWeight.normal,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor
                                                .withOpacity(0.7),
                                            fontSize: 11)))
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              onTap: () {
                NotificationModel model = notiList[index];
                if (model.newsId != "") {
                  getNewsById(model.newsId!);
                }
              },
            )));
  }

  updateParent() {
    //setState(() {});
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
      Response response =
          await post(Uri.parse(getNewsByIdApi), body: param, headers: headers)
              .timeout(Duration(seconds: timeOut));
      var getdata = json.decode(response.body);

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
                )));
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg')!);
    }
  }

  //get notification using api
  Future<void> getNotification() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
          ACCESS_KEY: access_key,
        };
        Response response = await post(Uri.parse(getNotificationApi),
                headers: headers, body: parameter)
            .timeout(Duration(seconds: timeOut));
        if (response.statusCode == 200) {
          var getData = json.decode(response.body);
          String error = getData["error"];
          if (error == "false") {
            total = int.parse(getData["total"]);
            if ((offset) < total) {
              tempList.clear();
              var data = getData["data"];
              tempList = (data as List)
                  .map((data) => new NotificationModel.fromJson(data))
                  .toList();

              notiList.addAll(tempList);
              offset = offset + perPage;
            }
          } else {
            isLoadingmore = false;
          }
          if (mounted)
            setState(() {
              _isLoading = false;
            });
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
        setState(() {
          _isLoading = false;
          isLoadingmore = false;
        });
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg')!);
      setState(() {
        _isLoading = false;
        isLoadingmore = false;
      });
    }
  }

  //get notification using api
  Future<void> getUserNotification() async {
    if (CUR_USERID != null && CUR_USERID != "") {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          var parameter = {
            LIMIT: perPage.toString(),
            OFFSET: perOffset.toString(),
            ACCESS_KEY: access_key,
            USER_ID: CUR_USERID
          };

          Response response = await post(Uri.parse(getUserNotificationApi),
                  headers: headers, body: parameter)
              .timeout(Duration(seconds: timeOut));
          if (response.statusCode == 200) {
            var getData = json.decode(response.body);
            String error = getData["error"];
            if (error == "false") {
              perTotal = int.parse(getData["total"]);
              if ((perOffset) < perTotal) {
                tempUserList.clear();
                var data = getData["data"];
                tempUserList = (data as List)
                    .map((data) => new NotificationModel.fromJson(data))
                    .toList();

                userNoti.addAll(tempUserList);
                perOffset = perOffset + perPage;
              }
            } else {
              isPerLoadingmore = false;
            }
            if (mounted)
              setState(() {
                _isPerLoading = false;
              });
          }
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!);
          setState(() {
            _isPerLoading = false;
            isPerLoadingmore = false;
          });
        }
      } else {
        setSnackbar(getTranslated(context, 'internetmsg')!);
        setState(() {
          _isPerLoading = false;
          isPerLoadingmore = false;
        });
      }
    } else {
      setState(() {
        _isPerLoading = false;
      });
    }
  }

//set snackbar msg
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

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (this.mounted) {
        setState(() {
          isLoadingmore = true;

          if (offset < total) getNotification();
        });
      }
    }
  }

  _scrollListener1() {
    if (controller1.offset >= controller1.position.maxScrollExtent &&
        !controller1.position.outOfRange) {
      if (this.mounted) {
        setState(() {
          isPerLoadingmore = true;

          if (perOffset < perTotal) getUserNotification();
        });
      }
    }
  }

  static const String FEED_URLRSS =
      'https://www.bhaskar.com/rss-v1--category-1740.xml';
  RssFeed? _feedRSS;
  String _titleRSS = "";
  static const String loadingFeedMsg = 'Loading Feed...';
  static const String feedLoadErrorMsg = 'Error Loading Feed.';
  static const String feedOpenErrorMsg = 'Error Opening Feed.';
  static const String placeholderImg = 'images/no_image.png';
  GlobalKey<RefreshIndicatorState>? _refreshKey;

  updateFeed(feed) {
    setState(() {
      _feedRSS = feed;
    });
  }

  Future<void> openFeed(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: true,
        forceWebView: false,
      );
      return;
    }
    updateTitleRSS(feedOpenErrorMsg);
  }

  updateTitleRSS(title) {
    setState(() {
      _titleRSS = title;
    });
  }

  loadRSS() async {
    updateTitleRSS(loadingFeedMsg);
    loadFeedRSS().then((result) {
      if (null == result || result.toString().isEmpty) {
        updateTitleRSS(feedLoadErrorMsg);
        return;
      }
      updateFeed(result);
      updateTitleRSS(_feedRSS!.title);
    });
  }

  Future<RssFeed?> loadFeedRSS() async {
    try {
      final client = http.Client();
      final response = await client.get(Uri.parse(FEED_URLRSS));
      return RssFeed.parse(response.body);
    } catch (e) {
      //
    }
    return null;
  }

  titleRSS(title) {
    return Text(
      title.toString(),
      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  subtitleRSS(subTitle) {
    return Text(
      convertToAgo(DateTime.parse(subTitle.toString()), 0)!,
      style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w100),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  thumbnailRSS(imageUrl) {
    return Padding(
      padding: EdgeInsets.only(left: 15.0),
      child: imageUrl == null
          ? Image.asset("assets/images/noImage.jpeg")
          : CachedNetworkImage(
              placeholder: (context, url) =>
                  Image.asset("assets/images/noImage.jpeg"),
              imageUrl: imageUrl,
              height: 50,
              width: 70,
              alignment: Alignment.center,
              fit: BoxFit.fill,
            ),
      // child: titleRSS(imageUrl.toString()),
    );
  }

  rightIconRSS() {
    return Icon(
      Icons.keyboard_arrow_right,
      color: Colors.grey,
      size: 30.0,
    );
  }

  listRSS() {
    return ListView.builder(
      itemCount: _feedRSS!.items!.length,
      itemBuilder: (BuildContext context, int index) {
        final item = _feedRSS!.items![index];
        return ListTile(
          title: titleRSS(item.title),
          subtitle: subtitleRSS(item.pubDate),
          leading: thumbnailRSS(item.media!.contents!.first.url),
          // leading: thumbnailRSS(item.enclosure?.url),
          trailing: rightIconRSS(),
          contentPadding: EdgeInsets.all(5.0),
          onTap: () => openFeed(item.link!),
        );
      },
    );
  }
}
// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:http/http.dart';
// import 'package:intl/intl.dart' as intl;
// import 'package:news/Helper/Constant.dart';
// import 'package:news/Helper/Session.dart';
// import 'package:news/Helper/Color.dart';
// import 'package:news/ListItemNotification.dart';
// import 'package:news/Model/Notification.dart';
// import 'package:news/appBarTitle.dart';
// import 'package:shimmer/shimmer.dart';
// import 'Helper/String.dart';
// import 'Model/News.dart';
// import 'NewsDetails.dart';
// import 'package:webfeed/webfeed.dart';
// import 'package:http/http.dart' as http;
// import 'package:url_launcher/url_launcher.dart';
// import 'package:cached_network_image/cached_network_image.dart';

// class NotificationList extends StatefulWidget {
//   @override
//   State<StatefulWidget> createState() => StateNoti();
// }

// class StateNoti extends State<NotificationList> with TickerProviderStateMixin {
//   final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
//   ScrollController controller = new ScrollController();
//   ScrollController controller1 = new ScrollController();

//   List<NotificationModel> tempList = [];
//   bool _isNetworkAvail = true;
//   final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
//       new GlobalKey<RefreshIndicatorState>();
//   final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey1 =
//       new GlobalKey<RefreshIndicatorState>();
//   TabController? _tc;
//   List<NotificationModel> notiList = [];
//   int offset = 0;
//   int total = 0;
//   int perOffset = 0;
//   int perTotal = 0;
//   bool isLoadingmore = true;
//   bool _isLoading = true;
//   bool isPerLoadingmore = true;
//   bool _isPerLoading = true;
//   List<NotificationModel> tempUserList = [];
//   List<NotificationModel> userNoti = [];
//   List<String> _tabs = [];
//   List<String> selectedList = [];

//   @override
//   void initState() {
//     getUserNotification();
//     getNotification();
//     controller.addListener(_scrollListener);
//     controller1.addListener(_scrollListener1);
//     new Future.delayed(Duration.zero, () {
//       _tabs = [
//         "RSS Feeds",
//         getTranslated(context, 'personal_lbl')!,
//         getTranslated(context, 'news_lbl')!,
//       ];
//     });
//     _tc = TabController(length: 3, vsync: this, initialIndex: 0);
//     _tc!.addListener(_handleTabControllerTick);
//     _refreshKey = GlobalKey<RefreshIndicatorState>();
//     updateTitleRSS("");
//     loadRSS();
//     super.initState();
//   }

//   void _handleTabControllerTick() {
//     setState(() {
//       selectedList.clear();
//     });
//   }

//   @override
//   void dispose() {
//     controller.dispose();
//     controller1.dispose();
//     super.dispose();
//   }

//   Widget tabShimmer() {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey.withOpacity(0.6),
//       highlightColor: Colors.grey,
//       child: Padding(
//           padding: EdgeInsetsDirectional.only(start: 20.0, top: 20.0),
//           child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
//             Container(
//               width: 70,
//               height: 15.0,
//               color: Colors.grey,
//             ),
//             // Spacer(),
//             Padding(
//                 padding: EdgeInsetsDirectional.only(start: 40.0),
//                 child: Container(
//                   width: 70,
//                   height: 15.0,
//                   color: Colors.grey,
//                 )),
//           ])),
//     );
//   }

//   //refresh function used in refresh notification
//   Future<void> _refresh() async {
//     setState(() {
//       _isPerLoading = true;
//     });
//     perOffset = 0;
//     perTotal = 0;
//     userNoti.clear();
//     getUserNotification();
//   }

//   Future<void> _refresh1() async {
//     setState(() {
//       _isLoading = true;
//     });
//     offset = 0;
//     total = 0;
//     notiList.clear();
//     getNotification();
//   }

//   setAppBar() {
//     return PreferredSize(
//         preferredSize: Size(double.infinity, 150),
//         child: Padding(
//             padding: EdgeInsets.only(top: 0.0),
//             child: Column(children: [
//               // Text(
//               //   getTranslated(context, 'notification_lbl')!,
//               //   style: Theme.of(context).textTheme.headline6?.copyWith(
//               //       color: colors.primary,
//               //       fontWeight: FontWeight.w600,
//               //       letterSpacing: 0.5),
//               // ),
//               Container(child: appBarTitle()),
//               _tabs.length != 0
//                   ? DefaultTabController(
//                       length: 3,
//                       child: Row(children: [
//                         Container(
//                             padding: EdgeInsetsDirectional.only(
//                                 start: 10.0, top: 15.0),
//                             width: deviceWidth! / 1.8,
//                             height: 60.0,
//                             child: TabBar(
//                               controller: _tc,

//                               labelStyle: Theme.of(context)
//                                   .textTheme
//                                   .subtitle2
//                                   ?.copyWith(
//                                       fontWeight: FontWeight.w600,
//                                       letterSpacing: 0.5),
//                               labelPadding: EdgeInsets.zero,
//                               labelColor: colors.primary,
//                               unselectedLabelColor: Theme.of(context)
//                                   .colorScheme
//                                   .fontColor
//                                   .withOpacity(0.7),
//                               indicatorColor: colors.primary,
//                               //indicatorSize: TabBarIndicatorSize.tab,
//                               indicator: UnderlineTabIndicator(
//                                   borderSide: BorderSide(
//                                       width: 3.0, color: colors.primary),
//                                   insets:
//                                       EdgeInsets.symmetric(horizontal: 10.0)),
//                               tabs: _tabs.map((e) => Tab(text: e)).toList(),
//                             )),
//                       ]))
//                   : tabShimmer(),
//               Padding(
//                   padding: EdgeInsetsDirectional.only(
//                       end: 15.0, start: 15.0, top: 1.0),
//                   child: Divider(
//                     thickness: 1.5,
//                     height: 1.0,
//                     color: Theme.of(context)
//                         .colorScheme
//                         .fontColor
//                         .withOpacity(0.3),
//                   ))
//             ])));
//   }

//   deleteNoti(String id) async {
//     _isNetworkAvail = await isNetworkAvailable();
//     if (_isNetworkAvail) {
//       var param = {ACCESS_KEY: access_key, ID: id};
//       Response response = await post(Uri.parse(deleteUserNotiApi),
//               body: param, headers: headers)
//           .timeout(Duration(seconds: timeOut));

//       var getdata = json.decode(response.body);
//       String error = getdata["error"];

//       String msg = getdata["message"];
//       if (error == "false") {
//         setState(() {
//           for (int i = 0; i < selectedList.length; i++) {
//             userNoti.removeWhere((item) => item.id == selectedList[i]);
//           }
//         });
//         selectedList.clear();
//         setSnackbar(getTranslated(context, 'delete_noti')!);
//       } else {
//         setSnackbar(msg);
//       }
//     } else {
//       setSnackbar(getTranslated(context, 'internetmsg')!);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         backgroundColor: colors.bgColor,
//         key: _scaffoldKey,
//         // appBar: setAppBar(),
//         // appBar: PreferredSize(
//         //     preferredSize: Size(double.infinity, 45 + 60),
//         //     child: AppBar(
//         //       leadingWidth: 50,
//         //       leading: Container(width: 0),
//         //       elevation: 0.0,
//         //       toolbarHeight: 45 + 60,
//         //       centerTitle: true,
//         //       backgroundColor: Colors.transparent,
//         //       title: appBarTitle(),
//         //       // title:Column(children: [

//         //       //  appBarTitle(),
//         //       //   _tabs.length != 0
//         //       // ? DefaultTabController(
//         //       //     length: 2,
//         //       //     child: Row(children: [
//         //       //       Container(
//         //       //           // padding: EdgeInsetsDirectional.only(
//         //       //           //     start: 10.0, top: 15.0),
//         //       //           width: deviceWidth!/2 ,
//         //       //           height: 60.0,
//         //       //           child: TabBar(
//         //       //             controller: _tc,
//         //       //             labelStyle: Theme.of(context)
//         //       //                 .textTheme
//         //       //                 .subtitle2
//         //       //                 ?.copyWith(
//         //       //                     fontWeight: FontWeight.w600,
//         //       //                     letterSpacing: 0.5),
//         //       //             labelPadding: EdgeInsets.zero,
//         //       //             labelColor: colors.primary,
//         //       //             unselectedLabelColor: Theme.of(context)
//         //       //                 .colorScheme
//         //       //                 .fontColor
//         //       //                 .withOpacity(0.7),
//         //       //             indicatorColor: colors.primary,
//         //       //             //indicatorSize: TabBarIndicatorSize.tab,
//         //       //             indicator: UnderlineTabIndicator(
//         //       //                 borderSide: BorderSide(
//         //       //                     width: 3.0, color: colors.primary),
//         //       //                 insets:
//         //       //                     EdgeInsets.symmetric(horizontal: 10.0)),
//         //       //             tabs: _tabs.map((e) => Tab(text: e)).toList(),
//         //       //           )),
//         //       //     ]))
//         //       // :Container(
//         //       //   height: 60,
//         //       //   child:tabShimmer()
//         //       // ) ,

//         //       // Padding(
//         //       //     padding: EdgeInsetsDirectional.only(
//         //       //         // end: 15.0, start: 15.0, top: 1.0),
//         //       //         end: 0, start: 0, top: 1.0),
//         //       //     child: Divider(
//         //       //       thickness: 1.5,
//         //       //       height: 1.0,
//         //       //       color: Theme.of(context)
//         //       //           .colorScheme
//         //       //           .fontColor
//         //       //           .withOpacity(0.3),
//         //       //     )),
//         //       //     ],)
//         //       bottom: PreferredSize(
//         //           preferredSize: Size(double.infinity, 60),
//         //           child: Column(children: [
//         //             _tabs.length != 0
//         //                 ? DefaultTabController(
//         //                     length: 2,
//         //                     child: Row(children: [
//         //                       Container(
//         //                           padding: EdgeInsetsDirectional.only(
//         //                               start: 05.0, top: 15.0),
//         //                           width: deviceWidth! / 2,
//         //                           height: 60.0,
//         //                           child: TabBar(
//         //                             controller: _tc,
//         //                             labelStyle: Theme.of(context)
//         //                                 .textTheme
//         //                                 .subtitle2
//         //                                 ?.copyWith(
//         //                                     fontWeight: FontWeight.w600,
//         //                                     letterSpacing: 0.5),
//         //                             labelPadding: EdgeInsets.zero,
//         //                             labelColor: colors.primary,
//         //                             unselectedLabelColor: Theme.of(context)
//         //                                 .colorScheme
//         //                                 .fontColor
//         //                                 .withOpacity(0.7),
//         //                             indicatorColor: colors.primary,
//         //                             //indicatorSize: TabBarIndicatorSize.tab,
//         //                             indicator: UnderlineTabIndicator(
//         //                                 borderSide: BorderSide(
//         //                                     width: 3.0, color: colors.primary),
//         //                                 insets: EdgeInsets.symmetric(
//         //                                     horizontal: 10.0)),
//         //                             tabs:
//         //                                 _tabs.map((e) => Tab(text: e)).toList(),
//         //                           )),
//         //                     ]))
//         //                 : Container(height: 60, child: tabShimmer()),
//         //             Padding(
//         //                 padding: EdgeInsetsDirectional.only(
//         //                     end: 15.0, start: 15.0, top: 1.0),
//         //                 child: Divider(
//         //                   thickness: 1.5,
//         //                   height: 1.0,
//         //                   color: Theme.of(context)
//         //                       .colorScheme
//         //                       .fontColor
//         //                       .withOpacity(0.3),
//         //                 )),
//         //           ])),
//         //     )),
//         appBar: PreferredSize(
//             preferredSize: Size(double.infinity, 45),
//             child: AppBar(
//               leadingWidth: 50,
//               actions: [
//                 Container(
//                   width: 50,
//                 )
//               ],
//               elevation: 0.0,
//               centerTitle: true,
//               backgroundColor: Colors.transparent,
//               title: appBarTitle(),
//               leading: Container(width: 0),
//             )),
//         body: Scaffold(
//           appBar: PreferredSize(
//               preferredSize: Size(double.infinity, 70),
//               child: AppBar(
//                 leadingWidth: 50,
//                 toolbarHeight: 70,
//                 leading: Container(width: 0),
//                 elevation: 0.0,
//                 backgroundColor: Colors.transparent,
//                 bottom: PreferredSize(
//                     preferredSize: Size(double.infinity, 60),
//                     child: Column(children: [
//                       _tabs.length != 0
//                           ? DefaultTabController(
//                               length: 2,
//                               child: Row(children: [
//                                 Container(
//                                     padding: EdgeInsetsDirectional.only(
//                                         start: 05.0, top: 15.0),
//                                     width: deviceWidth! / 1.5,
//                                     height: 60.0,
//                                     child: TabBar(
//                                       onTap: (int index) {
//                                         if (index == 0) {
//                                           _refreshKey = GlobalKey<
//                                               RefreshIndicatorState>();
//                                           updateTitleRSS("");
//                                           loadRSS();
//                                         }
//                                       },
//                                       controller: _tc,
//                                       labelStyle: Theme.of(context)
//                                           .textTheme
//                                           .subtitle2
//                                           ?.copyWith(
//                                               fontWeight: FontWeight.w600,
//                                               letterSpacing: 0.5),
//                                       labelPadding: EdgeInsets.zero,
//                                       labelColor: colors.primary,
//                                       unselectedLabelColor: Theme.of(context)
//                                           .colorScheme
//                                           .fontColor
//                                           .withOpacity(0.7),
//                                       indicatorColor: colors.primary,
//                                       //indicatorSize: TabBarIndicatorSize.tab,
//                                       indicator: UnderlineTabIndicator(
//                                           borderSide: BorderSide(
//                                               width: 3.0,
//                                               color: colors.primary),
//                                           insets: EdgeInsets.symmetric(
//                                               horizontal: 10.0)),
//                                       tabs: _tabs
//                                           .map((e) => Tab(text: e))
//                                           .toList(),
//                                     )),
//                               ]))
//                           : Container(height: 60, child: tabShimmer()),
//                       Padding(
//                           padding: EdgeInsetsDirectional.only(
//                               end: 15.0, start: 15.0, top: 1.0),
//                           child: Divider(
//                             thickness: 1.5,
//                             height: 1.0,
//                             color: Theme.of(context)
//                                 .colorScheme
//                                 .fontColor
//                                 .withOpacity(0.3),
//                           )),
//                     ])),
//               )),
//           body: TabBarView(controller: _tc, children: [
//             _isLoading
//                 ? shimmer(context)
//                 : null == _feedRSS || null == _feedRSS!.items
//                     ? Padding(
//                         padding: const EdgeInsetsDirectional.only(
//                             top: kToolbarHeight),
//                         child: Center(
//                             child:
//                                 Text(getTranslated(context, 'noti_nt_avail')!)))
//                     : RefreshIndicator(
//                         key: _refreshKey,
//                         child: listRSS(),
//                         onRefresh: () => loadRSS(),
//                       ),
//             _isPerLoading
//                 ? shimmer1(context)
//                 : userNoti.length == 0
//                     ? Padding(
//                         padding: const EdgeInsetsDirectional.only(
//                             bottom: kToolbarHeight),
//                         child: Center(
//                             child:
//                                 Text(getTranslated(context, 'noti_nt_avail')!)))
//                     : RefreshIndicator(
//                         key: _refreshIndicatorKey1,
//                         onRefresh: _refresh,
//                         child: Padding(
//                             padding: EdgeInsetsDirectional.only(
//                                 start: 15.0, end: 15.0, bottom: 10.0),
//                             child: Column(children: <Widget>[
//                               selectedList.length > 0
//                                   ? Align(
//                                       alignment: Alignment.topRight,
//                                       child: IconButton(
//                                         icon: Icon(Icons.delete),
//                                         onPressed: () {
//                                           deleteNoti(selectedList.join(','));
//                                         },
//                                       ),
//                                     )
//                                   : Container(),
//                               Expanded(
//                                   child: ListView.builder(
//                                 controller: controller1,
//                                 itemCount: userNoti.length,
//                                 physics: AlwaysScrollableScrollPhysics(),
//                                 itemBuilder: (context, index) {
//                                   return (index == userNoti.length &&
//                                           isPerLoadingmore)
//                                       ? Center(
//                                           child: CircularProgressIndicator())
//                                       : ListItemNoti(
//                                           userNoti: userNoti[index],
//                                           isSelected: (bool value) {
//                                             setState(() {
//                                               if (value) {
//                                                 selectedList
//                                                     .add(userNoti[index].id!);
//                                               } else {
//                                                 selectedList.remove(
//                                                     userNoti[index].id!);
//                                               }
//                                             });
//                                           },
//                                           key: Key(
//                                               userNoti[index].id.toString()));
//                                 },
//                               ))
//                             ]))),
//             _isLoading
//                 ? shimmer(context)
//                 : notiList.length == 0
//                     ? Padding(
//                         padding: const EdgeInsetsDirectional.only(
//                             top: kToolbarHeight),
//                         child: Center(
//                             child:
//                                 Text(getTranslated(context, 'noti_nt_avail')!)))
//                     : RefreshIndicator(
//                         key: _refreshIndicatorKey,
//                         onRefresh: _refresh1,
//                         child: Padding(
//                             padding: EdgeInsetsDirectional.only(
//                                 start: 15.0,
//                                 end: 15.0,
//                                 top: 10.0,
//                                 bottom: 10.0),
//                             child: ListView.builder(
//                               controller: controller,
//                               itemCount: notiList.length,
//                               physics: AlwaysScrollableScrollPhysics(),
//                               itemBuilder: (context, index) {
//                                 return (index == notiList.length &&
//                                         isLoadingmore)
//                                     ? Center(child: CircularProgressIndicator())
//                                     : listItem(index);
//                               },
//                             ))),
//           ]),
//         ));
//   }

//   //shimmer effects
//   Widget shimmer(BuildContext context) {
//     var isDarkTheme = Theme.of(context).brightness == Brightness.dark;
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsetsDirectional.only(
//           start: 15.0, end: 15.0, top: 20.0, bottom: 10.0),
//       child: Shimmer.fromColors(
//         baseColor: Colors.grey.withOpacity(0.6),
//         highlightColor: Colors.grey,
//         child: SingleChildScrollView(
//           child: Column(
//             children: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
//                 .map((_) => Padding(
//                     padding: EdgeInsetsDirectional.only(
//                       top: 5.0,
//                       bottom: 10.0,
//                     ),
//                     child: Container(
//                       padding: EdgeInsets.all(10.0),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(10),
//                         color: Colors.grey.withOpacity(0.6),
//                       ),
//                       child: Row(
//                         //crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Container(
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(5.0),
//                               color: Colors.grey,
//                             ),
//                             width: 80.0,
//                             height: 80.0,
//                           ),
//                           Expanded(
//                               child: Padding(
//                             padding: const EdgeInsetsDirectional.only(
//                                 start: 13.0, end: 8.0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Container(
//                                   width: double.infinity,
//                                   height: 13.0,
//                                   color: Colors.grey,
//                                 ),
//                                 Padding(
//                                   padding:
//                                       const EdgeInsets.symmetric(vertical: 3.0),
//                                 ),
//                                 Container(
//                                   width: double.infinity,
//                                   height: 13.0,
//                                   color: Colors.grey,
//                                 ),
//                                 Padding(
//                                   padding:
//                                       const EdgeInsets.symmetric(vertical: 8.0),
//                                 ),
//                                 Container(
//                                   width: 100,
//                                   height: 10.0,
//                                   color: Colors.grey,
//                                 ),
//                               ],
//                             ),
//                           ))
//                         ],
//                       ),
//                     )))
//                 .toList(),
//           ),
//         ),
//       ),
//     );
//   }

//   //shimmer effects
//   Widget shimmer1(BuildContext context) {
//     var isDarkTheme = Theme.of(context).brightness == Brightness.dark;
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsetsDirectional.only(
//           start: 15.0, end: 15.0, top: 20.0, bottom: 10.0),
//       child: Shimmer.fromColors(
//         baseColor: Colors.grey.withOpacity(0.6),
//         highlightColor: Colors.grey,
//         child: SingleChildScrollView(
//           child: Column(
//             children: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
//                 .map((_) => Padding(
//                     padding: EdgeInsetsDirectional.only(
//                       top: 5.0,
//                       bottom: 10.0,
//                     ),
//                     child: Container(
//                       padding: EdgeInsets.all(10.0),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(10),
//                         color: Colors.grey.withOpacity(0.6),
//                       ),
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Padding(
//                               padding: EdgeInsetsDirectional.only(start: 5.0),
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(5.0),
//                                   color: Colors.grey,
//                                 ),
//                                 width: 25.0,
//                                 height: 25.0,
//                               )),
//                           Expanded(
//                               child: Padding(
//                             padding: const EdgeInsetsDirectional.only(
//                                 start: 13.0, end: 8.0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Container(
//                                   width: double.infinity,
//                                   height: 13.0,
//                                   color: Colors.grey,
//                                 ),
//                                 Padding(
//                                   padding:
//                                       const EdgeInsets.symmetric(vertical: 3.0),
//                                 ),
//                                 Container(
//                                   width: double.infinity,
//                                   height: 13.0,
//                                   color: Colors.grey,
//                                 ),
//                                 Padding(
//                                   padding:
//                                       const EdgeInsets.symmetric(vertical: 8.0),
//                                 ),
//                                 Container(
//                                   width: 100,
//                                   height: 10.0,
//                                   color: Colors.grey,
//                                 ),
//                               ],
//                             ),
//                           ))
//                         ],
//                       ),
//                     )))
//                 .toList(),
//           ),
//         ),
//       ),
//     );
//   }

//   //list of notification shown
//   Widget listItem(int index) {
//     NotificationModel model = notiList[index];

//     DateTime time1 = DateTime.parse(model.date_sent!);

//     return Hero(
//         tag: model.id!,
//         child: Padding(
//             padding: EdgeInsetsDirectional.only(
//               top: 5.0,
//               bottom: 10.0,
//             ),
//             child: InkWell(
//               child: Container(
//                 decoration: BoxDecoration(
//                     color: Theme.of(context).colorScheme.boxColor,
//                     boxShadow: <BoxShadow>[
//                       BoxShadow(
//                           blurRadius: 10.0,
//                           offset: const Offset(5.0, 5.0),
//                           color: Theme.of(context)
//                               .colorScheme
//                               .fontColor
//                               .withOpacity(0.1),
//                           spreadRadius: 1.0),
//                     ],
//                     borderRadius: BorderRadius.circular(10)),
//                 child: Padding(
//                   padding: EdgeInsets.all(10.0),
//                   child: Row(
//                     children: <Widget>[
//                       model.image != null || model.image != ''
//                           ? ClipRRect(
//                               borderRadius: BorderRadius.circular(5.0),
//                               child: model.image! != ""
//                                   ? FadeInImage.assetNetwork(
//                                       fadeInDuration:
//                                           Duration(milliseconds: 150),
//                                       image: model.image!,
//                                       height: 80.0,
//                                       width: 80,
//                                       fit: BoxFit.cover,
//                                       placeholder: placeHolder,
//                                       imageErrorBuilder:
//                                           (context, error, stackTrace) {
//                                         return errorWidget(80, 80);
//                                       },
//                                     )
//                                   : Image.asset(
//                                       "assets/images/read.png",
//                                       height: 80.0,
//                                       width: 80,
//                                       fit: BoxFit.cover,
//                                     ),
//                             )
//                           : Container(
//                               height: 0,
//                             ),
//                       Expanded(
//                           child: Padding(
//                         padding: const EdgeInsetsDirectional.only(
//                             start: 13.0, end: 8.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: <Widget>[
//                             Text(model.title!,
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: Theme.of(context)
//                                     .textTheme
//                                     .subtitle1
//                                     ?.copyWith(
//                                         fontWeight: FontWeight.bold,
//                                         color: Theme.of(context)
//                                             .colorScheme
//                                             .fontColor
//                                             .withOpacity(0.9),
//                                         fontSize: 15.0,
//                                         letterSpacing: 0.1)),
//                             Padding(
//                                 padding:
//                                     const EdgeInsetsDirectional.only(top: 8.0),
//                                 child: Text(convertToAgo(time1, 2)!,
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .caption
//                                         ?.copyWith(
//                                             fontWeight: FontWeight.normal,
//                                             color: Theme.of(context)
//                                                 .colorScheme
//                                                 .fontColor
//                                                 .withOpacity(0.7),
//                                             fontSize: 11)))
//                           ],
//                         ),
//                       )),
//                     ],
//                   ),
//                 ),
//               ),
//               onTap: () {
//                 NotificationModel model = notiList[index];
//                 if (model.newsId != "") {
//                   getNewsById(model.newsId!);
//                 }
//               },
//             )));
//   }

//   updateParent() {
//     //setState(() {});
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
//       Response response =
//           await post(Uri.parse(getNewsByIdApi), body: param, headers: headers)
//               .timeout(Duration(seconds: timeOut));
//       var getdata = json.decode(response.body);

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
//                 )));
//       }
//     } else {
//       setSnackbar(getTranslated(context, 'internetmsg')!);
//     }
//   }

//   //get notification using api
//   Future<void> getNotification() async {
//     _isNetworkAvail = await isNetworkAvailable();
//     if (_isNetworkAvail) {
//       try {
//         var parameter = {
//           LIMIT: perPage.toString(),
//           OFFSET: offset.toString(),
//           ACCESS_KEY: access_key,
//         };
//         Response response = await post(Uri.parse(getNotificationApi),
//                 headers: headers, body: parameter)
//             .timeout(Duration(seconds: timeOut));
//         if (response.statusCode == 200) {
//           var getData = json.decode(response.body);
//           String error = getData["error"];
//           if (error == "false") {
//             total = int.parse(getData["total"]);
//             if ((offset) < total) {
//               tempList.clear();
//               var data = getData["data"];
//               tempList = (data as List)
//                   .map((data) => new NotificationModel.fromJson(data))
//                   .toList();

//               notiList.addAll(tempList);
//               offset = offset + perPage;
//             }
//           } else {
//             isLoadingmore = false;
//           }
//           if (mounted)
//             setState(() {
//               _isLoading = false;
//             });
//         }
//       } on TimeoutException catch (_) {
//         setSnackbar(getTranslated(context, 'somethingMSg')!);
//         setState(() {
//           _isLoading = false;
//           isLoadingmore = false;
//         });
//       }
//     } else {
//       setSnackbar(getTranslated(context, 'internetmsg')!);
//       setState(() {
//         _isLoading = false;
//         isLoadingmore = false;
//       });
//     }
//   }

//   //get notification using api
//   Future<void> getUserNotification() async {
//     if (CUR_USERID != null && CUR_USERID != "") {
//       _isNetworkAvail = await isNetworkAvailable();
//       if (_isNetworkAvail) {
//         try {
//           var parameter = {
//             LIMIT: perPage.toString(),
//             OFFSET: perOffset.toString(),
//             ACCESS_KEY: access_key,
//             USER_ID: CUR_USERID
//           };

//           Response response = await post(Uri.parse(getUserNotificationApi),
//                   headers: headers, body: parameter)
//               .timeout(Duration(seconds: timeOut));
//           if (response.statusCode == 200) {
//             var getData = json.decode(response.body);
//             String error = getData["error"];
//             if (error == "false") {
//               perTotal = int.parse(getData["total"]);
//               if ((perOffset) < perTotal) {
//                 tempUserList.clear();
//                 var data = getData["data"];
//                 tempUserList = (data as List)
//                     .map((data) => new NotificationModel.fromJson(data))
//                     .toList();

//                 userNoti.addAll(tempUserList);
//                 perOffset = perOffset + perPage;
//               }
//             } else {
//               isPerLoadingmore = false;
//             }
//             if (mounted)
//               setState(() {
//                 _isPerLoading = false;
//               });
//           }
//         } on TimeoutException catch (_) {
//           setSnackbar(getTranslated(context, 'somethingMSg')!);
//           setState(() {
//             _isPerLoading = false;
//             isPerLoadingmore = false;
//           });
//         }
//       } else {
//         setSnackbar(getTranslated(context, 'internetmsg')!);
//         setState(() {
//           _isPerLoading = false;
//           isPerLoadingmore = false;
//         });
//       }
//     } else {
//       setState(() {
//         _isPerLoading = false;
//       });
//     }
//   }

// //set snackbar msg
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

//   _scrollListener() {
//     if (controller.offset >= controller.position.maxScrollExtent &&
//         !controller.position.outOfRange) {
//       if (this.mounted) {
//         setState(() {
//           isLoadingmore = true;

//           if (offset < total) getNotification();
//         });
//       }
//     }
//   }

//   _scrollListener1() {
//     if (controller1.offset >= controller1.position.maxScrollExtent &&
//         !controller1.position.outOfRange) {
//       if (this.mounted) {
//         setState(() {
//           isPerLoadingmore = true;

//           if (perOffset < perTotal) getUserNotification();
//         });
//       }
//     }
//   }

//   static const String FEED_URLRSS =
//       'https://www.bhaskar.com/rss-v1--category-1740.xml';
//   RssFeed? _feedRSS;
//   String _titleRSS = "";
//   static const String loadingFeedMsg = 'Loading Feed...';
//   static const String feedLoadErrorMsg = 'Error Loading Feed.';
//   static const String feedOpenErrorMsg = 'Error Opening Feed.';
//   static const String placeholderImg = 'images/no_image.png';
//   GlobalKey<RefreshIndicatorState>? _refreshKey;

//   updateFeed(feed) {
//     setState(() {
//       _feedRSS = feed;
//     });
//   }

//   Future<void> openFeed(String url) async {
//     if (await canLaunch(url)) {
//       await launch(
//         url,
//         forceSafariVC: true,
//         forceWebView: false,
//       );
//       return;
//     }
//     updateTitleRSS(feedOpenErrorMsg);
//   }

//   updateTitleRSS(title) {
//     setState(() {
//       _titleRSS = title;
//     });
//   }

//   loadRSS() async {
//     updateTitleRSS(loadingFeedMsg);
//     loadFeedRSS().then((result) {
//       if (null == result || result.toString().isEmpty) {
//         updateTitleRSS(feedLoadErrorMsg);
//         return;
//       }
//       updateFeed(result);
//       updateTitleRSS(_feedRSS!.title);
//     });
//   }

//   Future<RssFeed?> loadFeedRSS() async {
//     try {
//       final client = http.Client();
//       final response = await client.get(Uri.parse(FEED_URLRSS));
//       return RssFeed.parse(response.body);
//     } catch (e) {
//       //
//     }
//     return null;
//   }

//   titleRSS(title) {
//     return Text(
//       title.toString(),
//       style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
//       maxLines: 2,
//       overflow: TextOverflow.ellipsis,
//     );
//   }

//   subtitleRSS(subTitle) {
//     return Text(
//       convertToAgo(DateTime.parse(subTitle.toString()), 0)!,
//       style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w100),
//       maxLines: 1,
//       overflow: TextOverflow.ellipsis,
//     );
//   }

//   thumbnailRSS(imageUrl) {
//     return Padding(
//       padding: EdgeInsets.only(left: 15.0),
//       child: imageUrl == null
//           ? Image.asset("assets/images/noImage.jpeg")
//           : CachedNetworkImage(
//               placeholder: (context, url) =>
//                   Image.asset("assets/images/noImage.jpeg"),
//               imageUrl: imageUrl,
//               height: 50,
//               width: 70,
//               alignment: Alignment.center,
//               fit: BoxFit.fill,
//             ),
//       // child: titleRSS(imageUrl.toString()),
//     );
//   }

//   rightIconRSS() {
//     return Icon(
//       Icons.keyboard_arrow_right,
//       color: Colors.grey,
//       size: 30.0,
//     );
//   }

//   listRSS() {
//     return ListView.builder(
//       itemCount: _feedRSS!.items!.length,
//       itemBuilder: (BuildContext context, int index) {
//         final item = _feedRSS!.items![index];
//         return ListTile(
//           title: titleRSS(item.title),
//           subtitle: subtitleRSS(item.pubDate),
//           leading: thumbnailRSS(item.media!.contents!.first.url),
//           // leading: thumbnailRSS(item.enclosure?.url),
//           trailing: rightIconRSS(),
//           contentPadding: EdgeInsets.all(5.0),
//           onTap: () => openFeed(item.link!),
//         );
//       },
//     );
//   }
// }
