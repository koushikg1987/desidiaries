import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

//import 'package:admob_flutter/admob_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:facebook_audience_network/ad/ad_interstitial.dart';
import 'package:facebook_audience_network/ad/ad_native.dart';
import 'package:facebook_audience_network/ad/ad_rewarded.dart';
import 'package:facebook_audience_network/facebook_audience_network.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart';
import 'package:news/Helper/FbAdHelper.dart';
import 'package:news/Model/BreakingNews.dart';
import 'package:news/Model/Comment.dart';
import 'package:news/Model/News.dart';
import 'package:news/NewsVideo.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'Helper/AdHelper.dart';
import 'Helper/Color.dart';
import 'Helper/Constant.dart';
import 'Helper/Session.dart';
import 'Helper/String.dart';
import 'Image_Preview.dart';
import 'Login.dart';
import 'NewsTag.dart';

class NewsDetails extends StatefulWidget {
  final News? model;
  final int? index;
  Function? updateParent;
  final String? id;
  final bool? isFav;
  final bool? isDetails;
  final List<News>? news;
  final BreakingNewsModel? model1;
  final List<BreakingNewsModel>? news1;

  NewsDetails(
      {Key? key,
      this.model,
      this.index,
      this.updateParent,
      this.id,
      this.isFav,
      this.isDetails,
      this.news,
      this.model1,
      this.news1})
      : super(key: key);

  @override
  NewsDetailsState createState() => NewsDetailsState();
}

class NewsDetailsState extends State<NewsDetails> {
  static final AdRequest request = AdRequest(
    keywords: <String>['foo', 'bar'],
    contentUrl: 'http://foo.com/bar.html',
    nonPersonalizedAds: true,
  );
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isNetworkAvail = true;
  List<News> tempList = [];
  bool _isLoading = true;
  bool isLoadingmore = true;
  int offset = 0;
  int total = 0;
  int _curSlider = 0;
  final PageController pageController = PageController();
  bool isScroll = false;
  bool _isInterstitialAdLoaded = false;
  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;
  int maxFailedLoadAttempts = 3;
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;

  @override
  void initState() {
    fbInit();
    getUserDetails();
    _loadInterstitialAd();
    _createRewardedAd();
    _createInterstitialAd();
    super.initState();
  }

  fbInit() async {
    String? deviceId = await _getId();

    FacebookAudienceNetwork.init(
        iOSAdvertiserTrackingEnabled: true, testingId: deviceId);
  }

  Future<String?> _getId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor; // Unique ID on iOS
    } else {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.androidId; // Unique ID on Android
    }
  }

  void _createRewardedAd() {
    if (goRewardedVideoId != null && iosGoRewardedVideoId != null) {
      RewardedAd.load(
          adUnitId: AdHelper.rewardAdUnitId,
          request: request,
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (RewardedAd ad) {
              print('$ad loaded.');
              _rewardedAd = ad;
              _numRewardedLoadAttempts = 0;
            },
            onAdFailedToLoad: (LoadAdError error) {
              print('RewardedAd failed to load: $error');
              _rewardedAd = null;
              _numRewardedLoadAttempts += 1;
              if (_numRewardedLoadAttempts <= maxFailedLoadAttempts) {
                _createRewardedAd();
              }
            },
          ));
    }
  }

  void _showGoogleRewardedAd() {
    if (_rewardedAd == null) {
      print('Warning: attempt to show rewarded before loaded.');
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createRewardedAd();
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(onUserEarnedReward: (_, __) {
      // print('$ad with reward $RewardItem(${reward.amount}, ${reward.type}');
    });
    _rewardedAd = null;
  }

  getUserDetails() async {
    CUR_USERID = await getPrefrence(ID) ?? "";
    setState(() {});
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

  void _createInterstitialAd() {
    if (goInterstitialId != null && iosGoInterstitialId != null) {
      InterstitialAd.load(
          adUnitId: AdHelper.interstitialAdUnitId,
          request: request,
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (InterstitialAd ad) {
              print('$ad loaded now****');
              _interstitialAd = ad;
              _numInterstitialLoadAttempts = 0;
              _interstitialAd!.setImmersiveMode(true);
            },
            onAdFailedToLoad: (LoadAdError error) {
              print('InterstitialAd failed to load: $error.');
              _numInterstitialLoadAttempts += 1;
              _interstitialAd = null;
              if (_numInterstitialLoadAttempts <= maxFailedLoadAttempts) {
                _createInterstitialAd();
              }
            },
          ));
    }
  }

  void _showGoogleInterstitialAd() {
    if (_interstitialAd == null) {
      print('Warning: attempt to show interstitial before loaded.');
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  _showInterstitialAd() {
    if (iosFbInterstitialId != "" && fbInterstitialId != "") {
      if (_isInterstitialAdLoaded == true)
        FacebookInterstitialAd.showInterstitialAd();
      else
        print("Interstial Ad not yet loaded!");
    }
  }

  void _loadInterstitialAd() {
    if (iosFbInterstitialId != "" && fbInterstitialId != "") {
      FacebookInterstitialAd.loadInterstitialAd(
        placementId: FbAdHelper.interstitialAdUnitId,
        listener: (result, value) {
          print(">> FAN > Interstitial Ad: $result --> $value");
          if (result == InterstitialAdResult.LOADED)
            _isInterstitialAdLoaded = true;

          if (result == InterstitialAdResult.DISMISSED &&
              value["invalidated"] == true) {
            _isInterstitialAdLoaded = false;
            _loadInterstitialAd();
          }
        },
      );
    }
  }

  //page slider news list data
  Widget _slider1() {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Container(
        height: height,
        width: width,
        child: PageView.builder(
            controller: pageController,
            onPageChanged: (index) async {
              setState(() {
                _curSlider = index;
              });
              _isNetworkAvail = await isNetworkAvailable();
              if (_isNetworkAvail) {
                if (index % 2 == 0) {
                  if (iosFbInterstitialId != "" && fbInterstitialId != "") {
                    _showInterstitialAd();
                  }
                }
                if (index % 3 == 0) {
                  if (goInterstitialId != null && iosGoInterstitialId != null) {
                    _showGoogleInterstitialAd();
                  }
                }
                if (index % 5 == 0) {
                  if (goRewardedVideoId != null &&
                      iosGoRewardedVideoId != null) {
                    _showGoogleRewardedAd();
                  }
                }
              }
            },
            itemCount: widget.news1!.length == 0 ? 1 : widget.news1!.length + 1,
            itemBuilder: (context, index) {
              return index == 0
                  ? NewsSubDetails(
                      model1: widget.model1,
                      index: widget.index,
                      updateParent: widget.updateParent,
                      id: widget.id,
                      isDetails: widget.isDetails,
                    )
                  : NewsSubDetails(
                      model1: widget.news1![index - 1],
                      index: index - 1,
                      updateParent: widget.updateParent,
                      id: widget.news1![index - 1].id,
                      isDetails: widget.isDetails,
                    );
            }));
  }

  //page slider news list data
  Widget _slider() {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Container(
        height: height,
        width: width,
        child: PageView.builder(
            controller: pageController,
            onPageChanged: (index) async {
              setState(() {
                _curSlider = index;
              });
              _isNetworkAvail = await isNetworkAvailable();
              if (_isNetworkAvail) {
                if (index % 2 == 0) {
                  if (goRewardedVideoId != null &&
                      iosGoRewardedVideoId != null) {
                    _showGoogleRewardedAd();
                  }
                }
                if (index % 3 == 0) {
                  if (iosFbInterstitialId != "" && fbInterstitialId != "") {
                    _showInterstitialAd();
                  }
                }
                if (index % 5 == 0) {
                  if (goInterstitialId != null && iosGoInterstitialId != null) {
                    _showGoogleInterstitialAd();
                  }
                }
              }
            },
            itemCount: widget.news!.length == 0 ? 1 : widget.news!.length + 1,
            itemBuilder: (context, index) {
              return index == 0
                  ? NewsSubDetails(
                      model: widget.model,
                      index: widget.index,
                      updateParent: widget.updateParent,
                      id: widget.id,
                      isDetails: widget.isDetails,
                    )
                  : NewsSubDetails(
                      model: widget.news![index - 1],
                      index: index - 1,
                      updateParent: widget.updateParent,
                      id: widget.news![index - 1].id,
                      isDetails: widget.isDetails,
                    );
            }));
  }

  @override
  void dispose() {
    !isDark!
        ? SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark)
        : null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Scaffold(
        backgroundColor: colors.bgColor,
        key: _scaffoldKey,
        body: !widget.isDetails! ? _slider1() : _slider());
  }
}

class NewsSubDetails extends StatefulWidget {
  final News? model;
  final int? index;
  final Function? updateParent;
  final String? id;
  final bool? isDetails;
  final BreakingNewsModel? model1;

  const NewsSubDetails(
      {Key? key,
      this.model,
      this.index,
      this.updateParent,
      this.id,
      this.isDetails,
      this.model1})
      : super(key: key);

  @override
  NewsSubDetailsState createState() => NewsSubDetailsState();
}

class NewsSubDetailsState extends State<NewsSubDetails> {
  List<String> allImage = [];
  String? profile;
  bool _isNetworkAvail = true;
  int _fontValue = 15;
  int offset = 0;
  int total = 0;
  String comTotal = "";
  bool _isLoadNews = true;
  bool _isLoadMoreNews = true;
  List<News> tempList = [];
  List<News> newsList = [];
  List<News> bookmarkList = [];
  List<Comment> commentList = [];
  bool _isLoading = true;
  bool isLoadingmore = true;
  bool _isBookmark = false;
  bool comBtnEnabled = false;
  bool replyComEnabled = false;
  TextEditingController _commentC = new TextEditingController();
  TextEditingController _replyComC = new TextEditingController();
  TextEditingController reportC = new TextEditingController();
  final _pageController = PageController();
  int _curSlider = 0;
  bool comEnabled = false;
  bool isReply = false;
  int? replyComIndex;
  FlutterTts? _flutterTts;
  bool isPlaying = false;
  bool isLikeBtnEnabled = true;
  bool isFirst = false;

  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  String? lanCode;
  int offsetNews = 0;
  int totalNews = 0;
  ScrollController controller = new ScrollController();
  ScrollController controller1 = new ScrollController();
  late BannerAd _bannerAd;

  // TODO: Add _isBannerAdReady
  bool _isBannerAdReady = false;

  // FlickManager? flickManager;
  // FlickManager? flickManager1;
  VideoPlayerController? flickManager;
  VideoPlayerController? flickManager1;
  YoutubePlayerController? _yc;

  @override
  void initState() {
    checkNet();
    if (widget.model!.contentValue != "" ||
        widget.model!.contentValue != null) {
      if (widget.model!.contentType == "video_upload") {
        // flickManager = FlickManager(
        //     videoPlayerController:
        //         VideoPlayerController.network(widget.model!.contentValue!),
        //     autoPlay: true);
        flickManager = VideoPlayerController.network(
          widget.model!.contentValue!,
        )..initialize().then((_) {
            setState(() {});
            flickManager!.play();
          });
      } else if (widget.model!.contentType == "video_youtube") {
        _yc = YoutubePlayerController(
          initialVideoId:
              YoutubePlayer.convertUrlToId(widget.model!.contentValue!)!,
          // YoutubePlayer.convertUrlToId(
          //     "https://www.youtube.com/watch?v=hS5CfP8n_js")!,
          flags: YoutubePlayerFlags(
            autoPlay: true,
          ),
        );
      } else if (widget.model!.contentType == "video_other") {
        // flickManager1 = FlickManager(
        //     videoPlayerController:
        //         VideoPlayerController.network(widget.model!.contentValue!),
        //     autoPlay: true);
        flickManager1 = VideoPlayerController.network(
          widget.model!.contentValue!,
        )..initialize().then((_) {
            setState(() {});
            flickManager1!.play();
          });
      }
    }
    getUserDetails();
    initializeTts();
    callApi();
    allImage.clear();
    if (widget.isDetails!) {
      if(widget.model!.image!.isNotEmpty){

      allImage.add(widget.model!.image!);
      }
      if (widget.model!.imageDataList!.length != 0) {
        for (int i = 0; i < widget.model!.imageDataList!.length; i++) {
           if(widget.model!.imageDataList![i].otherImage!.isNotEmpty){

          allImage.add(widget.model!.imageDataList![i].otherImage!);
      }
        }
      }
    } else {
       if(widget.model1!.image!.isNotEmpty){

      allImage.add(widget.model1!.image!);
      }
    }

    if (widget.model!.contentValue != "" ||
        widget.model!.contentValue != null) {
      if (widget.model!.contentType == "video_upload") {
        allImage.add(widget.model!.contentValue!);
      } else if (widget.model!.contentType == "video_youtube") {
        allImage.add(widget.model!.contentValue!);
        // allImage.add("https://www.youtube.com/watch?v=hS5CfP8n_js");
      } else if (widget.model!.contentType == "video_other") {
        allImage.add(widget.model!.contentValue!);
      }
      log(allImage.toString());
    }
    _createBottomBannerAd();
    controller.addListener(_scrollListener);
    controller1.addListener(_scrollListener1);
    super.initState();
  }

  callApi() async {
    _getBookmark();
    await getRelatedNews();
    await _getComment();
  }

  @override
  void dispose() {
    if (widget.model!.contentType == "video_upload") {
      flickManager!.dispose();
    } else if (widget.model!.contentType == "video_youtube") {
      _yc!.dispose();
    } else if (widget.model!.contentType == "video_other") {
      flickManager1!.dispose();
    }
    if (widget.isDetails!) {
      isPlaying = false;
      _flutterTts!.stop();
    }
    _bannerAd.dispose();
    super.dispose();
  }

  void _createBottomBannerAd() {
    if (goBannerId != "" && iosGoBannerId != "") {
      _bannerAd = BannerAd(
        adUnitId: AdHelper.bannerAdUnitId,
        request: AdRequest(),
        size: AdSize.fullBanner,
        listener: BannerAdListener(
          onAdLoaded: (_) {
            setState(() {
              _isBannerAdReady = true;
            });
          },
          onAdFailedToLoad: (ad, err) {
            _isBannerAdReady = false;
            ad.dispose();
          },
        ),
      );

      _bannerAd.load();
    }
  }

  //get prefrences
  getUserDetails() async {
    profile = await getPrefrence(PROFILE) ?? "";
    lanCode = await getPrefrence(LANGUAGE_CODE);

    getLocale().then((locale) {
      lanCode = locale.languageCode;
    });

    setState(() {});
  }

  initializeTts() {
    if (widget.isDetails!) {
      _flutterTts = FlutterTts();

      _flutterTts!.setStartHandler(() async {
        if (this.mounted)
          setState(() {
            isPlaying = true;
          });

        var max = await _flutterTts!.getMaxSpeechInputLength;
      });

      _flutterTts!.setCompletionHandler(() {
        if (this.mounted) {
          setState(() {
            isPlaying = false;
          });
        }
      });

      _flutterTts!.setErrorHandler((err) {
        if (this.mounted) {
          setState(() {
            print("error occurred: " + err);
            isPlaying = false;
          });
        }
      });
    }
  }

  _speak(String Description) async {
    if (Description != null && Description.isNotEmpty) {
      await _flutterTts!.setVolume(volume);
      await _flutterTts!.setSpeechRate(rate);
      await _flutterTts!.setPitch(pitch);
      await _flutterTts!.getLanguages;
      List<dynamic> languages = await _flutterTts!.getLanguages;
      print(languages);
      await _flutterTts!.setLanguage(() {
        if (lanCode == "en") {
          print("en-US");
          return "es-US";
        } else if (lanCode == "es") {
          print("en-ES");
          return "es-ES";
        } else if (lanCode == "hi") {
          print("hi-IN");
          return "hi-IN";
        } else if (lanCode == "tr") {
          print("tr-TR");
          return "tr-TR";
        } else if (lanCode == "pt") {
          print("pt-PT");
          return "pt-PT";
        } else {
          print("en-US");
          return "en-US";
        }
      }());
      int length = Description.length;
      if (length < 4000) {
        setState(() {
          isPlaying = true;
        });
        await _flutterTts!.speak(Description);
        _flutterTts!.setCompletionHandler(() {
          setState(() {
            _flutterTts!.stop();
            isPlaying = false;
          });
        });
      } else if (length < 8000) {
        String temp1 = Description.substring(0, length ~/ 2);
        print(temp1.length);
        await _flutterTts!.speak(temp1);
        _flutterTts!.setCompletionHandler(() {
          setState(() {
            isPlaying = true;
          });
        });

        String temp2 = Description.substring(temp1.length, Description.length);
        await _flutterTts!.speak(temp2);
        _flutterTts!.setCompletionHandler(() {
          setState(() {
            isPlaying = false;
          });
        });
      } else if (length < 12000) {
        String temp1 = Description.substring(0, 3999);
        await _flutterTts!.speak(temp1);
        _flutterTts!.setCompletionHandler(() {
          setState(() {
            isPlaying = true;
          });
        });
        String temp2 = Description.substring(temp1.length, 7999);
        await _flutterTts!.speak(temp2);
        _flutterTts!.setCompletionHandler(() {
          setState(() {});
        });
        String temp3 = Description.substring(temp2.length, Description.length);
        await _flutterTts!.speak(temp3);
        _flutterTts!.setCompletionHandler(() {
          setState(() {
            isPlaying = false;
            print("execution complete");
          });
        });
      }
    }
  }

  Future _stop() async {
    var result = await _flutterTts!.stop();
    if (result == 1)
      setState(() {
        isPlaying = false;
      });
  }

  Future _pause() async {
    var result = await _flutterTts!.pause();
    if (result == 1)
      setState(() {
        isPlaying = false;
      });
  }

  List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }

  //get comment list using api
  Future<void> _getComment() async {
    if (widget.isDetails!) {
      if (comments_mode == "1") {
        _isNetworkAvail = await isNetworkAvailable();
        if (_isNetworkAvail) {
          try {
            var param = {
              ACCESS_KEY: access_key,
              NEWS_ID: widget.model!.id,
              LIMIT: perPage.toString(),
              OFFSET: offset.toString(),
              USER_ID: CUR_USERID != null && CUR_USERID != "" ? CUR_USERID : "0"
            };
            Response response = await post(Uri.parse(getCommnetByNewsApi),
                    body: param, headers: headers)
                .timeout(Duration(seconds: timeOut));

            var getdata = json.decode(response.body);

            String error = getdata["error"];
            if (error == "false") {
              comTotal = getdata["total"];
              total = int.parse(getdata["total"]);

              if ((offset) < total) {
                var data = getdata["data"];
                commentList = (data as List)
                    .map((data) => new Comment.fromJson(data))
                    .toList();

                offset = offset + perPage;
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
            });
          }
        } else {
          setSnackbar(getTranslated(context, 'internetmsg')!);
        }
      }
    }
  }

  //set bookmark of news using api
  _setBookmark(String status) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
        USER_ID: CUR_USERID,
        NEWS_ID: widget.id,
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

          setState(() {
            _isBookmark = false;
          });
          widget.updateParent!();
        } else {
          setSnackbar(msg);
          setState(() {
            _isBookmark = true;
          });
          widget.updateParent!();
        }
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg')!);
    }
  }

  _setComLikeDislike(String status, String comId) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
        USER_ID: CUR_USERID,
        COMMENT_ID: comId,
        STATUS: status,
      };

      Response response = await post(Uri.parse(setLikeDislikeComApi),
              body: param, headers: headers)
          .timeout(Duration(seconds: timeOut));

      var getData = json.decode(response.body);

      String error = getData["error"];

      if (error == "false") {
        if (status == "1") {
          setSnackbar(com_like_msg);
        } else if (status == "2") {
          setSnackbar(com_dislike_msg);
        } else {
          setSnackbar(getTranslated(context, 'com_update_msg')!);
        }
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg')!);
    }
  }

  //get bookmark news list using api
  _getBookmark() async {
    if (widget.isDetails!) {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        if (CUR_USERID != null && CUR_USERID != "") {
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
              var data = getdata["data"];
              bookmarkList.clear();
              bookmarkList = (data as List)
                  .map((data) => new News.fromJson(data))
                  .toList();

              for (int i = 0; i < bookmarkList.length; i++) {
                if (bookmarkList[i].newsId == (widget.id)) {
                  _isBookmark = true;
                }
              }
              if (mounted)
                setState(() {
                  _isLoading = false;
                });
            }
          } on TimeoutException catch (_) {
            setSnackbar(getTranslated(context, 'somethingMSg')!);
          }
        }
      } else {
        setSnackbar(getTranslated(context, 'internetmsg')!);
      }
    }
  }

  setDeleteComment(String id, int index, int from) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
        USER_ID: CUR_USERID,
        COMMENT_ID: id,
      };
      Response response = await post(Uri.parse(setCommentDeleteApi),
              body: param, headers: headers)
          .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);
      String error = getdata["error"];

      String msg = getdata["message"];
      if (error == "false") {
        if (from == 1) {
          setState(() {
            commentList = List.from(commentList)..removeAt(index);
          });
        } else {
          setState(() {
            commentList[replyComIndex!].replyComList =
                List.from(commentList[replyComIndex!].replyComList!)
                  ..removeAt(index);
          });
        }

        setSnackbar(getTranslated(context, 'com_del_succ')!);
      } else {
        setSnackbar(msg);
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg')!);
    }
  }

  //set comment by user using api
  Future<void> _setComment(String message, String parent_id) async {
    if (comments_mode == "1") {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        var param = {
          ACCESS_KEY: access_key,
          USER_ID: CUR_USERID,
          PARENT_ID: parent_id,
          NEWS_ID: widget.id,
          MESSAGE: message,
        };
        Response response =
            await post(Uri.parse(setCommentApi), body: param, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);

        String error = getdata["error"];

        String msg = getdata["message"];

        comTotal = getdata["total"];

        if (error == "false") {
          setSnackbar(msg);
          var data = getdata["data"];
          commentList =
              (data as List).map((data) => new Comment.fromJson(data)).toList();
          setState(() {});

          if (parent_id == "0") {
            comBtnEnabled = false;
            _commentC.text = "";
          } else {
            replyComEnabled = false;
            _replyComC.text = "";
            setState(() {});
          }
        } else {
          setSnackbar(msg);
        }
      } else {
        setSnackbar(getTranslated(context, 'internetmsg')!);
      }
    }
  }

  //set comment by user using api
  Future<void> _setFlag(String message, String com_id) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
        USER_ID: CUR_USERID,
        NEWS_ID: widget.id,
        MESSAGE: message,
        COMMENT_ID: com_id
      };
      Response response =
          await post(Uri.parse(setFlagApi), body: param, headers: headers)
              .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      String error = getdata["error"];

      String msg = getdata["message"];
      if (error == "false") {
        setSnackbar(getTranslated(context, 'report_success')!);
        reportC.text = "";
        setState(() {});
      } else {
        setSnackbar(msg);
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

      var getdata = json.decode(response.body);

      String error = getdata["error"];

      String msg = getdata["message"];

      if (error == "false") {
        if (status == "1") {
          widget.model!.like = "1";
          widget.model!.totalLikes =
              (int.parse(widget.model!.totalLikes!) + 1).toString();
          setSnackbar(getTranslated(context, 'like_succ')!);
        } else if (status == "0") {
          widget.model!.like = "0";
          widget.model!.totalLikes =
              (int.parse(widget.model!.totalLikes!) - 1).toString();
          setSnackbar(getTranslated(context, 'dislike_succ')!);
        }
        setState(() {
          isFirst = false;
        });
        if (this.mounted)
          setState(() {
            _isLoading = false;
          });
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg')!);
    }
  }

  //set not comment of news text
  Widget getNoItem() {
    return Text(
      getTranslated(context, 'com_nt_avail')!,
      textAlign: TextAlign.center,
    );
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

  imageView() {
    return Container(
        height: deviceHeight! * 0.42,
        width: double.infinity,
        child: widget.isDetails!
            ? PageView.builder(
                itemCount: allImage.length,
                controller: _pageController,
                onPageChanged: (index) {
                  if (flickManager != null) {
                    flickManager!.pause();
                  } else if (flickManager1 != null) {
                    flickManager1!.pause();
                  } else if (_yc != null) {
                    _yc!.pause();
                  }
                  setState(() {
                    _curSlider = index;
                  });
                  if (allImage[index].split(".").last == "mp4" ||
                      allImage[index].contains("www.youtube")) {
                    if (widget.model!.contentType == "video_upload") {
                      flickManager!.play();
                    } else if (widget.model!.contentType == "video_other") {
                      flickManager1!.play();
                    } else {
                      _yc!.play();
                    }
                  }
                },
                itemBuilder: (BuildContext context, int index) {
                  return allImage[index].split(".").last == "mp4" ||
                          allImage[index].contains("www.youtube")
                      ? viewVideo()
                      : Hero(
                          tag: widget.model!.id!,
                          child: InkWell(
                            child: FadeInImage(
                                fadeInDuration: Duration(milliseconds: 150),
                                image:
                                    CachedNetworkImageProvider(allImage[index]),
                                fit: BoxFit.fill,
                                height: deviceHeight! * 0.42,
                                width: double.infinity,
                                imageErrorBuilder:
                                    (context, error, stackTrace) => errorWidget(
                                        deviceHeight! * 0.42, double.infinity),
                                placeholder: AssetImage(
                                  placeHolder,
                                )),
                            onTap: () {
                              Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) => ImagePreview(
                                        index: index,
                                        imgList: allImage,
                                        isNetworkAvail: _isNetworkAvail),
                                  ));
                            },
                          ),
                        );
                })
            : Hero(
                tag: widget.model1!.id!,
                child: FadeInImage(
                    fadeInDuration: Duration(milliseconds: 150),
                    image: CachedNetworkImageProvider(widget.isDetails!
                        ? widget.model!.image!
                        : widget.model1!.image!),
                    fit: BoxFit.fill,
                    height: deviceHeight! * 0.42,
                    width: double.infinity,
                    imageErrorBuilder: (context, error, stackTrace) =>
                        errorWidget(deviceHeight! * 0.42, double.infinity),
                    placeholder: AssetImage(
                      placeHolder,
                    )),
              ));
  }

  imageSliderDot() {
    return widget.isDetails!
        ? allImage.length <= 1
            ? Container()
            : Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                    margin: EdgeInsets.only(top: deviceHeight! / 2.6 - 23),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: map<Widget>(
                        allImage,
                        (index, url) {
                          return Container(
                              width: _curSlider == index ? 10.0 : 8.0,
                              height: _curSlider == index ? 10.0 : 8.0,
                              margin: EdgeInsets.symmetric(horizontal: 1.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _curSlider == index
                                    ? colors.bgColor
                                    : colors.bgColor.withOpacity((0.5)),
                              ));
                        },
                      ),
                    )))
        : Container();
  }

  backBtn() {
    return Positioned.directional(
        textDirection: Directionality.of(context),
        top: 30.0,
        start: 10.0,
        child: InkWell(
          child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 35,
                    width: 35,
                    padding: EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.transparent.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: SvgPicture.asset(
                      "assets/images/back_icon.svg",
                      semanticsLabel: 'back icon',
                    ),
                  ))),
          onTap: () {
            Navigator.pop(context);
          },
        ));
  }

  videoBtn() {
    return widget.isDetails!
        ? widget.model!.contentType == "video_upload" ||
                widget.model!.contentType == "video_youtube" ||
                widget.model!.contentType == "video_other"
            ? Positioned.directional(
                textDirection: Directionality.of(context),
                top: 30.0,
                end: 10.0,
                child: InkWell(
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            height: 35,
                            width: 35,
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.transparent.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: SvgPicture.asset(
                              "assets/images/video_icon.svg",
                              semanticsLabel: 'video icon',
                            ),
                          ))),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewsVideo(
                            model: widget.model,
                          ),
                        ));
                  },
                ))
            : Container()
        : Container();
  }

  changeFontSizeSheet() {
    showModalBottomSheet<dynamic>(
        context: context,
        elevation: 5.0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(50), topRight: Radius.circular(50))),
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (BuildContext context, setStater) {
            return Container(
                padding: EdgeInsetsDirectional.only(
                    bottom: 20.0, top: 5.0, start: 20.0, end: 20.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                        padding: EdgeInsets.only(top: 30.0, bottom: 30.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            SvgPicture.asset(
                              "assets/images/textsize_icon.svg",
                              semanticsLabel: 'textsize',
                              height: 23.0,
                              width: 23.0,
                              color: Theme.of(context).colorScheme.darkColor,
                            ),
                            Padding(
                                padding:
                                    EdgeInsetsDirectional.only(start: 15.0),
                                child: Text(
                                  getTranslated(context, 'txtSize_lbl')!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline6
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor),
                                )),
                          ],
                        )),
                    SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.red[700],
                          inactiveTrackColor: Colors.red[100],
                          trackShape: RoundedRectSliderTrackShape(),
                          trackHeight: 4.0,
                          thumbShape:
                              RoundSliderThumbShape(enabledThumbRadius: 12.0),
                          thumbColor: Colors.redAccent,
                          overlayColor: Colors.red.withAlpha(32),
                          overlayShape:
                              RoundSliderOverlayShape(overlayRadius: 28.0),
                          tickMarkShape: RoundSliderTickMarkShape(),
                          activeTickMarkColor: Colors.red[700],
                          inactiveTickMarkColor: Colors.red[100],
                          valueIndicatorShape:
                              PaddleSliderValueIndicatorShape(),
                          valueIndicatorColor: Colors.redAccent,
                          valueIndicatorTextStyle: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        child: Slider(
                          label: '${_fontValue}',
                          value: _fontValue.toDouble(),
                          activeColor: colors.primary,
                          min: 15,
                          max: 40,
                          divisions: 10,
                          onChanged: (value) {
                            setStater(() {
                              setState(() {
                                _fontValue = value.round();
                                setPrefrence(font_value, _fontValue.toString());
                              });
                            });
                          },
                        )),
                  ],
                ));
          });
        });
  }

  allRowBtn() {
    return widget.isDetails!
        ? Row(
            children: [
              InkWell(
                child: Column(
                  children: [
                    SvgPicture.asset(
                      "assets/images/comment_icon.svg",
                      semanticsLabel: 'comment',
                      height: 16.0,
                      width: 16.0,
                      color: Theme.of(context).colorScheme.darkColor,
                    ),
                    Padding(
                        padding: EdgeInsetsDirectional.only(top: 4.0),
                        child: Text(
                          getTranslated(context, 'com_lbl')!,
                          style: Theme.of(this.context)
                              .textTheme
                              .caption
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .fontColor
                                      .withOpacity(0.8),
                                  fontSize: 9.0),
                        ))
                  ],
                ),
                onTap: () {
                  setState(() {
                    comEnabled = true;
                  });
                },
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(start: 9.0),
                child: InkWell(
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        "assets/images/sharee_icon.svg",
                        semanticsLabel: 'share',
                        height: 16.0,
                        width: 16.0,
                        color: Theme.of(context).colorScheme.darkColor,
                      ),
                      Padding(
                          padding: EdgeInsetsDirectional.only(top: 4.0),
                          child: Text(
                            getTranslated(context, 'share_lbl')!,
                            style: Theme.of(this.context)
                                .textTheme
                                .caption
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor
                                        .withOpacity(0.8),
                                    fontSize: 9.0),
                          ))
                    ],
                  ),
                  onTap: () async {
                    _isNetworkAvail = await isNetworkAvailable();
                    if (_isNetworkAvail) {
                      createDynamicLink(
                        widget.model!.id!,
                        widget.index!,
                        widget.model!.title!,
                      );
                    } else {
                      setSnackbar(getTranslated(context, 'internetmsg')!);
                    }
                  },
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(start: 9.0),
                child: InkWell(
                  child: Column(
                    children: [
                      /*SvgPicture.asset(
                        _isBookmark
                            ? "assets/images/bookmarkfilled_icon.svg"
                            : "assets/images/bookmark_icon.svg",
                        semanticsLabel: 'save',
                        height: 16.0,
                        width: 16.0,
                        color: Theme.of(context).colorScheme.blackColor,
                      ),*/
                      Icon(
                        _isBookmark
                            ? Icons.bookmark_outlined
                            : Icons.bookmark_border,
                        size: 16.0,
                        color: Theme.of(context).colorScheme.darkColor,
                      ),
                      Padding(
                          padding: EdgeInsetsDirectional.only(top: 4.0),
                          child: Text(
                            getTranslated(context, 'save_lbl')!,
                            style: Theme.of(this.context)
                                .textTheme
                                .caption
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor
                                        .withOpacity(0.8),
                                    fontSize: 9.0),
                          ))
                    ],
                  ),
                  onTap: () async {
                    if (CUR_USERID != "") {
                      _isNetworkAvail = await isNetworkAvailable();
                      if (_isNetworkAvail) {
                        _isBookmark ? _setBookmark("0") : _setBookmark("1");
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
                ),
              ),
              Padding(
                  padding: EdgeInsetsDirectional.only(start: 9.0),
                  child: InkWell(
                    child: Column(
                      children: [
                        SvgPicture.asset(
                          "assets/images/textsize_icon.svg",
                          semanticsLabel: 'textsize',
                          height: 16.0,
                          width: 16.0,
                          color: Theme.of(context).colorScheme.darkColor,
                        ),
                        Padding(
                            padding: EdgeInsetsDirectional.only(top: 4.0),
                            child: Text(
                              getTranslated(context, 'txtSize_lbl')!,
                              style: Theme.of(this.context)
                                  .textTheme
                                  .caption
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.8),
                                      fontSize: 9.0),
                            ))
                      ],
                    ),
                    onTap: () {
                      changeFontSizeSheet();
                    },
                  )),
              Padding(
                  padding: EdgeInsetsDirectional.only(start: 9.0),
                  child: InkWell(
                    child: Column(
                      children: [
                        SvgPicture.asset(
                          "assets/images/speakloud_icon.svg",
                          semanticsLabel: 'speakloud',
                          height: 16.0,
                          width: 16.0,
                          color: isPlaying
                              ? colors.primary
                              : Theme.of(context).colorScheme.darkColor,
                        ),
                        Padding(
                            padding: EdgeInsetsDirectional.only(top: 4.0),
                            child: Text(
                              getTranslated(context, 'speakLoud_lbl')!,
                              style: Theme.of(this.context)
                                  .textTheme
                                  .caption
                                  ?.copyWith(
                                      color: isPlaying
                                          ? colors.primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .fontColor
                                              .withOpacity(0.8),
                                      fontSize: 9.0),
                            ))
                      ],
                    ),
                    onTap: () {
                      if (isPlaying) {
                        _stop();
                      } else {
                        final document = parse(widget.model!.desc);
                        String parsedString =
                            parse(document.body!.text).documentElement!.text;
                        _speak(parsedString);
                      }
                    },
                  )),
            ],
          )
        : Container();
  }

  dateView() {
    DateTime? time1;
    if (widget.isDetails!) {
      time1 = DateTime.parse(widget.model!.date!);
    }
    return widget.isDetails!
        ? !isReply
            ? !comEnabled
                ? Padding(
                    padding: EdgeInsetsDirectional.only(top: 8.0),
                    child: Text(
                      convertToAgo(time1!, 0)!,
                      style: Theme.of(this.context).textTheme.caption?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .fontColor
                              .withOpacity(0.8),
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600),
                    ),
                  )
                : Container()
            : Container()
        : Container();
  }

  tagView() {
    List<String> tagList = [];
    if (widget.isDetails!) {
      if (widget.model!.tagName! != "") {
        final tagName = widget.model!.tagName!;
        tagList = tagName.split(',');
      }
    }
    List<String> tagId = [];
    if (widget.isDetails!) {
      if (widget.model!.tagId! != "") {
        tagId = widget.model!.tagId!.split(",");
      }
    }
    return widget.isDetails!
        ? !isReply
            ? !comEnabled
                ? widget.model!.tagName! != ""
                    ? Padding(
                        padding: EdgeInsetsDirectional.only(top: 8.0),
                        child: SizedBox(
                            height: 20.0,
                            child: Row(
                              children: List.generate(tagList.length, (index) {
                                return Padding(
                                    padding: EdgeInsetsDirectional.only(
                                        start: index == 0 ? 0 : 7),
                                    child: InkWell(
                                      child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(3.0),
                                          child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                  sigmaX: 30, sigmaY: 30),
                                              child: Container(
                                                  height: 20.0,
                                                  width: 65,
                                                  alignment: Alignment.center,
                                                  padding: EdgeInsetsDirectional
                                                      .only(
                                                          start: 3.0,
                                                          end: 3.0,
                                                          top: 2.5,
                                                          bottom: 2.5),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3.0),
                                                    color: colors.primary
                                                        .withOpacity(0.03),
                                                  ),
                                                  child: Text(
                                                    tagList[index],
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyText2
                                                        ?.copyWith(
                                                          color: colors.primary,
                                                          fontSize: 11,
                                                        ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    softWrap: true,
                                                  )))),
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => NewsTag(
                                                tadId: tagId[index],
                                                tagName: tagList[index],
                                                updateParent: updateHomePage,
                                              ),
                                            ));
                                      },
                                    ));
                              }),
                            )))
                    : Container()
                : Container()
            : Container()
        : Container();
  }

  titleView() {
    return !isReply
        ? !comEnabled
            ? Padding(
                padding: EdgeInsetsDirectional.only(top: 6.0),
                child: Text(
                  widget.isDetails!
                      ? widget.model!.title!
                      : widget.model1!.title!,
                  style: Theme.of(this.context).textTheme.subtitle1?.copyWith(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.w600),
                ),
              )
            : Container()
        : Container();
  }

  descView() {
    return !isReply
        ? !comEnabled
            ? Padding(
                padding: EdgeInsets.only(top: 5.0),
                child: Html(
                  data: widget.isDetails!
                      ? widget.model!.desc
                      : widget.model1!.desc,
                  shrinkWrap: true,
                  style: {
                    // tables will have the below background color
                    "div": Style(
                      color: Theme.of(context)
                          .colorScheme
                          .fontColor
                          .withOpacity(0.8),
                      fontSize: FontSize((_fontValue - 3).toDouble()),
                    ),
                    "p": Style(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontSize: FontSize(_fontValue.toDouble())),
                    "b ": Style(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontSize: FontSize(_fontValue.toDouble())),
                  },
                  onLinkTap: (String? url,
                      RenderContext context,
                      Map<String, String> attributes,
                      dom.Element? element) async {
                    if (await canLaunch(url!)) {
                      await launch(
                        url,
                        forceSafariVC: false,
                        forceWebView: false,
                      );
                    } else {
                      throw 'Could not launch $url';
                    }
                  },
                ))
            : Container()
        : Container();
  }

  allDetails() {
    return Padding(
        padding: EdgeInsets.only(top: deviceHeight! / 2.6),
        child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding:
                  EdgeInsetsDirectional.only(top: 20.0, start: 20.0, end: 20.0),
              width: deviceWidth,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                  color: isDark! ? colors.darkModeColor : colors.bgColor),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    allRowBtn(),
                    dateView(),
                    tagView(),
                    titleView(),
                    descView(),
                    widget.isDetails!
                        ? !isReply
                            ? comEnabled
                                ? commentView()
                                : Container()
                            : Container()
                        : Container(),
                    widget.isDetails!
                        ? isReply
                            ? replyCommentView()
                            : Container()
                        : Container(),
                    widget.index! % 2 == 0
                        ? fbBannerId != null && iosFbBannerId != null
                            ? Container(
                                alignment: Alignment(0.5, 1),
                                padding: EdgeInsets.only(bottom: 15.0),
                                child: FacebookBannerAd(
                                  placementId: FbAdHelper.bannerAdUnitId,
                                  bannerSize: BannerSize.STANDARD,
                                  listener: (result, value) {
                                    switch (result) {
                                      case BannerAdResult.ERROR:
                                        print("Error: $value");
                                        break;
                                      case BannerAdResult.LOADED:
                                        print("Loaded: $value");
                                        break;
                                      case BannerAdResult.CLICKED:
                                        print("Clicked: $value");
                                        break;
                                      case BannerAdResult.LOGGING_IMPRESSION:
                                        print("Logging Impression: $value");
                                        break;
                                    }
                                  },
                                ))
                            : Container()
                        : goBannerId != "" && iosGoBannerId != ""
                            ? _isNetworkAvail
                                ? Padding(
                                    padding: EdgeInsets.only(bottom: 15.0),
                                    child: _isBannerAdReady
                                        ? Container(
                                            width:
                                                _bannerAd.size.width.toDouble(),
                                            height: _bannerAd.size.height
                                                .toDouble(),
                                            child: AdWidget(ad: _bannerAd))
                                        : null)
                                : Container()
                            : Container(),
                    viewRelatedContent()
                  ]),
            )));
  }

  likeBtn() {
    return widget.isDetails!
        ? Positioned.directional(
            textDirection: Directionality.of(context),
            top: deviceHeight! / 2.84,
            start: deviceWidth! * 0.73,
            child: Column(children: [
              InkWell(
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(52.0),
                    child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          height: 52,
                          width: 52,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: colors.primary.withOpacity(0.7),
                              shape: BoxShape.circle),
                          child: SvgPicture.asset(
                            widget.model!.like == "1"
                                ? "assets/images/likefilled_button.svg"
                                : "assets/images/Like_icon.svg",
                            semanticsLabel: 'like icon',
                            color: colors.tempboxColor,
                          ),
                        ))),
                onTap: () async {
                  if (CUR_USERID != "") {
                    if (_isNetworkAvail) {
                      if (!isFirst) {
                        setState(() {
                          isFirst = true;
                        });
                        if (widget.model!.like == "1") {
                          await _setLikesDisLikes("0", widget.id!);
                          setState(() {});
                        } else {
                          await _setLikesDisLikes("1", widget.id!);
                          setState(() {});
                        }
                      }
                    } else {
                      setSnackbar(getTranslated(context, 'internetmsg')!);
                    }
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Login()),
                    );
                  }
                },
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(top: 6.0),
                child: Text(
                  widget.model!.totalLikes != "0"
                      ? widget.model!.totalLikes! +
                          " " +
                          getTranslated(context, 'like_lbl')!
                      : "",
                  style: Theme.of(this.context)
                      .textTheme
                      .caption
                      ?.copyWith(color: colors.primary, fontSize: 9.0),
                ),
              )
            ]))
        : Container();
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (this.mounted) {
        setState(() {
          _isLoadMoreNews = true;

          if (offsetNews < totalNews) getRelatedNews();
        });
      }
    }
  }

  _scrollListener1() {
    if (controller1.offset >= controller1.position.maxScrollExtent &&
        !controller1.position.outOfRange) {
      if (this.mounted) {
        setState(() {
          isLoadingmore = true;

          if (offset < total) _getComment();
        });
      }
    }
  }

  newsShimmer() {
    return Shimmer.fromColors(
        baseColor: Colors.grey.withOpacity(0.6),
        highlightColor: Colors.grey,
        child: SingleChildScrollView(
          //padding: EdgeInsetsDirectional.only(start: 5.0, top: 20.0),
          scrollDirection: Axis.horizontal,
          child: Row(
              children: [0, 1, 2, 3, 4, 5, 6]
                  .map((i) => Padding(
                      padding: EdgeInsetsDirectional.only(
                          top: 15.0, start: i == 0 ? 0 : 6.0),
                      child: Stack(children: [
                        Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: Colors.grey.withOpacity(0.6)),
                          height: 240.0,
                          width: 195.0,
                        ),
                        Positioned.directional(
                            textDirection: Directionality.of(context),
                            bottom: 7.0,
                            start: 7,
                            end: 7,
                            height: 99,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: Colors.grey,
                              ),
                            )),
                      ])))
                  .toList()),
        ));
  }

  viewRelatedContent() {
    return widget.isDetails!
        ? !isReply
            ? !comEnabled
                ? _isLoadNews
                    ? Container()
                    : newsList.length != 0
                        ? Padding(
                            padding: EdgeInsetsDirectional.only(
                              top: 15.0,
                            ),
                            child: Column(children: [
                              Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                      getTranslated(context, 'related_news')!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1
                                          ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor,
                                              fontWeight: FontWeight.w600))),
                              SizedBox(
                                  height: 250,
                                  child: ListView.builder(
                                    itemCount: (offsetNews < totalNews)
                                        ? newsList.length + 1
                                        : newsList.length,
                                    scrollDirection: Axis.horizontal,
                                    controller: controller,
                                    itemBuilder: (context, index) {
                                      return (index == newsList.length &&
                                              _isLoadMoreNews)
                                          ? Center(
                                              child:
                                                  CircularProgressIndicator())
                                          : newsItem(index);
                                    },
                                  ))
                            ]))
                        : Container()
                : Container()
            : Container()
        : Container();
  }

  newsItem(int index) {
    DateTime time1 = DateTime.parse(newsList[index].date!);

    return Padding(
      padding: EdgeInsetsDirectional.only(
          top: 15.0, start: index == 0 ? 0 : 6.0, bottom: 15.0),
      child: Hero(
        tag: newsList[index].id!,
        child: InkWell(
          child: Stack(
            children: <Widget>[
              ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: FadeInImage(
                      fadeInDuration: Duration(milliseconds: 150),
                      image: CachedNetworkImageProvider(newsList[index].image!),
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
                                      newsList[index].title!,
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
                              ],
                            ),
                          )))),
            ],
          ),
          onTap: () {
            News model = newsList[index];
            List<News> recList = [];
            recList.addAll(newsList);
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
                      //updateHome: updateHome,
                    )));
          },
        ),
      ),
    );
  }

  updateHomePage() {
    setState(() {
      bookmarkList.clear();
      _getBookmark();
    });
  }

  Future<void> getRelatedNews() async {
    if (widget.isDetails!) {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          var param = {
            ACCESS_KEY: access_key,
            LIMIT: perPage.toString(),
            OFFSET: offsetNews.toString(),
            USER_ID: CUR_USERID != "" ? CUR_USERID : "0",
          };

          if (widget.model!.subCat_id != "0") {
            param[SUBCAT_ID] = widget.model!.subCat_id!;
          } else {
            param[CATEGORY_ID] = widget.model!.categoryId!;
          }

          Response response = await post(Uri.parse(getNewsByCatApi),
                  body: param, headers: headers)
              .timeout(Duration(seconds: timeOut));
          if (response.statusCode == 200) {
            var getData = json.decode(response.body);

            String error = getData["error"];
            if (error == "false") {
              totalNews = int.parse(getData["total"]);
              if ((offsetNews) < totalNews) {
                tempList.clear();
                var data = getData["data"];
                tempList = (data as List)
                    .map((data) => new News.fromJson(data))
                    .toList();
                newsList.addAll(tempList);
                newsList.removeWhere((element) => element.id == widget.id);

                offsetNews = offsetNews + perPage;
              }
            } else {
              if (this.mounted)
                setState(() {
                  _isLoadMoreNews = false;
                });
            }
            if (this.mounted)
              setState(() {
                _isLoadNews = false;
              });
          }
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!);
          setState(() {
            _isLoadNews = false;
            _isLoadMoreNews = false;
          });
        }
      } else {
        setSnackbar(getTranslated(context, 'internetmsg')!);
        setState(() {
          _isLoadNews = false;
          _isLoadMoreNews = false;
        });
      }
    }
  }

  checkNet() async {
    _isNetworkAvail = await isNetworkAvailable();
  }

  viewVideo() {
    return Container(
      height: deviceHeight! * 0.42,
      width: double.infinity,
      color: Colors.black,
      child: widget.model!.contentType == "video_upload"
          ? Container(
              alignment: Alignment.center,
              // child: FlickVideoPlayer(flickManager: flickManager!))
              child: VideoPlayer(flickManager!))
          : widget.model!.contentType == "video_youtube"
              ? YoutubePlayerBuilder(
                  player: YoutubePlayer(
                    controller: _yc!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: colors.primary,
                  ),
                  builder: (context, player) {
                    return Center(child: player);
                  })
              : widget.model!.contentType == "video_other"
                  ? Container(
                      alignment: Alignment.center,
                      // child: FlickVideoPlayer(flickManager: flickManager1!))
                      child: VideoPlayer(flickManager1!))
                  : Container(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: deviceWidth,
        child: SingleChildScrollView(
            child: Stack(children: <Widget>[
          imageView(),
          imageSliderDot(),
          backBtn(),
          // videoBtn(),
          allDetails(),
          likeBtn(),
        ])));
  }

  allCommentView() {
    return Row(
      children: [
        commentList.length != 0
            ? Text(
                getTranslated(context, 'all_lbl')! +
                    "\t" +
                    commentList.length.toString() +
                    "\t" +
                    getTranslated(context, 'coms_lbl')!,
                style: Theme.of(this.context).textTheme.caption?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .fontColor
                        .withOpacity(0.6),
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600),
              )
            : Container(),
        Spacer(),
        Align(
            alignment: Alignment.topRight,
            child: InkWell(
              child: SvgPicture.asset(
                "assets/images/close_icon.svg",
                semanticsLabel: 'close icon',
                height: 23,
                width: 23,
                color: Theme.of(context).colorScheme.darkColor,
              ),
              onTap: () {
                setState(() {
                  comEnabled = false;
                });
              },
            ))
      ],
    );
  }

  profileWithSendCom() {
    return Padding(
        padding: EdgeInsetsDirectional.only(top: 5.0),
        child: Row(
          children: [
            Expanded(
                flex: 1,
                child: profile != null && profile != ""
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(profile!),
                      )
                    : Container(
                        height: 35,
                        width: 35,
                        child: Icon(
                          Icons.account_circle,
                          color: colors.primary,
                          size: 35,
                        ),
                      )),
            Expanded(
                flex: 7,
                child: Padding(
                    padding: EdgeInsetsDirectional.only(start: 18.0),
                    child: TextField(
                      controller: _commentC,
                      style: Theme.of(context).textTheme.subtitle2?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .fontColor
                              .withOpacity(0.7)),
                      onChanged: (String val) {
                        if (_commentC.text.trim().isNotEmpty) {
                          setState(() {
                            comBtnEnabled = true;
                          });
                        } else {
                          setState(() {
                            comBtnEnabled = false;
                          });
                        }
                      },
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: InputDecoration(
                          contentPadding:
                              EdgeInsets.only(top: 10.0, bottom: 2.0),
                          isDense: true,
                          suffixIconConstraints: BoxConstraints(
                            maxHeight: 35,
                            maxWidth: 30,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .fontColor
                                    .withOpacity(0.5),
                                width: 1.5),
                          ),
                          hintText: getTranslated(context, 'share_thoght_lbl')!,
                          hintStyle: Theme.of(context)
                              .textTheme
                              .subtitle2
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .fontColor
                                      .withOpacity(0.7)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.send,
                              color: comBtnEnabled
                                  ? Theme.of(context)
                                      .colorScheme
                                      .fontColor
                                      .withOpacity(0.8)
                                  : Colors.transparent,
                              size: 20.0,
                            ),
                            onPressed: () async {
                              if (CUR_USERID != "") {
                                setState(() {
                                  _setComment(_commentC.text, "0");
                                  FocusScopeNode currentFocus =
                                      FocusScope.of(context);

                                  if (!currentFocus.hasPrimaryFocus) {
                                    currentFocus.unfocus();
                                  }
                                });
                              } else {
                                setSnackbar(
                                    getTranslated(context, 'login_req_msg')!);
                              }
                            },
                          )),
                    )))
          ],
        ));
  }

  allComListView() {
    return Padding(
        padding: EdgeInsets.only(top: 20.0),
        child: SingleChildScrollView(
            child: ListView.separated(
                separatorBuilder: (BuildContext context, int index) => Divider(
                      color: Theme.of(context)
                          .colorScheme
                          .fontColor
                          .withOpacity(0.5),
                    ),
                shrinkWrap: true,
                padding: EdgeInsets.only(top: 20.0),
                controller: controller1,
                physics: NeverScrollableScrollPhysics(),
                itemCount: commentList.length,
                itemBuilder: (context, index) {
                  DateTime time1 = DateTime.parse(commentList[index].date!);

                  return (index == commentList.length && isLoadingmore)
                      ? Center(child: CircularProgressIndicator())
                      : InkWell(
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                commentList[index].profile != null ||
                                        commentList[index].profile != ""
                                    ? Container(
                                        height: 40,
                                        width: 40,
                                        child: CircleAvatar(
                                          backgroundImage: NetworkImage(
                                              commentList[index].profile!),
                                          radius: 32,
                                        ))
                                    : Container(
                                        height: 35,
                                        width: 35,
                                        child: Icon(
                                          Icons.account_circle,
                                          color: colors.primary,
                                          size: 35,
                                        ),
                                      ),
                                Expanded(
                                    child: Padding(
                                        padding: EdgeInsetsDirectional.only(
                                            start: 15.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(commentList[index].name!,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyText2
                                                        ?.copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .fontColor
                                                                .withOpacity(
                                                                    0.7),
                                                            fontSize: 13)),
                                                Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .only(start: 10.0),
                                                    child: Icon(
                                                      Icons.circle,
                                                      size: 4.0,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .fontColor
                                                          .withOpacity(0.7),
                                                    )),
                                                Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .only(start: 10.0),
                                                    child: Text(
                                                      convertToAgo(time1, 1)!,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .caption
                                                          ?.copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .fontColor
                                                                  .withOpacity(
                                                                      0.7),
                                                              fontSize: 10),
                                                    )),
                                              ],
                                            ),
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(top: 8.0),
                                              child: Text(
                                                commentList[index].message!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .subtitle2
                                                    ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .darkColor,
                                                        fontWeight:
                                                            FontWeight.normal),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(top: 15.0),
                                              child: Row(
                                                children: [
                                                  InkWell(
                                                      child: SvgPicture.asset(
                                                        "assets/images/likecomment_icon.svg",
                                                        semanticsLabel:
                                                            'likecomment',
                                                        height: 13.0,
                                                        width: 13.0,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .darkColor,
                                                      ),
                                                      onTap: () {
                                                        if (CUR_USERID != "") {
                                                          if (_isNetworkAvail) {
                                                            if (commentList[
                                                                        index]
                                                                    .like ==
                                                                "1") {
                                                              _setComLikeDislike(
                                                                "0",
                                                                commentList[
                                                                        index]
                                                                    .id!,
                                                              );
                                                              commentList[index]
                                                                  .like = "0";

                                                              commentList[index]
                                                                      .totalLikes =
                                                                  (int.parse(commentList[index]
                                                                              .totalLikes!) -
                                                                          1)
                                                                      .toString();

                                                              setState(() {});
                                                            } else if (commentList[
                                                                        index]
                                                                    .dislike ==
                                                                "1") {
                                                              _setComLikeDislike(
                                                                "1",
                                                                commentList[
                                                                        index]
                                                                    .id!,
                                                              );
                                                              commentList[index]
                                                                      .dislike =
                                                                  "0";

                                                              commentList[index]
                                                                      .totalDislikes =
                                                                  (int.parse(commentList[index]
                                                                              .totalDislikes!) -
                                                                          1)
                                                                      .toString();

                                                              commentList[index]
                                                                  .like = "1";
                                                              commentList[index]
                                                                      .totalLikes =
                                                                  (int.parse(commentList[index]
                                                                              .totalLikes!) +
                                                                          1)
                                                                      .toString();
                                                              setState(() {});
                                                            } else {
                                                              _setComLikeDislike(
                                                                "1",
                                                                commentList[
                                                                        index]
                                                                    .id!,
                                                              );
                                                              commentList[index]
                                                                  .like = "1";
                                                              commentList[index]
                                                                      .totalLikes =
                                                                  (int.parse(commentList[index]
                                                                              .totalLikes!) +
                                                                          1)
                                                                      .toString();
                                                              setState(() {});
                                                            }
                                                          } else {
                                                            setSnackbar(
                                                                getTranslated(
                                                                    context,
                                                                    'internetmsg')!);
                                                          }
                                                        } else {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        Login()),
                                                          );
                                                        }
                                                      }),
                                                  commentList[index]
                                                              .totalLikes! !=
                                                          "0"
                                                      ? Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .only(
                                                                      start:
                                                                          4.0),
                                                          child: Text(
                                                            commentList[index]
                                                                .totalLikes!,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .subtitle2
                                                                ?.copyWith(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .darkColor),
                                                          ),
                                                        )
                                                      : Container(
                                                          width: 12,
                                                        ),
                                                  Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .only(start: 35),
                                                      child: InkWell(
                                                        child: SvgPicture.asset(
                                                          "assets/images/dislikecomment_icon.svg",
                                                          semanticsLabel:
                                                              'dislikecomment',
                                                          height: 13.0,
                                                          width: 13.0,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .darkColor,
                                                        ),
                                                        onTap: () {
                                                          if (CUR_USERID !=
                                                              "") {
                                                            if (_isNetworkAvail) {
                                                              if (commentList[
                                                                          index]
                                                                      .dislike ==
                                                                  "1") {
                                                                _setComLikeDislike(
                                                                  "0",
                                                                  commentList[
                                                                          index]
                                                                      .id!,
                                                                );
                                                                commentList[
                                                                        index]
                                                                    .dislike = "0";

                                                                commentList[
                                                                        index]
                                                                    .totalDislikes = (int.parse(
                                                                            commentList[index].totalDislikes!) -
                                                                        1)
                                                                    .toString();

                                                                setState(() {});
                                                              } else if (commentList[
                                                                          index]
                                                                      .like ==
                                                                  "1") {
                                                                _setComLikeDislike(
                                                                  "2",
                                                                  commentList[
                                                                          index]
                                                                      .id!,
                                                                );
                                                                commentList[
                                                                        index]
                                                                    .like = "0";

                                                                commentList[
                                                                        index]
                                                                    .totalLikes = (int.parse(
                                                                            commentList[index].totalLikes!) -
                                                                        1)
                                                                    .toString();

                                                                commentList[
                                                                        index]
                                                                    .dislike = "1";
                                                                commentList[
                                                                        index]
                                                                    .totalDislikes = (int.parse(
                                                                            commentList[index].totalDislikes!) +
                                                                        1)
                                                                    .toString();
                                                                setState(() {});
                                                              } else {
                                                                _setComLikeDislike(
                                                                  "2",
                                                                  commentList[
                                                                          index]
                                                                      .id!,
                                                                );
                                                                commentList[
                                                                        index]
                                                                    .dislike = "1";
                                                                commentList[
                                                                        index]
                                                                    .totalDislikes = (int.parse(
                                                                            commentList[index].totalDislikes!) +
                                                                        1)
                                                                    .toString();
                                                                setState(() {});
                                                              }
                                                            } else {
                                                              setSnackbar(
                                                                  getTranslated(
                                                                      context,
                                                                      'internetmsg')!);
                                                            }
                                                          } else {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          Login()),
                                                            );
                                                          }
                                                        },
                                                      )),
                                                  commentList[index]
                                                              .totalDislikes! !=
                                                          "0"
                                                      ? Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .only(
                                                                      start:
                                                                          4.0),
                                                          child: Text(
                                                            commentList[index]
                                                                .totalDislikes!,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .subtitle2
                                                                ?.copyWith(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .darkColor),
                                                          ),
                                                        )
                                                      : Container(
                                                          width: 12,
                                                        ),
                                                  Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .only(start: 35),
                                                      child: InkWell(
                                                        child: SvgPicture.asset(
                                                          "assets/images/replycomment_icon.svg",
                                                          semanticsLabel:
                                                              'replycomment',
                                                          height: 13.0,
                                                          width: 13.0,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .darkColor,
                                                        ),
                                                      )),
                                                  commentList[index]
                                                              .replyComList!
                                                              .length !=
                                                          0
                                                      ? Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .only(
                                                                      start:
                                                                          5.0),
                                                          child: Text(
                                                            commentList[index]
                                                                .replyComList!
                                                                .length
                                                                .toString(),
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .subtitle2
                                                                ?.copyWith(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .darkColor),
                                                          ),
                                                        )
                                                      : Container(),
                                                  Spacer(),
                                                  CUR_USERID != ""
                                                      ? InkWell(
                                                          child: Icon(
                                                            Icons
                                                                .more_vert_outlined,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .darkColor,
                                                            size: 17,
                                                          ),
                                                          onTap: () {
                                                            delAndReportCom(
                                                              commentList[index]
                                                                  .id!,
                                                              index,
                                                            );
                                                          },
                                                        )
                                                      : Container()
                                                ],
                                              ),
                                            ),
                                            Padding(
                                                padding:
                                                    EdgeInsets.only(top: 10.0),
                                                child: InkWell(
                                                  child: Text(
                                                    commentList[index]
                                                                .replyComList!
                                                                .length !=
                                                            0
                                                        ? commentList[index]
                                                                .replyComList!
                                                                .length
                                                                .toString() +
                                                            "\t" +
                                                            getTranslated(
                                                                context,
                                                                'reply_lbl')!
                                                        : "",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .caption
                                                        ?.copyWith(
                                                            color:
                                                                colors.primary,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                  ),
                                                  onTap: () {
                                                    setState(() {
                                                      isReply = true;
                                                      replyComIndex = index;
                                                    });
                                                  },
                                                )),
                                          ],
                                        ))),
                              ]),
                          onTap: () {
                            setState(() {
                              isReply = true;
                              replyComIndex = index;
                            });
                          },
                        );
                })));
  }

  commentView() {
    return comments_mode == "1"
        ? Padding(
            padding: EdgeInsetsDirectional.only(top: 10.0, bottom: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                allCommentView(),
                profileWithSendCom(),
                allComListView()
              ],
            ))
        : Column(children: [
            Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  child: SvgPicture.asset(
                    "assets/images/close_icon.svg",
                    semanticsLabel: 'close icon',
                    height: 23,
                    width: 23,
                    color: Theme.of(context).colorScheme.darkColor,
                  ),
                  onTap: () {
                    setState(() {
                      comEnabled = false;
                    });
                  },
                )),
            Container(
                padding: EdgeInsetsDirectional.only(top: kToolbarHeight),
                child: Text(getTranslated(context, 'com_disable')!))
          ]);
  }

  delAndReportCom(String comId, int index) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
              contentPadding: const EdgeInsets.all(20),
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15.0))),
              content: SingleChildScrollView(
                  //padding: EdgeInsets.all(15.0),
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CUR_USERID == commentList[index].userId!
                      ? Row(
                          children: <Widget>[
                            Text(
                              getTranslated(context, 'delete_txt')!,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.9),
                                      fontWeight: FontWeight.bold),
                            ),
                            Spacer(),
                            InkWell(
                              child: Image.asset(
                                "assets/images/delete_icon.png",
                                color: Theme.of(context).colorScheme.fontColor,
                                height: 20,
                                width: 20,
                              ),
                              onTap: () async {
                                if (CUR_USERID != "") {
                                  setDeleteComment(comId, index, 1);
                                  Navigator.pop(context);
                                } else {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Login()),
                                  );
                                }
                              },
                            ),
                          ],
                        )
                      : Container(),
                  CUR_USERID != commentList[index].userId!
                      ? Padding(
                          padding: EdgeInsets.only(top: 15),
                          child: Row(
                            children: <Widget>[
                              Text(
                                getTranslated(context, 'report_txt')!,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor
                                            .withOpacity(0.9),
                                        fontWeight: FontWeight.bold),
                              ),
                              Spacer(),
                              Image.asset(
                                "assets/images/flag_icon.png",
                                color: Theme.of(context).colorScheme.fontColor,
                                height: 20,
                                width: 20,
                              ),
                            ],
                          ))
                      : Container(),
                  CUR_USERID != commentList[index].userId!
                      ? Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: TextField(
                            controller: reportC,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            style:
                                Theme.of(context).textTheme.caption?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.7),
                                    ),
                            decoration: new InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    width: 0.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    width: 0.5),
                              ),
                            ),
                          ))
                      : Container(),
                  CUR_USERID != commentList[index].userId!
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  getTranslated(context, 'cancel_btn')!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor
                                              .withOpacity(0.9),
                                          fontWeight: FontWeight.bold),
                                )),
                            TextButton(
                                onPressed: () {
                                  if (CUR_USERID != "") {
                                    if (reportC.text.trim().isNotEmpty) {
                                      _setFlag(reportC.text, comId);
                                      Navigator.pop(context);
                                    } else {
                                      setSnackbar(getTranslated(
                                          context, 'first_fill_data')!);
                                    }
                                  } else {
                                    Navigator.pop(context);
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => Login()),
                                    );
                                  }
                                },
                                child: Text(
                                  getTranslated(context, 'submit_btn')!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor
                                              .withOpacity(0.9),
                                          fontWeight: FontWeight.bold),
                                )),
                          ],
                        )
                      : Container(),
                ],
              )));
        });
  }

  delAndReportCom1(String comId, int index) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
              contentPadding: const EdgeInsets.all(20),
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15.0))),
              content: SingleChildScrollView(
                  //padding: EdgeInsets.all(15.0),
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CUR_USERID ==
                          commentList[replyComIndex!]
                              .replyComList![index]
                              .userId
                      ? Row(
                          children: <Widget>[
                            Text(
                              getTranslated(context, 'delete_txt')!,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.9),
                                      fontWeight: FontWeight.bold),
                            ),
                            Spacer(),
                            InkWell(
                              child: Image.asset(
                                "assets/images/delete_icon.png",
                                color: Theme.of(context).colorScheme.fontColor,
                                height: 20,
                                width: 20,
                              ),
                              onTap: () async {
                                if (CUR_USERID != "") {
                                  setDeleteComment(comId, index, 2);
                                  Navigator.pop(context);
                                } else {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Login()),
                                  );
                                }
                              },
                            ),
                          ],
                        )
                      : Container(),
                  CUR_USERID !=
                          commentList[replyComIndex!]
                              .replyComList![index]
                              .userId
                      ? Padding(
                          padding: EdgeInsets.only(top: 15),
                          child: Row(
                            children: <Widget>[
                              Text(
                                getTranslated(context, 'report_txt')!,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor
                                            .withOpacity(0.9),
                                        fontWeight: FontWeight.bold),
                              ),
                              Spacer(),
                              Image.asset(
                                "assets/images/flag_icon.png",
                                color: Theme.of(context).colorScheme.fontColor,
                                height: 20,
                                width: 20,
                              ),
                            ],
                          ))
                      : Container(),
                  CUR_USERID !=
                          commentList[replyComIndex!]
                              .replyComList![index]
                              .userId
                      ? Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: TextField(
                            controller: reportC,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            style:
                                Theme.of(context).textTheme.caption?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.7),
                                    ),
                            decoration: new InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    width: 0.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    width: 0.5),
                              ),
                            ),
                          ))
                      : Container(),
                  CUR_USERID !=
                          commentList[replyComIndex!]
                              .replyComList![index]
                              .userId
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  getTranslated(context, 'cancel_btn')!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor
                                              .withOpacity(0.9),
                                          fontWeight: FontWeight.bold),
                                )),
                            TextButton(
                                onPressed: () {
                                  if (CUR_USERID != "") {
                                    if (reportC.text.trim().isNotEmpty) {
                                      _setFlag(reportC.text, comId);
                                      Navigator.pop(context);
                                    } else {
                                      setSnackbar(getTranslated(
                                          context, 'first_fill_data')!);
                                    }
                                  } else {
                                    Navigator.pop(context);
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => Login()),
                                    );
                                  }
                                },
                                child: Text(
                                  getTranslated(context, 'submit_btn')!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor
                                              .withOpacity(0.9),
                                          fontWeight: FontWeight.bold),
                                )),
                          ],
                        )
                      : Container()
                ],
              )));
        });
  }

  allReplyComView() {
    return Row(
      children: [
        Text(
          getTranslated(context, 'all_lbl')! +
              "\t" +
              commentList[replyComIndex!].replyComList!.length.toString() +
              "\t" +
              getTranslated(context, 'reply_lbl')!,
          style: Theme.of(this.context).textTheme.caption?.copyWith(
              color: Theme.of(context).colorScheme.fontColor.withOpacity(0.6),
              fontSize: 12.0,
              fontWeight: FontWeight.w600),
        ),
        Spacer(),
        Align(
            alignment: Alignment.topRight,
            child: InkWell(
              child: SvgPicture.asset(
                "assets/images/close_icon.svg",
                semanticsLabel: 'close icon',
                height: 23,
                width: 23,
                color: Theme.of(context).colorScheme.darkColor,
              ),
              onTap: () {
                setState(() {
                  isReply = false;
                });
              },
            ))
      ],
    );
  }

  replyComProfileWithCom() {
    DateTime time1 = DateTime.parse(commentList[replyComIndex!].date!);
    return Padding(
        padding: EdgeInsets.only(top: 10),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              commentList[replyComIndex!].profile != null ||
                      commentList[replyComIndex!].profile != ""
                  ? Container(
                      height: 40,
                      width: 40,
                      child: CircleAvatar(
                        backgroundImage:
                            NetworkImage(commentList[replyComIndex!].profile!),
                        radius: 32,
                      ))
                  : Container(
                      height: 35,
                      width: 35,
                      child: Icon(
                        Icons.account_circle,
                        color: colors.primary,
                        size: 35,
                      ),
                    ),
              Expanded(
                  child: Padding(
                      padding: EdgeInsetsDirectional.only(start: 15.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(commentList[replyComIndex!].name!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyText2
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor
                                              .withOpacity(0.7),
                                          fontSize: 13)),
                              Padding(
                                  padding:
                                      EdgeInsetsDirectional.only(start: 10.0),
                                  child: Icon(
                                    Icons.circle,
                                    size: 4.0,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor
                                        .withOpacity(0.7),
                                  )),
                              Padding(
                                  padding:
                                      EdgeInsetsDirectional.only(start: 10.0),
                                  child: Text(
                                    convertToAgo(time1, 1)!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .caption
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor
                                                .withOpacity(0.7),
                                            fontSize: 10),
                                  )),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              commentList[replyComIndex!].message!,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle2
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                      fontWeight: FontWeight.normal),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 15.0),
                            child: Row(
                              children: [
                                InkWell(
                                  child: SvgPicture.asset(
                                    "assets/images/likecomment_icon.svg",
                                    semanticsLabel: 'likecomment',
                                    height: 13.0,
                                    width: 13.0,
                                    color:
                                        Theme.of(context).colorScheme.darkColor,
                                  ),
                                  onTap: () {
                                    if (CUR_USERID != "") {
                                      if (_isNetworkAvail) {
                                        if (commentList[replyComIndex!].like ==
                                            "1") {
                                          _setComLikeDislike(
                                            "0",
                                            commentList[replyComIndex!].id!,
                                          );
                                          commentList[replyComIndex!].like =
                                              "0";

                                          commentList[replyComIndex!]
                                              .totalLikes = (int.parse(
                                                      commentList[
                                                              replyComIndex!]
                                                          .totalLikes!) -
                                                  1)
                                              .toString();

                                          setState(() {});
                                        } else if (commentList[replyComIndex!]
                                                .dislike ==
                                            "1") {
                                          _setComLikeDislike(
                                            "1",
                                            commentList[replyComIndex!].id!,
                                          );
                                          commentList[replyComIndex!].dislike =
                                              "0";

                                          commentList[replyComIndex!]
                                              .totalDislikes = (int.parse(
                                                      commentList[
                                                              replyComIndex!]
                                                          .totalDislikes!) -
                                                  1)
                                              .toString();

                                          commentList[replyComIndex!].like =
                                              "1";
                                          commentList[replyComIndex!]
                                              .totalLikes = (int.parse(
                                                      commentList[
                                                              replyComIndex!]
                                                          .totalLikes!) +
                                                  1)
                                              .toString();
                                          setState(() {});
                                        } else {
                                          _setComLikeDislike(
                                            "1",
                                            commentList[replyComIndex!].id!,
                                          );
                                          commentList[replyComIndex!].like =
                                              "1";
                                          commentList[replyComIndex!]
                                              .totalLikes = (int.parse(
                                                      commentList[
                                                              replyComIndex!]
                                                          .totalLikes!) +
                                                  1)
                                              .toString();
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
                                            builder: (context) => Login()),
                                      );
                                    }
                                  },
                                ),
                                commentList[replyComIndex!].totalLikes! != "0"
                                    ? Padding(
                                        padding: EdgeInsetsDirectional.only(
                                            start: 4.0),
                                        child: Text(
                                          commentList[replyComIndex!]
                                              .totalLikes!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .darkColor,
                                              ),
                                        ),
                                      )
                                    : Container(
                                        width: 12,
                                      ),
                                Padding(
                                    padding:
                                        EdgeInsetsDirectional.only(start: 35),
                                    child: InkWell(
                                      child: SvgPicture.asset(
                                        "assets/images/dislikecomment_icon.svg",
                                        semanticsLabel: 'dislikecomment',
                                        height: 13.0,
                                        width: 13.0,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .darkColor,
                                      ),
                                      onTap: () {
                                        if (CUR_USERID != "") {
                                          if (_isNetworkAvail) {
                                            if (commentList[replyComIndex!]
                                                    .dislike ==
                                                "1") {
                                              _setComLikeDislike(
                                                "0",
                                                commentList[replyComIndex!].id!,
                                              );
                                              commentList[replyComIndex!]
                                                  .dislike = "0";

                                              commentList[replyComIndex!]
                                                  .totalDislikes = (int.parse(
                                                          commentList[
                                                                  replyComIndex!]
                                                              .totalDislikes!) -
                                                      1)
                                                  .toString();

                                              setState(() {});
                                            } else if (commentList[
                                                        replyComIndex!]
                                                    .like ==
                                                "1") {
                                              _setComLikeDislike(
                                                "2",
                                                commentList[replyComIndex!].id!,
                                              );
                                              commentList[replyComIndex!].like =
                                                  "0";

                                              commentList[replyComIndex!]
                                                  .totalLikes = (int.parse(
                                                          commentList[
                                                                  replyComIndex!]
                                                              .totalLikes!) -
                                                      1)
                                                  .toString();

                                              commentList[replyComIndex!]
                                                  .dislike = "1";
                                              commentList[replyComIndex!]
                                                  .totalDislikes = (int.parse(
                                                          commentList[
                                                                  replyComIndex!]
                                                              .totalDislikes!) +
                                                      1)
                                                  .toString();
                                              setState(() {});
                                            } else {
                                              _setComLikeDislike(
                                                "2",
                                                commentList[replyComIndex!].id!,
                                              );
                                              commentList[replyComIndex!]
                                                  .dislike = "1";
                                              commentList[replyComIndex!]
                                                  .totalDislikes = (int.parse(
                                                          commentList[
                                                                  replyComIndex!]
                                                              .totalDislikes!) +
                                                      1)
                                                  .toString();
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
                                                builder: (context) => Login()),
                                          );
                                        }
                                      },
                                    )),
                                commentList[replyComIndex!].totalDislikes! !=
                                        "0"
                                    ? Padding(
                                        padding: EdgeInsetsDirectional.only(
                                            start: 4.0),
                                        child: Text(
                                          commentList[replyComIndex!]
                                              .totalDislikes!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .darkColor,
                                              ),
                                        ),
                                      )
                                    : Container(
                                        width: 12,
                                      ),
                                Padding(
                                    padding:
                                        EdgeInsetsDirectional.only(start: 35),
                                    child: InkWell(
                                      child: SvgPicture.asset(
                                        "assets/images/replycomment_icon.svg",
                                        semanticsLabel: 'replycomment',
                                        height: 13.0,
                                        width: 13.0,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .darkColor,
                                      ),
                                    )),
                                commentList[replyComIndex!]
                                            .replyComList!
                                            .length !=
                                        0
                                    ? Padding(
                                        padding: EdgeInsetsDirectional.only(
                                            start: 5.0),
                                        child: Text(
                                          commentList[replyComIndex!]
                                              .replyComList!
                                              .length
                                              .toString(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .darkColor,
                                              ),
                                        ),
                                      )
                                    : Container(),
                                Spacer(),
                                CUR_USERID != ""
                                    ? InkWell(
                                        child: Icon(
                                          Icons.more_vert_outlined,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .darkColor,
                                          size: 17,
                                        ),
                                        onTap: () {
                                          delAndReportCom(
                                            commentList[replyComIndex!].id!,
                                            replyComIndex!,
                                          );
                                        },
                                      )
                                    : Container()
                              ],
                            ),
                          ),
                        ],
                      ))),
            ]));
  }

  replyComSendReplyView() {
    return CUR_USERID != ""
        ? Padding(
            padding: EdgeInsetsDirectional.only(top: 10.0),
            child: Row(
              children: [
                Expanded(
                    flex: 1,
                    child: profile != null && profile != ""
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(profile!),
                          )
                        : Container(
                            height: 35,
                            width: 35,
                            child: Icon(
                              Icons.account_circle,
                              color: colors.primary,
                              size: 35,
                            ),
                          )),
                Expanded(
                    flex: 7,
                    child: Padding(
                        padding: EdgeInsetsDirectional.only(start: 18.0),
                        child: TextField(
                          controller: _replyComC,
                          style: Theme.of(context)
                              .textTheme
                              .subtitle2
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .fontColor
                                      .withOpacity(0.7)),
                          onChanged: (String val) {
                            if (_replyComC.text.trim().isNotEmpty) {
                              setState(() {
                                replyComEnabled = true;
                              });
                            } else {
                              setState(() {
                                replyComEnabled = false;
                              });
                            }
                          },
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          decoration: InputDecoration(
                              contentPadding:
                                  EdgeInsets.only(top: 10.0, bottom: 2.0),
                              isDense: true,
                              suffixIconConstraints: BoxConstraints(
                                maxHeight: 35,
                                maxWidth: 30,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor
                                        .withOpacity(0.5),
                                    width: 1.5),
                              ),
                              hintText: getTranslated(context, 'public_reply')!,
                              hintStyle: Theme.of(context)
                                  .textTheme
                                  .subtitle2
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.7)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  Icons.send,
                                  color: replyComEnabled
                                      ? Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.8)
                                      : Colors.transparent,
                                  size: 20.0,
                                ),
                                onPressed: () async {
                                  if (CUR_USERID != "") {
                                    setState(() {
                                      _setComment(_replyComC.text,
                                          commentList[replyComIndex!].id!);
                                      FocusScopeNode currentFocus =
                                          FocusScope.of(context);

                                      if (!currentFocus.hasPrimaryFocus) {
                                        currentFocus.unfocus();
                                      }
                                    });
                                  } else {
                                    setSnackbar(getTranslated(
                                        context, 'login_req_msg')!);
                                  }
                                },
                              )),
                        )))
              ],
            ))
        : Container();
  }

  replyAllComListView() {
    return Padding(
        padding: EdgeInsets.only(top: 20.0),
        child: SingleChildScrollView(
            child: ListView.separated(
                separatorBuilder: (BuildContext context, int index) => Divider(
                      color: Theme.of(context)
                          .colorScheme
                          .fontColor
                          .withOpacity(0.5),
                    ),
                shrinkWrap: true,
                reverse: true,
                padding: EdgeInsets.only(top: 20.0),
                physics: NeverScrollableScrollPhysics(),
                itemCount: commentList[replyComIndex!].replyComList!.length,
                itemBuilder: (context, index) {
                  DateTime time1 = DateTime.parse(
                      commentList[replyComIndex!].replyComList![index].date!);
                  return Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        commentList[replyComIndex!]
                                        .replyComList![index]
                                        .profile !=
                                    null ||
                                commentList[replyComIndex!]
                                        .replyComList![index]
                                        .profile !=
                                    ""
                            ? Container(
                                height: 40,
                                width: 40,
                                child: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                      commentList[replyComIndex!]
                                          .replyComList![index]
                                          .profile!),
                                  radius: 32,
                                ))
                            : Container(
                                height: 35,
                                width: 35,
                                child: Icon(
                                  Icons.account_circle,
                                  color: colors.primary,
                                  size: 35,
                                ),
                              ),
                        Expanded(
                            child: Padding(
                                padding:
                                    EdgeInsetsDirectional.only(start: 15.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                            commentList[replyComIndex!]
                                                .replyComList![index]
                                                .name!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText2
                                                ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .fontColor
                                                        .withOpacity(0.7),
                                                    fontSize: 13)),
                                        Padding(
                                            padding: EdgeInsetsDirectional.only(
                                                start: 10.0),
                                            child: Icon(
                                              Icons.circle,
                                              size: 4.0,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor
                                                  .withOpacity(0.7),
                                            )),
                                        Padding(
                                            padding: EdgeInsetsDirectional.only(
                                                start: 10.0),
                                            child: Text(
                                              convertToAgo(time1, 1)!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .caption
                                                  ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .fontColor
                                                          .withOpacity(0.7),
                                                      fontSize: 10),
                                            )),
                                      ],
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        commentList[replyComIndex!]
                                            .replyComList![index]
                                            .message!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle2
                                            ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .fontColor,
                                                fontWeight: FontWeight.normal),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: 15.0),
                                      child: Row(
                                        children: [
                                          InkWell(
                                            child: SvgPicture.asset(
                                              "assets/images/likecomment_icon.svg",
                                              semanticsLabel: 'likecomment',
                                              height: 13.0,
                                              width: 13.0,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .darkColor,
                                            ),
                                            onTap: () {
                                              if (CUR_USERID != "") {
                                                if (_isNetworkAvail) {
                                                  if (commentList[
                                                              replyComIndex!]
                                                          .replyComList![index]
                                                          .like ==
                                                      "1") {
                                                    _setComLikeDislike(
                                                      "0",
                                                      commentList[
                                                              replyComIndex!]
                                                          .replyComList![index]
                                                          .id!,
                                                    );
                                                    commentList[replyComIndex!]
                                                        .replyComList![index]
                                                        .like = "0";

                                                    commentList[replyComIndex!]
                                                        .replyComList![index]
                                                        .totalLikes = (int.parse(
                                                                commentList[
                                                                        replyComIndex!]
                                                                    .replyComList![
                                                                        index]
                                                                    .totalLikes!) -
                                                            1)
                                                        .toString();

                                                    setState(() {});
                                                  } else if (commentList[
                                                              replyComIndex!]
                                                          .replyComList![index]
                                                          .dislike ==
                                                      "1") {
                                                    _setComLikeDislike(
                                                      "1",
                                                      commentList[
                                                              replyComIndex!]
                                                          .replyComList![index]
                                                          .id!,
                                                    );
                                                    commentList[replyComIndex!]
                                                        .replyComList![index]
                                                        .dislike = "0";

                                                    commentList[replyComIndex!]
                                                            .replyComList![index]
                                                            .totalDislikes =
                                                        (int.parse(commentList[
                                                                        replyComIndex!]
                                                                    .replyComList![
                                                                        index]
                                                                    .totalDislikes!) -
                                                                1)
                                                            .toString();

                                                    commentList[replyComIndex!]
                                                        .replyComList![index]
                                                        .like = "1";
                                                    commentList[replyComIndex!]
                                                        .replyComList![index]
                                                        .totalLikes = (int.parse(
                                                                commentList[
                                                                        replyComIndex!]
                                                                    .replyComList![
                                                                        index]
                                                                    .totalLikes!) +
                                                            1)
                                                        .toString();
                                                    setState(() {});
                                                  } else {
                                                    _setComLikeDislike(
                                                      "1",
                                                      commentList[
                                                              replyComIndex!]
                                                          .replyComList![index]
                                                          .id!,
                                                    );
                                                    commentList[replyComIndex!]
                                                        .replyComList![index]
                                                        .like = "1";
                                                    commentList[replyComIndex!]
                                                        .replyComList![index]
                                                        .totalLikes = (int.parse(
                                                                commentList[
                                                                        replyComIndex!]
                                                                    .replyComList![
                                                                        index]
                                                                    .totalLikes!) +
                                                            1)
                                                        .toString();
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
                                                      builder: (context) =>
                                                          Login()),
                                                );
                                              }
                                            },
                                          ),
                                          commentList[replyComIndex!]
                                                      .replyComList![index]
                                                      .totalLikes! !=
                                                  "0"
                                              ? Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .only(start: 4.0),
                                                  child: Text(
                                                    commentList[replyComIndex!]
                                                        .replyComList![index]
                                                        .totalLikes!,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .subtitle2
                                                        ?.copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .darkColor,
                                                        ),
                                                  ),
                                                )
                                              : Container(
                                                  width: 12,
                                                ),
                                          Padding(
                                              padding:
                                                  EdgeInsetsDirectional.only(
                                                      start: 35),
                                              child: InkWell(
                                                child: SvgPicture.asset(
                                                  "assets/images/dislikecomment_icon.svg",
                                                  semanticsLabel:
                                                      'dislikecomment',
                                                  height: 13.0,
                                                  width: 13.0,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .darkColor,
                                                ),
                                                onTap: () {
                                                  if (CUR_USERID != "") {
                                                    if (_isNetworkAvail) {
                                                      if (commentList[
                                                                  replyComIndex!]
                                                              .replyComList![
                                                                  index]
                                                              .dislike ==
                                                          "1") {
                                                        _setComLikeDislike(
                                                          "0",
                                                          commentList[
                                                                  replyComIndex!]
                                                              .replyComList![
                                                                  index]
                                                              .id!,
                                                        );
                                                        commentList[
                                                                replyComIndex!]
                                                            .replyComList![
                                                                index]
                                                            .dislike = "0";

                                                        commentList[replyComIndex!]
                                                                .replyComList![
                                                                    index]
                                                                .totalDislikes =
                                                            (int.parse(commentList[
                                                                            replyComIndex!]
                                                                        .replyComList![
                                                                            index]
                                                                        .totalDislikes!) -
                                                                    1)
                                                                .toString();

                                                        setState(() {});
                                                      } else if (commentList[
                                                                  replyComIndex!]
                                                              .replyComList![
                                                                  index]
                                                              .like ==
                                                          "1") {
                                                        _setComLikeDislike(
                                                          "2",
                                                          commentList[
                                                                  replyComIndex!]
                                                              .replyComList![
                                                                  index]
                                                              .id!,
                                                        );
                                                        commentList[
                                                                replyComIndex!]
                                                            .replyComList![
                                                                index]
                                                            .like = "0";

                                                        commentList[
                                                                replyComIndex!]
                                                            .replyComList![
                                                                index]
                                                            .totalLikes = (int.parse(commentList[
                                                                        replyComIndex!]
                                                                    .replyComList![
                                                                        index]
                                                                    .totalLikes!) -
                                                                1)
                                                            .toString();

                                                        commentList[
                                                                replyComIndex!]
                                                            .replyComList![
                                                                index]
                                                            .dislike = "1";
                                                        commentList[replyComIndex!]
                                                                .replyComList![
                                                                    index]
                                                                .totalDislikes =
                                                            (int.parse(commentList[
                                                                            replyComIndex!]
                                                                        .replyComList![
                                                                            index]
                                                                        .totalDislikes!) +
                                                                    1)
                                                                .toString();
                                                        setState(() {});
                                                      } else {
                                                        _setComLikeDislike(
                                                          "2",
                                                          commentList[
                                                                  replyComIndex!]
                                                              .replyComList![
                                                                  index]
                                                              .id!,
                                                        );
                                                        commentList[
                                                                replyComIndex!]
                                                            .replyComList![
                                                                index]
                                                            .dislike = "1";
                                                        commentList[replyComIndex!]
                                                                .replyComList![
                                                                    index]
                                                                .totalDislikes =
                                                            (int.parse(commentList[
                                                                            replyComIndex!]
                                                                        .replyComList![
                                                                            index]
                                                                        .totalDislikes!) +
                                                                    1)
                                                                .toString();
                                                        setState(() {});
                                                      }
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
                                                              Login()),
                                                    );
                                                  }
                                                },
                                              )),
                                          commentList[replyComIndex!]
                                                      .replyComList![index]
                                                      .totalDislikes! !=
                                                  "0"
                                              ? Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .only(start: 4.0),
                                                  child: Text(
                                                    commentList[replyComIndex!]
                                                        .replyComList![index]
                                                        .totalDislikes!,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .subtitle2
                                                        ?.copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .darkColor,
                                                        ),
                                                  ),
                                                )
                                              : Container(),
                                          Spacer(),
                                          CUR_USERID != ""
                                              ? InkWell(
                                                  child: Icon(
                                                    Icons.more_vert_outlined,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .darkColor,
                                                    size: 17,
                                                  ),
                                                  onTap: () {
                                                    delAndReportCom1(
                                                      commentList[
                                                              replyComIndex!]
                                                          .replyComList![index]
                                                          .id!,
                                                      index,
                                                    );
                                                  },
                                                )
                                              : Container()
                                        ],
                                      ),
                                    ),
                                  ],
                                ))),
                      ]);
                })));
  }

  replyCommentView() {
    return Padding(
        padding: EdgeInsetsDirectional.only(top: 10.0, bottom: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            allReplyComView(),
            replyComProfileWithCom(),
            replyComSendReplyView(),
            replyAllComListView(),
          ],
        ));
  }
}
