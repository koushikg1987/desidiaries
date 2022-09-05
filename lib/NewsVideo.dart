
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart' as intl;
import 'package:news/Helper/Session.dart';
import 'package:news/Helper/Color.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'Model/News.dart';

class NewsVideo extends StatefulWidget {
  News? model;

  NewsVideo({Key? key, this.model}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StateVideo();
}

class StateVideo extends State<NewsVideo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  FlickManager? flickManager;
  FlickManager? flickManager1;
  YoutubePlayerController? _yc;
  bool _isNetworkAvail = true;

  @override
  void initState() {
    super.initState();
    checkNet();
    if (widget.model!.contentValue != "" ||
        widget.model!.contentValue != null) {
      if (widget.model!.contentType == "video_upload") {
        flickManager = FlickManager(
            videoPlayerController:
                VideoPlayerController.network(widget.model!.contentValue!),
            autoPlay: false);
      } else if (widget.model!.contentType == "video_youtube") {
        _yc = YoutubePlayerController(
          initialVideoId:
              // YoutubePlayer.convertUrlToId(widget.model!.contentValue!)!,
              YoutubePlayer.convertUrlToId("https://www.youtube.com/watch?v=hS5CfP8n_js")!,
          flags: YoutubePlayerFlags(
            autoPlay: false,
          ),
        );
      } else if (widget.model!.contentType == "video_other") {
        flickManager1 = FlickManager(
            videoPlayerController:
                VideoPlayerController.network(widget.model!.contentValue!),
            autoPlay: false);
      }
    }
  }

  checkNet() async {
    _isNetworkAvail = await isNetworkAvailable();
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.model!.contentType == "video_upload") {
      flickManager!.dispose();
    } else if (widget.model!.contentType == "video_youtube") {
      _yc!.dispose();
    } else if (widget.model!.contentType == "video_other") {
      flickManager1!.dispose();
    }
  }

  //news video link set
  viewVideo() {
    return widget.model!.contentType == "video_upload"
        ? Container(
            alignment: Alignment.center,
            child: FlickVideoPlayer(flickManager: flickManager!))
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
                    child: FlickVideoPlayer(flickManager: flickManager1!))
                : Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        body: Stack(children: <Widget>[
          Padding(
            padding: EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
            child: _isNetworkAvail
                ? Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0)),
                    child: viewVideo())
                : Center(child: Text(getTranslated(context, 'internetmsg')!)),
          ),
          Padding(
              padding: const EdgeInsetsDirectional.only(top: 30.0, start: 10.0),
              child: Container(
                  height: 30,
                  width: 30,
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
                  ))),
        ]));
  }
}
