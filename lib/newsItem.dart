import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:news/Helper/Color.dart';
import 'package:news/Helper/Constant.dart';
import 'package:news/Helper/Session.dart';
import 'package:news/Helper/String.dart';
import 'package:news/Home.dart';
import 'package:news/Login.dart';
import 'package:news/Model/News.dart';
import 'package:news/NewsDetails.dart';
import 'package:readmore/readmore.dart';
import 'package:video_player/video_player.dart';
import 'package:webfeed/domain/media/category.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class NewsItem extends StatefulWidget {
  int index;
  NewsItem({
    Key? key,
    required this.index,
  }) : super(key: key);

  @override
  State<NewsItem> createState() => _NewsItemState();
}

class _NewsItemState extends State<NewsItem> {
  List<News> tempList = [];
  List<Category> tempCatList = [];
  String? error;
  final TextEditingController textController = TextEditingController();
  int offsetRecent = 0;
  int totalRecent = 0;
  int offsetUser = 0;
  int totalUser = 0;
  String? catId = "";
  List<Map<String, dynamic>> _tabs = [];
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
  int _curSlider = 0;
  int? selectSubCat = 0;

  bool isFirst = false;
  var isliveNews;

  List<News> newsList = [];
  List<News> tempNewsList = [];
  String selectedCity = select;
  List<String> cityList = [select];

  int offset = 0;
  int total = 0;
  bool enabled = true;
  ScrollController controller = new ScrollController();
  ScrollController controller1 = new ScrollController();
  bool isTab = true;
  List<String> tagId = [];
  List<String> tagList = [];
  YoutubePlayerController? _yc;

  bool errorrrr = false;
  String errorMessage = "";
  VideoPlayerController? flickManager;
  VideoPlayerController? flickManager1;
  Future<void> callApi() async {
    getSetting();

    await getCity();
    await getUserByCatNews();
  }

  @override
  void initState() {
    callApi();
    if (recentNewsList[widget.index].tagName! != "") {
      final tagName = recentNewsList[widget.index].tagName!;
      tagList = tagName.split(',');
    }

    if (recentNewsList[widget.index].tagId! != "") {
      tagId = recentNewsList[widget.index].tagId!.split(",");
    }

    allImage.clear();

    allImage.add(recentNewsList[widget.index].image!);
    if (recentNewsList[widget.index].imageDataList!.length != 0) {
      for (int i = 0;
          i < recentNewsList[widget.index].imageDataList!.length;
          i++) {
        allImage
            .add(recentNewsList[widget.index].imageDataList![i].otherImage!);
      }
    }

    if (recentNewsList[widget.index].contentValue != "" ||
        recentNewsList[widget.index].contentValue != null) {
      if (recentNewsList[widget.index].contentType == "video_upload") {
        flickManager = VideoPlayerController.network(
            recentNewsList[widget.index].contentValue!)
          ..initialize().then((value) {
            setState(() {});
            flickManager!.play();
          });
      } else if (recentNewsList[widget.index].contentType == "video_youtube") {
        _yc = YoutubePlayerController(
          initialVideoId:
              YoutubePlayer.convertUrlToId(recentNewsList[widget.index].contentValue!)!,
              // YoutubePlayer.convertUrlToId(
              //     "https://www.youtube.com/watch?v=hS5CfP8n_js")!,
          flags: YoutubePlayerFlags(
            autoPlay: true,
          ),
        );
      } else if (recentNewsList[widget.index].contentType == "video_other") {
        flickManager1 = VideoPlayerController.network(
            recentNewsList[widget.index].contentValue!)
          ..initialize().then((value) {
            setState(() {});
            flickManager1!.play();
          });
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        News model = recentNewsList[widget.index];
        List<News> recList = [];
        recList.addAll(recentNewsList);
        recList.removeAt(widget.index);
        Navigator.of(context).push(MaterialPageRoute(
            builder: (BuildContext context) => NewsDetails(
                  model: model,
                  index: widget.index,
                  updateParent: () {},
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
                    child: (recentNewsList[widget.index].image == null ||
                                recentNewsList[widget.index].image!.isEmpty) &&
                            recentNewsList[widget.index].contentType ==
                                "video_upload"
                        ? Container(
                            height: MediaQuery.of(context).size.height,
                            width: MediaQuery.of(context).size.width,
                            color: Colors.black,
                            alignment: Alignment.center,
                            // child: FlickVideoPlayer(
                            //     flickManager: FlickManager(
                            //         videoPlayerController: VideoPlayerController.network(
                            //             recentNewsList[widget.index].contentValue!),
                            //         autoPlay: true)))
                            child: VideoPlayer(flickManager!))
                        : (recentNewsList[widget.index].image == null ||
                                    recentNewsList[widget.index]
                                        .image!
                                        .isEmpty) &&
                                recentNewsList[widget.index].contentType ==
                                    "video_youtube"
                            ? YoutubePlayerBuilder(
                                player: YoutubePlayer(
                                  controller: _yc!,
                                  showVideoProgressIndicator: true,
                                  progressIndicatorColor: colors.primary,
                                ),
                                builder: (context, player) {
                                  return Center(child: player);
                                })
                            : (recentNewsList[widget.index].image == null ||
                                        recentNewsList[widget.index]
                                            .image!
                                            .isEmpty) &&
                                    recentNewsList[widget.index].contentType ==
                                        "video_other"
                                ? Container(
                                    alignment: Alignment.center,
                                    // child: FlickVideoPlayer(
                                    //     flickManager: FlickManager(
                                    //         videoPlayerController: VideoPlayerController.network(
                                    //             recentNewsList[widget.index].contentValue!),
                                    //         autoPlay: true)))
                                    child: VideoPlayer(flickManager1!))
                                : FadeInImage(
                                    fadeInDuration: Duration(milliseconds: 150),
                                    image: CachedNetworkImageProvider(
                                        recentNewsList[widget.index].image!),
                                    height: 250.0,
                                    width: 450.0,
                                    fit: BoxFit.cover,
                                    imageErrorBuilder:
                                        (context, error, stackTrace) =>
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
                                          recentNewsList[widget.index].title!,
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
                                          recentNewsList[widget.index].desc!,
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
                                        //   data: recentNewsList[widget.index].desc!,
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
                                                  convertToAgo(
                                                      DateTime.parse(
                                                          recentNewsList[
                                                                  widget.index]
                                                              .date!),
                                                      0)! +
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
                                                  (recentNewsList[widget.index]
                                                      .totalLikes = (int.parse(
                                                              recentNewsList[
                                                                      widget
                                                                          .index]
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
                                    if (recentNewsList[widget.index].like ==
                                        "1") {
                                      _setLikesDisLikes(
                                          "0",
                                          recentNewsList[widget.index].id!,
                                          widget.index,
                                          1);

                                      setState(() {});
                                    } else {
                                      _setLikesDisLikes(
                                          "1",
                                          recentNewsList[widget.index].id!,
                                          widget.index,
                                          1);
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
                                    recentNewsList[widget.index].like == "1"
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
                                createDynamicLink(
                                    recentNewsList[widget.index].id!,
                                    widget.index,
                                    recentNewsList[widget.index].title!);
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
                                    bookMarkValue.contains(
                                            recentNewsList[widget.index].id!)
                                        ? _setBookmark("0",
                                            recentNewsList[widget.index].id!)
                                        : _setBookmark("1",
                                            recentNewsList[widget.index].id!);
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
                                    bookMarkValue.contains(
                                            recentNewsList[widget.index].id)
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
              widget.index == 0
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
                                dropdownColor:
                                    errorrrr ? Colors.white : Colors.black,
                                items: cityList.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value.split(splitText).first,
                                        style: TextStyle(
                                            color: errorrrr
                                                ? Colors.black
                                                : Colors.white,
                                            fontSize: deviceWidth! * 0.035)),
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
          )),
    );
  }

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
