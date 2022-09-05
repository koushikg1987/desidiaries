import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart';
import 'package:news/Helper/Color.dart';

import 'Helper/Constant.dart';
import 'Helper/Session.dart';
import 'Helper/String.dart';
import 'Login.dart';
import 'Model/News.dart';
import 'NewsDetails.dart';

class NewsTag extends StatefulWidget {
  final String? tadId;
  final String? tagName;
  final Function? updateParent;

  NewsTag({Key? key, this.tadId, this.tagName, this.updateParent})
      : super(key: key);

  @override
  NewsTagState createState() => NewsTagState();
}

class NewsTagState extends State<NewsTag> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isNetworkAvail = true;
  List<News> tagNewsList = [];
  bool _isLoading = true;
  List bookMarkValue = [];
  List<News> bookmarkList = [];
  bool isFirst = false;

  @override
  void initState() {
    super.initState();
    callApi();
  }

  callApi() async {
    getNewsByTag();
    await _getBookmark();
  }

  Future<void> getNewsByTag() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var param = {
          ACCESS_KEY: access_key,
          TAG_ID: widget.tadId,
          USER_ID: CUR_USERID != null && CUR_USERID != "" ? CUR_USERID : "0"
        };

        Response response = await post(Uri.parse(getNewsByTagApi),
                body: param, headers: headers)
            .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);



        String error = getdata["error"];
        if (error == "false") {
          var data = getdata["data"];
          tagNewsList =
              (data as List).map((data) => new News.fromJson(data)).toList();

          if (mounted)
            setState(() {
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

  newsItem(int index) {
    List<String> tagList = [];
    DateTime time1 = DateTime.parse(tagNewsList[index].date!);
    if (tagNewsList[index].tagName! != "") {
      final tagName = tagNewsList[index].tagName!;
      tagList = tagName.split(',');
    }

    List<String> tagId = [];

    if (tagNewsList[index].tagId! != "") {
      tagId = tagNewsList[index].tagId!.split(",");
    }
    return Padding(
        padding: EdgeInsetsDirectional.only(top: index == 0 ? 0 : 15.0),
        child: Column(children: <Widget>[
          Hero(
            tag: tagNewsList[index].id!,
            child: InkWell(
              child: Stack(
                children: <Widget>[
                  ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: FadeInImage(
                          fadeInDuration: Duration(milliseconds: 150),
                          image: CachedNetworkImageProvider(
                              tagNewsList[index].image!),
                          height: 320.0,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) =>
                              errorWidget(320, double.infinity),
                          placeholder: AssetImage(
                            placeHolder,
                          ))),
                  Positioned.directional(
                      textDirection: Directionality.of(context),
                      bottom: 10.0,
                      start: 10,
                      end: 10,
                      height: 123,
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
                                              fontSize: 13.0),
                                    ),
                                    Padding(
                                        padding: EdgeInsets.only(top: 6.0),
                                        child: Text(
                                          tagNewsList[index].title!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle1
                                              ?.copyWith(
                                                  color: colors.tempdarkColor
                                                      .withOpacity(0.9),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                  height: 1.0),
                                          maxLines: 3,
                                          softWrap: true,
                                          overflow: TextOverflow.ellipsis,
                                        )),
                                    Padding(
                                        padding: EdgeInsets.only(top: 6.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            tagNewsList[index].tagName! != ""
                                                ? SizedBox(
                                                    height: 23.0,
                                                    child: ListView.builder(
                                                        physics:
                                                            ClampingScrollPhysics(),
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        shrinkWrap: true,
                                                        itemCount:
                                                            tagList.length >= 3
                                                                ? 3
                                                                : tagList
                                                                    .length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          return Padding(
                                                              padding: EdgeInsetsDirectional
                                                                  .only(
                                                                      start: index ==
                                                                              0
                                                                          ? 0
                                                                          : 4),
                                                              child: InkWell(
                                                                child:
                                                                    Container(
                                                                        height:
                                                                            23.0,
                                                                        width:
                                                                            65,
                                                                        alignment:
                                                                            Alignment
                                                                                .center,
                                                                        padding: EdgeInsetsDirectional.only(
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
                                                                              BorderRadius.circular(3.0),
                                                                          color: colors
                                                                              .primary
                                                                              .withOpacity(0.08),
                                                                        ),
                                                                        child:
                                                                            Text(
                                                                          tagList[
                                                                              index],
                                                                          style: Theme.of(context)
                                                                              .textTheme
                                                                              .bodyText2
                                                                              ?.copyWith(
                                                                                color: colors.primary,
                                                                                fontSize: 12,
                                                                              ),
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
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
                                                                          tadId:
                                                                              tagId[index],
                                                                          tagName:
                                                                              tagList[index],
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
                                                        tagNewsList[index].id)
                                                    ? "assets/images/bookmarkfilled_icon.svg"
                                                    : "assets/images/bookmark_icon.svg",
                                                semanticsLabel: 'bookmark icon',
                                                height: 19,
                                                width: 19,
                                              ),
                                              onTap: () async {
                                                _isNetworkAvail =
                                                    await isNetworkAvailable();
                                                if (CUR_USERID != "") {
                                                  if (_isNetworkAvail) {
                                                    setState(() {
                                                      bookMarkValue.contains(
                                                              tagNewsList[index]
                                                                  .id!)
                                                          ? _setBookmark(
                                                              "0",
                                                              tagNewsList[index]
                                                                  .id!)
                                                          : _setBookmark(
                                                              "1",
                                                              tagNewsList[index]
                                                                  .id!);
                                                    });
                                                  } else {
                                                    setSnackbar(getTranslated(
                                                        context,
                                                        'internetmsg')!);
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
                                              padding:
                                                  EdgeInsetsDirectional.only(
                                                      start: 13.0),
                                              child: InkWell(
                                                child: SvgPicture.asset(
                                                  "assets/images/share_icon.svg",
                                                  semanticsLabel: 'share icon',
                                                  height: 19,
                                                  width: 19,
                                                ),
                                                onTap: () async {
                                                  _isNetworkAvail =
                                                      await isNetworkAvailable();
                                                  if (_isNetworkAvail) {
                                                    createDynamicLink(
                                                        tagNewsList[index].id!,
                                                        index,
                                                        tagNewsList[index]
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
                            borderRadius: BorderRadius.circular(55.0),
                            child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  height: 55,
                                  width: 55,
                                  padding: EdgeInsets.all(13),
                                  decoration: BoxDecoration(
                                      color:
                                          colors.tempboxColor.withOpacity(0.5),
                                      shape: BoxShape.circle),
                                  child: SvgPicture.asset(
                                    tagNewsList[index].like == "1"
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
                                if (tagNewsList[index].like == "1") {
                                  _setLikesDisLikes(
                                      "0", tagNewsList[index].id!, index);

                                  setState(() {});
                                } else {
                                  _setLikesDisLikes(
                                      "1", tagNewsList[index].id!, index);

                                  setState(() {});
                                }
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
                        },
                      ))
                ],
              ),
              onTap: () {
                News model = tagNewsList[index];
                List<News> tgList = [];
                tgList.addAll(tagNewsList);
                tgList.removeAt(index);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => NewsDetails(
                          model: model,
                          index: index,
                          updateParent: updateHomePage,
                          id: model.id,
                          isFav: false,
                          isDetails: true,
                          news: tgList,
                        )));
              },
            ),
          ),
        ]));
  }

  //set likes of news using api
  _setLikesDisLikes(String status, String id, int index) async {
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

      var getdata = json.decode(response.body);

      String error = getdata["error"];

      String msg = getdata["message"];

      if (error == "false") {
        if (status == "1") {
          tagNewsList[index].like = "1";
          tagNewsList[index].totalLikes =
              (int.parse(tagNewsList[index].totalLikes!) + 1).toString();
          setSnackbar(getTranslated(context, 'like_succ')!);
        } else if (status == "0") {
          tagNewsList[index].like = "0";
          tagNewsList[index].totalLikes =
              (int.parse(tagNewsList[index].totalLikes!) - 1).toString();
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
          Response response = await post(Uri.parse(getBookmarkApi),
                  body: param, headers: headers)
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
              bookMarkValue.add(bookmarkList[i].newsId);
            }
          }
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!);
        }
      } else {
        setSnackbar(getTranslated(context, 'internetmsg')!);
      }
    }
  }

  updateHomePage() {
    setState(() {
      bookmarkList.clear();
      bookMarkValue.clear();
      _getBookmark();
    });
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

      Response response =
          await post(Uri.parse(setBookmarkApi), body: param, headers: headers)
              .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      String error = getdata["error"];

      String msg = getdata["message"];

      if (error == "false") {
        if (status == "0") {
          setSnackbar(msg);
          widget.updateParent!();
        } else {
          setSnackbar(msg);
          widget.updateParent!();
        }
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg')!);
    }
  }

  viewContent() {
    return Padding(
        padding: EdgeInsetsDirectional.only(
            top: 0.0, bottom: 10.0, start: 13.0, end: 13.0),
        child: _isLoading
            ? contentShimmer(context)
            : tagNewsList.length == 0
                ? Center(
                    child: Text(getTranslated(context, 'no_news')!,
                        style: Theme.of(context).textTheme.subtitle1?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .fontColor
                                .withOpacity(0.8))))
                : Padding(
                    padding: EdgeInsetsDirectional.only(
                      top: 15.0,
                    ),
                    child: ListView.builder(
                      itemCount: tagNewsList.length,
                      itemBuilder: (context, index) {
                        return newsItem(index);
                      },
                    )));
  }

  //set appbar
  getAppBar() {
    return PreferredSize(
        preferredSize: Size(double.infinity, 45),
        child: AppBar(
          leadingWidth: 50,
          elevation: 0.0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          title: Text(
            widget.tagName!,
            style: Theme.of(context).textTheme.headline6?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5),
          ),
          leading: Builder(builder: (BuildContext context) {
            return Padding(
                padding: EdgeInsetsDirectional.only(
                    start: 15.0, top: 5.0, bottom: 5.0),
                child: Container(
                    height: 38,
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.boxColor,
                        boxShadow: [
                          BoxShadow(
                              blurRadius: 10.0,
                              offset: const Offset(5.0, 5.0),
                              color: Theme.of(context)
                                  .colorScheme
                                  .fontColor
                                  .withOpacity(0.1),
                              spreadRadius: 1.0),
                        ],
                        borderRadius: BorderRadius.circular(6.0)),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: SvgPicture.asset(
                        "assets/images/back_icon.svg",
                        semanticsLabel: 'back icon',
                        color: Theme.of(context).colorScheme.fontColor,
                      ),
                    )));
          }),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: getAppBar(),
      body: viewContent(),
    );
  }
}
