import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart';
import 'package:news/Helper/Color.dart';
import 'package:news/appBarTitle.dart';

import 'Helper/Constant.dart';
import 'Helper/Session.dart';
import 'Helper/String.dart';
import 'Login.dart';
import 'Model/News.dart';
import 'NewsDetails.dart';
import 'NewsTag.dart';

class Bookmark extends StatefulWidget {
  @override
  BookmarkState createState() => BookmarkState();
}

List bookMarkValue = [];
List likeDisLikeValue = [];
List<News> bookmarkList = [];
int offset = 0;
int total = 0;
bool isLoadingmore = true;
bool _isLoading = true;

class BookmarkState extends State<Bookmark> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isNetworkAvail = true;
  List<News> tempList = [];
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  ScrollController _controller = new ScrollController();
  bool enabled = true;

  @override
  void initState() {
    _controller.addListener(_scrollListener);
    getUserDetails();
    _getBookmark();
    super.initState();
  }

  @override
  void dispose() {
    _controller.removeListener(() {});
    super.dispose();
  }

  Future<void> getUserDetails() async {
    CUR_USERID = (await getPrefrence(ID)) ?? "";
    setState(() {});
  }

  //get bookmark api here
  _getBookmark() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (CUR_USERID != "") {
        try {
          var param = {
            ACCESS_KEY: access_key,
            USER_ID: CUR_USERID,
            LIMIT: perPage.toString(),
            OFFSET: offset.toString(),
          };
          Response response = await post(Uri.parse(getBookmarkApi),
                  body: param, headers: headers)
              .timeout(Duration(seconds: timeOut));

          var getdata = json.decode(response.body);

          String error = getdata["error"];
          if (error == "false") {
            total = int.parse(getdata["total"]);

            if ((offset) < total) {
              var data = getdata["data"];
              tempList.clear();
              tempList = (data as List)
                  .map((data) => new News.fromJson(data))
                  .toList();
              if (offset == 0) bookmarkList.clear();
              bookmarkList.addAll(tempList);
              bookMarkValue.clear();
              for (int i = 0; i < bookmarkList.length; i++) {
                bookMarkValue.add(bookmarkList[i].newsId);
              }
              offset = offset + perPage;
            }

            if (this.mounted)
              setState(() {
                _isLoading = false;
              });
          } else {
            setState(() {
              isLoadingmore = false;
              _isLoading = false;
            });
          }
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!);
        }
      } else {
        setState(() {
          isLoadingmore = false;
          _isLoading = false;
        });
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg')!);
    }
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

  //news bookmark list have no news then call this function
  Widget getNoItem() {
    return Center(child: Text(getTranslated(context, 'bookmark_nt_avail')!));
  }

  //user not login then show this function used to navigate login screen
  Widget loginMsg() {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Container(
        height: height,
        width: width,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              getTranslated(context, 'bookmark_login')!,
              style: Theme.of(context).textTheme.subtitle2,
              textAlign: TextAlign.center,
            ),
            InkWell(
                child: Text(
                  getTranslated(context, 'loginnow_lbl')!,
                  style: Theme.of(context)
                      .textTheme
                      .subtitle2
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Login(),
                      ));
                }),
          ],
        ));
  }

  callApi() {
    offset = 0;
    total = 0;
    _getBookmark();
  }

  //refresh function to refresh page
  Future<String> _refresh() async {
    setState(() {
      _isLoading = true;
    });
    return callApi();
  }

  _scrollListener() {
    if (_controller.offset >= _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange) {
      if (this.mounted) {
        setState(() {
          isLoadingmore = true;
          if (offset < total) _getBookmark();
        });
      }
    }
  }

  updateFav() {
    setState(() {
      offset = 0;
      total = 0;
      bookmarkList.clear();
      bookMarkValue.clear();
      _getBookmark();
    });
  }

  //set bookmook api here
  _setBookmark(String status, String id, int index) async {
    if (bookMarkValue.contains(id)) {
      setState(() {
        bookmarkList = List.from(bookmarkList)..removeAt(index);
        bookMarkValue = List.from(bookMarkValue)..remove(id);
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
      Response response =
          await post(Uri.parse(setBookmarkApi), body: param, headers: headers)
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

  //set likes of news using api
  _setLikesDisLikes(String status, String id) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
        USER_ID: CUR_USERID,
        NEWS_ID: id,
        STATUS: status,
      };

      Response response = await post(Uri.parse(setLikesDislikesApi),
              body: param, headers: headers)
          .timeout(Duration(seconds: timeOut));

      var getData = json.decode(response.body);

      String error = getData["error"];

      if (error == "false") {
        if (status == "1") {
          setSnackbar(getTranslated(context, 'like_succ')!);
        } else if (status == "2") {
          setSnackbar(getTranslated(context, 'dislike_succ')!);
        }
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg')!);
    }
  }

  //show bookmarklist
  getBookmarkList() {
    return RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refresh,
        child: ListView.builder(
            controller: _controller,
            shrinkWrap: true,
            physics: AlwaysScrollableScrollPhysics(),
            itemCount: bookmarkList.length,
            itemBuilder: (context, index) {
              DateTime time1 = DateTime.parse(bookmarkList[index].date!);
              List<String> tagList = [];
              if (bookmarkList[index].tagName! != "") {
                final tagName = bookmarkList[index].tagName!;
                tagList = tagName.split(',');
              }

              List<String> tagId = [];

              if (bookmarkList[index].tagId! != "") {
                tagId = bookmarkList[index].tagId!.split(",");
              }

              return (index == bookmarkList.length && isLoadingmore)
                  ? Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: EdgeInsetsDirectional.only(top: 15.0),
                      child: Hero(
                          tag: bookmarkList[index].id!,
                          child: AbsorbPointer(
                            absorbing: !enabled,
                            child: InkWell(
                              child: Stack(
                                children: [
                                  ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: FadeInImage.assetNetwork(
                                        image: bookmarkList[index].image!,
                                        height: 320.0,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholder: placeHolder,
                                        imageErrorBuilder:
                                            (context, error, stackTrace) {
                                          return errorWidget(320,double.infinity);
                                        },
                                      )),
                                  Positioned.directional(
                                      textDirection: Directionality.of(context),
                                      bottom: 10.0,
                                      start: 10,
                                      end: 10,
                                      height: 123,
                                      child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                  sigmaX: 15, sigmaY: 15),
                                              child: Container(
                                                alignment: Alignment.center,
                                                padding: EdgeInsets.all(10.0),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10.0),
                                                  color: colors.tempboxColor
                                                      .withOpacity(0.85),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Text(
                                                      convertToAgo(time1, 0)!,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .caption
                                                          ?.copyWith(
                                                              color: colors
                                                                  .tempdarkColor,
                                                              fontSize: 13.0),
                                                    ),
                                                    Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                top: 8.0),
                                                        child: Text(
                                                          bookmarkList[index]
                                                              .title!,
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .subtitle1
                                                              ?.copyWith(
                                                                  color: colors
                                                                      .tempdarkColor
                                                                      .withOpacity(
                                                                          0.9),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 15,
                                                                  height: 1.0,
                                                                  letterSpacing:
                                                                      0.5),
                                                          maxLines: 3,
                                                          softWrap: true,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        )),
                                                    Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                top: 8.0),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: <Widget>[
                                                            bookmarkList[index]
                                                                        .tagName! !=
                                                                    ""
                                                                ? SizedBox(
                                                                    height:
                                                                        23.0,
                                                                    child: ListView.builder(
                                                                        physics: ClampingScrollPhysics(),
                                                                        scrollDirection: Axis.horizontal,
                                                                        shrinkWrap: true,
                                                                        controller: _controller,
                                                                        itemCount: tagList.length >= 3 ? 3 : tagList.length,
                                                                        itemBuilder: (context, index) {
                                                                          return Padding(
                                                                              padding: EdgeInsetsDirectional.only(start: index == 0 ? 0 : 4),
                                                                              child: InkWell(
                                                                                child: ClipRRect(
                                                                                    borderRadius: BorderRadius.circular(3.0),
                                                                                    child: BackdropFilter(
                                                                                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                                                                                        child: Container(
                                                                                            height: 23.0,
                                                                                            width: 65,
                                                                                            alignment: Alignment.center,
                                                                                            padding: EdgeInsetsDirectional.only(start: 3.0, end: 3.0, top: 2.5, bottom: 2.5),
                                                                                            decoration: BoxDecoration(
                                                                                              borderRadius: BorderRadius.circular(3.0),
                                                                                              color: colors.primary.withOpacity(0.03),
                                                                                            ),
                                                                                            child: Text(
                                                                                              tagList[index],
                                                                                              style: Theme.of(context).textTheme.bodyText2?.copyWith(
                                                                                                    color: colors.primary,
                                                                                                    fontSize: 12,
                                                                                                  ),
                                                                                              overflow: TextOverflow.ellipsis,
                                                                                              softWrap: true,
                                                                                            )))),
                                                                                onTap: () {
                                                                                  Navigator.push(
                                                                                      context,
                                                                                      MaterialPageRoute(
                                                                                        builder: (context) => NewsTag(
                                                                                          tadId: tagId[index],
                                                                                          tagName: tagList[index],
                                                                                          updateParent: updateFav,
                                                                                        ),
                                                                                      ));
                                                                                },
                                                                              ));
                                                                        }))
                                                                : Container(),
                                                            Spacer(),
                                                            InkWell(
                                                                child:
                                                                    SvgPicture
                                                                        .asset(
                                                                  bookMarkValue.contains(
                                                                          bookmarkList[index]
                                                                              .newsId)
                                                                      ? "assets/images/bookmarkfilled_icon.svg"
                                                                      : "assets/images/bookmark_icon.svg",
                                                                  semanticsLabel:
                                                                      'bookmark icon',
                                                                  height: 19,
                                                                  width: 19,
                                                                  color: colors
                                                                      .primary,
                                                                ),
                                                                onTap:
                                                                    () async {
                                                                  if (CUR_USERID !=
                                                                      "") {
                                                                    _isNetworkAvail =
                                                                        await isNetworkAvailable();
                                                                    if (_isNetworkAvail) {
                                                                      _setBookmark(
                                                                          "0",
                                                                          bookmarkList[index]
                                                                              .newsId!,
                                                                          index);
                                                                    } else {
                                                                      setSnackbar(getTranslated(
                                                                          context,
                                                                          'internetmsg')!);
                                                                    }
                                                                  } else {
                                                                    Navigator
                                                                        .pushReplacement(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                          builder: (context) =>
                                                                              Login()),
                                                                    );
                                                                  }
                                                                }),
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .only(
                                                                          start:
                                                                              13.0),
                                                              child: InkWell(
                                                                child:
                                                                    SvgPicture
                                                                        .asset(
                                                                  "assets/images/share_icon.svg",
                                                                  semanticsLabel:
                                                                      'share icon',
                                                                  height: 19,
                                                                  width: 19,
                                                                ),
                                                                onTap:
                                                                    () async {
                                                                  _isNetworkAvail =
                                                                      await isNetworkAvailable();
                                                                  if (_isNetworkAvail) {
                                                                    createDynamicLink(
                                                                        bookmarkList[index]
                                                                            .newsId!,
                                                                        index,
                                                                        bookmarkList[index]
                                                                            .title!);
                                                                  } else {
                                                                    setSnackbar(getTranslated(
                                                                        context,
                                                                        'internetmsg')!);
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
                                      bottom: (320 - 113) / 2,
                                      start: deviceWidth! * 0.67,
                                      child: InkWell(
                                        child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(55.0),
                                            child: BackdropFilter(
                                                filter: ImageFilter.blur(
                                                    sigmaX: 10, sigmaY: 10),
                                                child: Container(
                                                  height: 55,
                                                  width: 55,
                                                  padding: EdgeInsets.all(13),
                                                  decoration: BoxDecoration(
                                                      color: colors.tempboxColor
                                                          .withOpacity(0.5),
                                                      shape: BoxShape.circle),
                                                  child: SvgPicture.asset(
                                                    bookmarkList[index].like ==
                                                            "1"
                                                        ? "assets/images/likefilled_button.svg"
                                                        : "assets/images/Like_icon.svg",
                                                    semanticsLabel: 'like icon',
                                                  ),
                                                ))),
                                        onTap: () async {
                                          if (CUR_USERID != "") {
                                            _isNetworkAvail =
                                                await isNetworkAvailable();
                                            if (_isNetworkAvail) {
                                              if (bookmarkList[index].like ==
                                                  "1") {
                                                _setLikesDisLikes(
                                                    "2",
                                                    bookmarkList[index]
                                                        .newsId!);
                                                bookmarkList[index].like = "0";

                                                setState(() {});
                                              } else {
                                                _setLikesDisLikes(
                                                    "1",
                                                    bookmarkList[index]
                                                        .newsId!);
                                                bookmarkList[index].like = "1";
                                                setState(() {});
                                              }
                                            } else {
                                              setSnackbar(getTranslated(
                                                  context, 'internetmsg')!);
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
                              onTap: () async {
                                setState(() {
                                  enabled = false;
                                });
                                News model = bookmarkList[index];
                                List<News> bookList=[];
                                bookList.addAll(bookmarkList);
                                bookList.removeAt(index);
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        NewsDetails(
                                          model: model,
                                          index: index,
                                          updateParent: updateFav,
                                          id: model.newsId,
                                          isFav: true,
                                          isDetails: true,
                                          news:bookList ,
                                        )));
                                setState(() {
                                  enabled = true;
                                });
                              },
                            ),
                          )));
            }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: PreferredSize(
            preferredSize: Size(double.infinity, 35),
            // child: Center(
            //     child: Padding(
            //         padding: EdgeInsets.only(top: 35.0),
            //         child: Text(
            //           getTranslated(context, 'bookmark_lbl')!,
            //           style: Theme.of(context).textTheme.headline6?.copyWith(
            //               color: colors.primary,
            //               fontWeight: FontWeight.w600,
            //               letterSpacing: 0.5),
            //         )))
            child: appBarTitle()
            ),
        body: Padding(
          padding: EdgeInsetsDirectional.only(
              top: 0.0, bottom: 10.0, start: 13.0, end: 13.0),
          child: _isLoading
              ? contentShimmer(context)
              : CUR_USERID != ""
                  ? bookmarkList.length == 0
                      ? getNoItem()
                      : getBookmarkList()
                  : loginMsg(),
        ));
  }
}
