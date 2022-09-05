import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart';
import 'package:news/appBarTitle.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Helper/Color.dart';
import 'Helper/Constant.dart';
import 'Helper/Session.dart';
import 'Helper/String.dart';
import 'Login.dart';
import 'package:html/dom.dart' as dom;

class PrivacyPolicy extends StatefulWidget {
  final String? title;
  final String? from;

  const PrivacyPolicy({Key? key, this.title, this.from}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StatePrivacy();
  }
}

class StatePrivacy extends State<PrivacyPolicy> with TickerProviderStateMixin {
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  String? privacy;
  String url = "";
  bool _isNetworkAvail = true;

  @override
  void initState() {
    super.initState();
    getSetting();
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
            widget.title!,
            style: Theme.of(context).textTheme.headline6?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5),
          ),
          leading: Builder(builder: (BuildContext context) {
            return Padding(
                padding: EdgeInsetsDirectional.only(
                    start: 15.0, top: 6.0, bottom: 6.0),
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
    return _isLoading
        ? Scaffold(
            key: _scaffoldKey,
            // appBar: getAppBar(),
            appBar: PreferredSize(
          preferredSize: Size(double.infinity, 45),
          child: AppBar(
            leadingWidth: 50,
            elevation: 0.0,
            centerTitle: true,
            backgroundColor: Colors.transparent,
             actions: [
                Container(
                  width: 50,
                )
              ],
            title: appBarTitle(title: widget.title?? "Desi Diaries"),
            leading: Builder(builder: (BuildContext context) {
              return Padding(
                  padding: EdgeInsetsDirectional.only(
                      start: 15.0, top: 6.0, bottom: 6.0),
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
          )),
            body: Container(
              alignment: Alignment.center,
              child: showCircularProgress(_isLoading, colors.primary),
            ))
        : Scaffold(
            key: _scaffoldKey,
            appBar:  PreferredSize(
          preferredSize: Size(double.infinity, 45),
          child: AppBar(
            leadingWidth: 50,
            elevation: 0.0,
            centerTitle: true,
             actions: [
                Container(
                  width: 50,
                )
              ],
            backgroundColor: Colors.transparent,
            title: appBarTitle(title: widget.title?? "Desi Diaries"),
            leading: Builder(builder: (BuildContext context) {
              return Padding(
                  padding: EdgeInsetsDirectional.only(
                      start: 15.0, top: 6.0, bottom: 6.0),
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
          )),
            body: SingleChildScrollView(
                padding: EdgeInsetsDirectional.only(
                    // start: 15.0, end: 15.0, top: 5.0),
                    start: 15.0, end: 15.0, top: 15.0),
                child:
                  Html(
                    data: privacy!,
                    style: {
                      "p": Style(
                          color: Theme.of(context).colorScheme.darkColor,
                          fontSize: FontSize(16)),
                      "b ": Style(
                          color: Theme.of(context).colorScheme.darkColor,
                          fontSize: FontSize(19)),
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
                  ),
                 ));
  }

  //get setting api in fetch privacy data
  Future<void> getSetting() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
      };
      Response response =
          await post(Uri.parse(getSettingApi), body: param, headers: headers)
              .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      String error = getdata["error"];
      if (error == "false") {
        if (widget.title == getTranslated(context, 'privacy_policy')!)
          privacy = getdata["data"][PRIVACY_POLICY].toString();
        else if (widget.title == getTranslated(context, 'term_cond')!)
          privacy = getdata["data"][TERMS_CONDITIONS].toString();
        else if (widget.title == getTranslated(context, 'about_us')!)
          privacy = getdata["data"][ABOUT_US].toString();
        else if (widget.title == getTranslated(context, 'contact_us')!)
          privacy = getdata["data"][CONTACT_US].toString();
      }
      setState(() {
        _isLoading = false;
      });
    } else {
      setSnackbar(getTranslated(context, 'internetmsg')!);
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
}
