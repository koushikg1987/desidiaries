import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:news/Helper/Color.dart';
import 'package:news/Helper/Constant.dart';
import 'package:news/Helper/Session.dart';
import 'package:news/Login.dart';
import 'package:news/ManagePref.dart';
import 'package:news/Model/News.dart';
import 'package:news/appBarTitle.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

import 'Helper/String.dart';
import 'Helper/Theme.dart';
import 'Privacy.dart';
import 'main.dart';

class Setting extends StatefulWidget {
  @override
  SettingState createState() => SettingState();
}

class SettingState extends State<Setting> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  String profile = "";
  String cover = "";

  String mobile = "";
  String? type, name, email;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  File? image;
  bool _isNetworkAvail = true;
  TextEditingController? nameC, monoC, emailC = TextEditingController();
  bool isEditName = false;
  bool isEditMono = false;
  bool isEditEmail = false;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final GlobalKey<FormState> _formkey1 = GlobalKey<FormState>();
  final GlobalKey<FormState> _formkey2 = GlobalKey<FormState>();
  ThemeNotifier? themeNotifier;
  String? theme;
  int? selectedIndex;
  List<String> languageList = [eng_lbl, span_lbl, hin_lbl, turk_lbl, port_lbl];
  List<News> bookmarkList = [];

  List<String> langCode = ["en", "es", "hi", "tr", "pt"];

  int? selectLan;
  final InAppReview _inAppReview = InAppReview.instance;
  FocusNode _bioFocusNode = FocusNode();
  TextEditingController _bioTextEditingConroller = TextEditingController();
  @override
  void initState() {
    _bioFocusNode.unfocus();
    _bioTextEditingConroller.text=   prefs!.getString(BIO)??""; 
    getUserDetails();
    _getBookmark();

    super.initState();
  }

  @override
  void dispose() {
    nameC!.dispose();
    super.dispose();
  }

  _getSavedTheme() async {
    theme = await getPrefrence(APP_THEME);
    if (theme == SYSTEM) {
      selectedIndex = 0;
    } else if (theme == LIGHT) {
      selectedIndex = 1;
    } else {
      selectedIndex = 2;
    }
    setState(() {});
  }

  _updateState(int position) {
    setState(() {
      selectedIndex = position;
    });
    onThemeChanged(position);
  }

  Future<void> getUserDetails() async {
    CUR_USERID = (await getPrefrence(ID)) ?? "";
    CUR_USERNAME = (await getPrefrence(NAME)) ?? "";
    CUR_USEREMAIL = (await getPrefrence(EMAIL)) ?? "";
    profile = await getPrefrence(PROFILE) ?? "";
    cover = await getPrefrence(COVER) ?? "";

    mobile = await getPrefrence(MOBILE) ?? "";
    type = await getPrefrence(TYPE);

    nameC = TextEditingController(text: CUR_USERNAME);
    monoC = TextEditingController(text: mobile);
    emailC = TextEditingController(text: CUR_USEREMAIL);
    getLocale().then((locale) {
      selectLan = langCode.indexOf(locale.languageCode);
    });

    notiEnable = await getPrefrenceBool(NOTIENABLE);

    setState(() {});
  }

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

            if (mounted)
              setState(() {
                _isLoading = false;
              });
          } else {
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, "/home");
        return true;
      },
      child: Scaffold(
        backgroundColor: colors.bgColor,

        key: _scaffoldKey,
        appBar: PreferredSize(
            preferredSize: Size(double.infinity, 45),
            child: AppBar(
              leadingWidth: 50,
              elevation: 0.0, actions: [
                Container(
                  width: 50,
                )
              ],
              centerTitle: true,
              backgroundColor: Colors.transparent,
              title: appBarTitle(),
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
                            Navigator.pushReplacementNamed(context, "/home");

                            // Navigator.of(context).pop();
                          },
                          child: SvgPicture.asset(
                            "assets/images/back_icon.svg",
                            semanticsLabel: 'back icon',
                            color: Theme.of(context).colorScheme.fontColor,
                          ),
                        )));
              }),
            )),
        // appBar: PreferredSize(
        //     preferredSize: Size(double.infinity, 35),
        //     child: Stack(
        //       alignment: Alignment.center,
        //       children: [
        //         appBarTitle(),
        //         Positioned(
        //                 left: deviceWidth! * 0.05,
        //                 top: 35,
        //                 child: Center(
        //                   child:  InkWell(
        //     child: ClipRRect(
        //         borderRadius: BorderRadius.circular(10.0),
        //         child: BackdropFilter(
        //             filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        //             child: Container(
        //               height: 35,
        //               width: 35,
        //               padding: EdgeInsets.all(9),
        //               decoration: BoxDecoration(
        //                 color: Colors.transparent.withOpacity(0.3),
        //                 borderRadius: BorderRadius.circular(10.0),
        //               ),
        //               child: SvgPicture.asset(
        //                 "assets/images/back_icon.svg",
        //                 semanticsLabel: 'back icon',
        //               ),
        //             ))),
        //     onTap: () {
        //       Navigator.pop(context);
        //     },
        //   )
        //                 ))

        //       ],
        //     )),
        body: Stack(
          children: <Widget>[
            _showContent(),
            showCircularProgress(_isLoading, colors.primary)
          ],
        ),
      ),
    );
  }

  //show header and drawer data shown
  _showContent() {
    return SingleChildScrollView(
        padding: EdgeInsetsDirectional.only(
            // start: 15.0, end: 15.0, top: 45.0, bottom: 10.0),
            start: 15.0,
            end: 15.0,
            top: 15.0,
            bottom: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // setHeader(),
            setHeader2(),

            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextField(
                    autofocus: false,
                    maxLines: 10,
                    minLines: 10,
                    controller: _bioTextEditingConroller,
                    focusNode: _bioFocusNode,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 10.0),
                        hintText: "Bio",
                        hintStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .darkColor
                                .withOpacity(0.5)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.boxColor),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.boxColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                        ),
                        fillColor: colors.bgColor),
                    // onChanged: (query) => updateSearchQuery(query),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 30.0),
                    child: InkWell(
                        child: Container(
                          height: 45.0,
                          width: 190.0,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: colors.primary,
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(10.0)),
                          child: Text(
                            "Update Bio",
                            style: Theme.of(this.context)
                                .textTheme
                                .headline6
                                ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.boxColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 21),
                          ),
                        ),
                        onTap: () async {
                          updateBio();
                        }),
                  ),
                ],
              ),
            ),

            // bookbarkView(),
            setBottomContent(),
            //signOutBtn(),
          ],
        ));
  }

  void _changeLan(String language) async {
    Locale _locale = await setLocale(language);

    MyApp.setLocale(context, _locale);
  }

  List<Widget> getLngList() {
    return languageList
        .asMap()
        .map(
          (index, element) => MapEntry(
              index,
              InkWell(
                onTap: () {
                  setState(() {
                    selectLan = index;
                    _changeLan(langCode[index]);
                  });
                },
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 5),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 25.0,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selectLan == index
                                    ? colors.primary
                                    : colors.tempboxColor,
                                border: Border.all(color: colors.primary)),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: selectLan == index
                                  ? Icon(
                                      Icons.check,
                                      size: 17.0,
                                      color: colors.tempboxColor,
                                    )
                                  : Icon(
                                      Icons.check_box_outline_blank,
                                      size: 15.0,
                                      color: colors.tempboxColor,
                                    ),
                            ),
                          ),
                          Padding(
                              padding: EdgeInsets.only(
                                left: 15.0,
                              ),
                              child: Text(
                                languageList[index],
                                style: Theme.of(this.context)
                                    .textTheme
                                    .subtitle1
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor),
                              ))
                        ],
                      ),
                      Divider(),
                    ],
                  ),
                ),
              )),
        )
        .values
        .toList();
  }

  //user profile upload function
  void _showPicker2() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)), //this end here
            child: Container(
                height: 130,
                width: 80,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: 50.0, end: 50.0, top: 10.0, bottom: 10.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                            icon: Icon(
                              Icons.photo_library,
                              color: Theme.of(context)
                                  .colorScheme
                                  .fontColor
                                  .withOpacity(0.7),
                            ),
                            label: Text(
                              getTranslated(context, 'photo_lib_lbl')!,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .fontColor
                                      .withOpacity(0.7),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              _getFromGallery2();
                              Navigator.of(context).pop();
                            }),
                        TextButton.icon(
                          icon: Icon(
                            Icons.photo_camera,
                            color: Theme.of(context)
                                .colorScheme
                                .fontColor
                                .withOpacity(0.7),
                          ),
                          label: Text(
                            getTranslated(context, 'camera_lbl')!,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .fontColor
                                    .withOpacity(0.7),
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            _getFromCamera2();
                            Navigator.of(context).pop();
                          },
                        )
                      ]),
                )));
      },
    );
  }

  //set image camera
  _getFromCamera2() async {
    XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile.path);
      });

      setProfilePic2(image!);
    }
  }

  //set profile using api
  Future<void> setProfilePic2(File _image) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      setState(() {
        _isLoading = true;
      });
      try {
        var request = MultipartRequest('POST', Uri.parse(setProfileApi2));
        request.headers.addAll(headers);
        request.fields[USER_ID] = CUR_USERID;
        request.fields[ACCESS_KEY] = access_key;
        var pic = await MultipartFile.fromPath(IMAGE, _image.path);
        request.files.add(pic);

        var response = await request.send();

        log(response.request!.url.toString());
        log(response.request!.headers.toString());
        log(request.fields.toString());
        var responseData = await response.stream.toBytes();

        var responseString = String.fromCharCodes(responseData);
        if (response.statusCode == 200) {
          var getdata = json.decode(responseString);
          log(getdata.toString());

          String error = getdata["error"];
          String msg = getdata['message'];
          cover = getdata['file_path'];
          if (error == "false") {
            setSnackbar(getTranslated(context, 'profile_success')!);
            setState(() {
              setPrefrence(COVER, cover);
            });
            String? img1 = await getPrefrence(COVER);
          } else {
            setSnackbar(msg);
          }
          setState(() {
            _isLoading = false;
          });
        } else {
          return null;
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  //set profile using api
  Future<void> updateBio() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      setState(() {
        _isLoading = true;
      });
      try {
        var request = MultipartRequest('POST', Uri.parse(update_bio));
        request.headers.addAll(headers);
        request.fields[USER_ID] = CUR_USERID;
        request.fields[ACCESS_KEY] = access_key;
        request.fields["bio"] = _bioTextEditingConroller.text;

        var response = await request.send();

        log(response.request!.url.toString());
        log(response.request!.headers.toString());
        log(request.fields.toString());
        var responseData = await response.stream.toBytes();

        var responseString = String.fromCharCodes(responseData);
        if (response.statusCode == 200) {
          var getdata = json.decode(responseString);
          log(getdata.toString());

          String error = getdata["error"];
          String msg = getdata['message'];
          if (error == "false") {
            setSnackbar(msg);
            setState(() {
              setPrefrence(BIO, _bioTextEditingConroller.text);
            });
          } else {
            setSnackbar(msg);
          }
          setState(() {
            _isLoading = false;
          });
        } else {
          return null;
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

// set image gallery
  _getFromGallery2() async {
    XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile.path);
      });
      setProfilePic2(image!);
    }
  }

  setHeader2() {
    var brightness =
        SchedulerBinding.instance.window.platformBrightness == Brightness.dark;
    double width = MediaQuery.of(context).size.width;
    return Container(
      height: deviceHeight! * 0.3,
      width: deviceWidth!,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 0,
            child: Container(
              height: deviceHeight! * 0.23,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: cover == ""
                      ? Container(
                          width: width-50,
                        
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: colors.primary),
                        )
                      : Image.network(
                          cover,
                          width: width-50,
                          
                          fit: BoxFit.cover,
                        )),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              height: deviceWidth! * 0.36,
              width: deviceWidth! * 0.36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: deviceWidth! * 0.3,
                    width: deviceWidth! * 0.3,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1000),
                        border: Border.all(color: Colors.white, width: 3)),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(10000),
                        child: profile == ""
                            ? Container(
                                width: width,
                                // decoration: BoxDecoration(
                                //     borderRadius: BorderRadius.circular(20),
                                //     color: colors.primary),
                                child: SvgPicture.asset(
                                  "assets/images/user_icon.svg",
                                  semanticsLabel: 'user icon',
                                  color: Colors.black,
                                  width: width,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.network(
                                profile,
                                width: width,
                                fit: BoxFit.cover,
                              )),
                  ),
                  Positioned(
                    right: deviceWidth! * 0.025,
                    bottom: deviceWidth! * 0.05,
                    child: GestureDetector(
                      onTap: () {
                        _showPicker();
                      },
                      child: Container(
                        width: deviceWidth! * 0.08,
                        height: deviceWidth! * 0.08,
                        decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(1000)),
                        child: Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          Positioned.directional(
              textDirection: Directionality.of(context),
              end: 13,
              top: 10,
              height: 35,
              width: 35,
              child: InkWell(
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(35.0),
                    child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: EdgeInsets.all(5.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(35.0),
                            color: colors.tempboxColor.withOpacity(0.7),
                          ),
                          child: Icon(
                            Icons.add_circle_outline,
                            color: colors.darkColor1,
                            size: 22,
                          ),
                        ))),
                onTap: () {
                  _showPicker2();
                },
              )),
        ],
      ),
    );

    CUR_USERID != ""
        ? Stack(children: <Widget>[
            ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: profile == ""
                    ? Container(
                        height: 340.0,
                        width: width,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: colors.primary),
                      )
                    : Image.network(
                        profile,
                        height: 340.0,
                        width: width,
                        fit: BoxFit.cover,
                      )),
            Positioned.directional(
              textDirection: Directionality.of(context),
              bottom: 10.0,
              start: 10,
              end: 10,
              height: CUR_USEREMAIL != ""
                  ? 130
                  : CUR_USERNAME != ""
                      ? 130
                      : 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.all(15.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: colors.tempboxColor.withOpacity(0.7),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        CUR_USERNAME != ""
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Container(
                                      height: 20,
                                      width: 20,
                                      child: SvgPicture.asset(
                                        "assets/images/user_icon.svg",
                                        semanticsLabel: 'user icon',
                                      )),
                                  Padding(
                                      padding: EdgeInsetsDirectional.only(
                                          start: 20.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text(
                                              getTranslated(
                                                  context, 'name_lbl')!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .subtitle2
                                                  ?.copyWith(
                                                    color: colors.tempdarkColor,
                                                  )),
                                          Form(
                                              key: _formkey,
                                              child: Container(
                                                  width: deviceWidth! / 1.7,
                                                  child: TextFormField(
                                                    //enabled: isEdit ? false : true,
                                                    readOnly: isEditName
                                                        ? false
                                                        : true,
                                                    onSaved: (newValue) {
                                                      setState(() {
                                                        name = newValue;
                                                      });
                                                    },
                                                    validator: (val) =>
                                                        nameValidation(
                                                            val!, context),
                                                    decoration:
                                                        new InputDecoration(
                                                      border: InputBorder.none,
                                                      focusedBorder:
                                                          InputBorder.none,
                                                      enabledBorder:
                                                          InputBorder.none,
                                                      errorBorder:
                                                          InputBorder.none,
                                                      disabledBorder:
                                                          InputBorder.none,
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.all(0),
                                                    ),
                                                    controller: nameC,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .subtitle1
                                                        ?.copyWith(
                                                          color: colors
                                                              .tempdarkColor,
                                                        ),
                                                  ))),
                                        ],
                                      )),
                                  Spacer(),
                                  !isEditName
                                      ? InkWell(
                                          child: SvgPicture.asset(
                                              "assets/images/edit_icon.svg",
                                              semanticsLabel: 'edit icon',
                                              height: 16,
                                              width: 16,
                                              color: colors.darkColor1),
                                          onTap: () {
                                            setState(() {
                                              isEditName = true;
                                            });
                                          },
                                        )
                                      : InkWell(
                                          child: Icon(Icons.check_box,
                                              size: 20,
                                              color: colors.darkColor1),
                                          onTap: () {
                                            final form = _formkey.currentState;
                                            if (form!.validate()) {
                                              form.save();
                                              setState(() {
                                                name = nameC!.text;
                                              });
                                              _setUpdateProfile(name!, "", "");
                                            }
                                          },
                                        ),
                                ],
                              )
                            : Container(),
                        mobile != ""
                            ? Padding(
                                padding: EdgeInsets.only(top: 7.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Container(
                                        height: 20,
                                        width: 20,
                                        child: SvgPicture.asset(
                                          "assets/images/mobile_icon.svg",
                                          semanticsLabel: 'mobile',
                                        )),
                                    Padding(
                                        padding: EdgeInsetsDirectional.only(
                                            start: 20.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Text(
                                                getTranslated(
                                                    context, 'mobile_lbl')!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .subtitle2
                                                    ?.copyWith(
                                                      color:
                                                          colors.tempdarkColor,
                                                    )),
                                            Form(
                                                key: _formkey1,
                                                child: Container(
                                                    width: deviceWidth! / 1.7,
                                                    child: TextFormField(
                                                      //enabled: isEdit ? false : true,
                                                      readOnly: isEditMono
                                                          ? false
                                                          : true,
                                                      onSaved: (newValue) {
                                                        setState(() {
                                                          mobile = newValue!;
                                                        });
                                                      },
                                                      validator: (val) =>
                                                          mobValidation(
                                                              val!, context),
                                                      decoration:
                                                          new InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        focusedBorder:
                                                            InputBorder.none,
                                                        enabledBorder:
                                                            InputBorder.none,
                                                        errorBorder:
                                                            InputBorder.none,
                                                        disabledBorder:
                                                            InputBorder.none,
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets.all(0),
                                                      ),
                                                      controller: monoC,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .subtitle1
                                                          ?.copyWith(
                                                            color: colors
                                                                .tempdarkColor,
                                                          ),
                                                    ))),
                                          ],
                                        )),
                                    Spacer(),
                                    type != login_mbl
                                        ? !isEditMono
                                            ? InkWell(
                                                child: SvgPicture.asset(
                                                  "assets/images/edit_icon.svg",
                                                  semanticsLabel: 'edit icon',
                                                  height: 16,
                                                  width: 16,
                                                  color: colors.darkColor1,
                                                ),
                                                onTap: () {
                                                  setState(() {
                                                    isEditMono = true;
                                                  });
                                                },
                                              )
                                            : InkWell(
                                                child: Icon(
                                                  Icons.check_box,
                                                  size: 20,
                                                  color: colors.darkColor1,
                                                ),
                                                onTap: () {
                                                  final form =
                                                      _formkey1.currentState;
                                                  if (form!.validate()) {
                                                    form.save();
                                                    setState(() {
                                                      mobile = monoC!.text;
                                                    });
                                                    _setUpdateProfile(
                                                        "", mobile, "");
                                                  }
                                                },
                                              )
                                        : Container(),
                                  ],
                                ))
                            : Container(),
                        CUR_USEREMAIL != ""
                            ? Padding(
                                padding: EdgeInsets.only(top: 7.0),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Container(
                                          height: 20,
                                          width: 20,
                                          child: SvgPicture.asset(
                                            "assets/images/email_icon.svg",
                                            semanticsLabel: 'email',
                                          )),
                                      Padding(
                                        padding: EdgeInsetsDirectional.only(
                                            start: 20.0),
                                        child: Form(
                                            key: _formkey2,
                                            child: Container(
                                                width: deviceWidth! / 1.7,
                                                child: TextFormField(
                                                  //enabled: isEdit ? false : true,
                                                  readOnly: isEditEmail
                                                      ? false
                                                      : true,
                                                  onSaved: (newValue) {
                                                    setState(() {
                                                      email = newValue!;
                                                    });
                                                  },
                                                  validator: (val) =>
                                                      emailValidation(
                                                          val!, context),
                                                  decoration:
                                                      new InputDecoration(
                                                    border: InputBorder.none,
                                                    focusedBorder:
                                                        InputBorder.none,
                                                    enabledBorder:
                                                        InputBorder.none,
                                                    errorBorder:
                                                        InputBorder.none,
                                                    disabledBorder:
                                                        InputBorder.none,
                                                    isDense: true,
                                                    contentPadding:
                                                        EdgeInsets.all(0),
                                                  ),
                                                  controller: emailC,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle1
                                                      ?.copyWith(
                                                        color: colors
                                                            .tempdarkColor,
                                                      ),
                                                ))),
                                      ),
                                      Spacer(),
                                      type != login_email &&
                                              type != login_fb &&
                                              type != login_gmail
                                          ? !isEditEmail
                                              ? InkWell(
                                                  child: SvgPicture.asset(
                                                    "assets/images/edit_icon.svg",
                                                    semanticsLabel: 'edit icon',
                                                    height: 16,
                                                    width: 16,
                                                    color: colors.darkColor1,
                                                  ),
                                                  onTap: () {
                                                    setState(() {
                                                      isEditEmail = true;
                                                    });
                                                  },
                                                )
                                              : InkWell(
                                                  child: Icon(
                                                    Icons.check_box,
                                                    size: 20,
                                                    color: colors.darkColor1,
                                                  ),
                                                  onTap: () {
                                                    final form =
                                                        _formkey2.currentState;
                                                    if (form!.validate()) {
                                                      form.save();
                                                      setState(() {
                                                        email = emailC!.text;
                                                      });
                                                      _setUpdateProfile(
                                                          "", "", email!);
                                                    }
                                                  },
                                                )
                                          : Container(),
                                    ]))
                            : Container(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.directional(
                textDirection: Directionality.of(context),
                end: 13,
                top: 10,
                height: 35,
                width: 35,
                child: InkWell(
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(35.0),
                      child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: EdgeInsets.all(5.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(35.0),
                              color: colors.tempboxColor.withOpacity(0.7),
                            ),
                            child: Icon(
                              Icons.add_circle_outline,
                              color: colors.darkColor1,
                              size: 22,
                            ),
                          ))),
                  onTap: () {
                    _showPicker();
                  },
                ))
          ])
        : Stack(children: <Widget>[
            Container(
              height: 340,
              width: width,
              decoration: BoxDecoration(
                  color: !isDark! ? colors.primary : colors.tempdarkColor,
                  borderRadius: BorderRadius.circular(20)),
            ),
            Positioned.directional(
                textDirection: Directionality.of(context),
                end: 13,
                top: 10,
                height: 35,
                width: 35,
                child: InkWell(
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(35.0),
                      child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: EdgeInsets.all(5.0),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(35.0),
                                color: colors.tempboxColor),
                            child: Icon(
                              Icons.login_sharp,
                              color: colors.darkColor1,
                              size: 22,
                            ),
                          ))),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Login()),
                    );
                  },
                )),
            Positioned.directional(
                textDirection: Directionality.of(context),
                bottom: 12.0,
                start: 12,
                end: 12,
                height: 136,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.all(25.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              color: colors.tempboxColor.withOpacity(0.94),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  getTranslated(context, 'auth_required')!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1
                                      ?.copyWith(
                                          color: colors.tempdarkColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 19),
                                ),
                                Padding(
                                    padding: EdgeInsets.only(top: 13.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          getTranslated(context, 'plz_lbl')!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2
                                              ?.copyWith(
                                                color: colors.tempdarkColor,
                                              ),
                                        ),
                                        InkWell(
                                          child: Text(
                                            "\t" +
                                                getTranslated(
                                                    context, 'login_btn')!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .subtitle2
                                                ?.copyWith(
                                                    color: colors.primary,
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                          onTap: () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      Login()),
                                            );
                                          },
                                        ),
                                        Text(
                                          "\t" +
                                              getTranslated(
                                                  context, 'first_acc_lbl')!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2
                                              ?.copyWith(
                                                color: colors.tempdarkColor,
                                              ),
                                        ),
                                      ],
                                    )),
                                Text(
                                  getTranslated(context, 'all_fun_lbl')!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle2
                                      ?.copyWith(
                                        color: colors.tempdarkColor,
                                      ),
                                ),
                              ],
                            ))))),
            Padding(
                padding: EdgeInsets.only(top: 20.0, bottom: 20.0),
                child: Center(
                  child: Icon(
                    Icons.person_outline,
                    size: 160.0,
                    color: colors.tempboxColor,
                  ),
                ))
          ]);
  }

  languageDialog() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0))),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                      padding: EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                      child: Text(
                        getTranslated(context, 'choose_lan_lbl')!,
                        style: Theme.of(this.context)
                            .textTheme
                            .subtitle1
                            ?.copyWith(
                                color: Theme.of(context).colorScheme.fontColor),
                      )),
                  Divider(),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: getLngList()),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                new TextButton(
                    child: Text(
                      getTranslated(context, 'save_lbl')!,
                      style: Theme.of(this.context)
                          .textTheme
                          .subtitle2
                          ?.copyWith(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    })
              ],
            );
          });
        });
  }

  //set image camera
  _getFromCamera() async {
    XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile.path);
      });

      setProfilePic(image!);
    }
  }

// set image gallery
  _getFromGallery() async {
    XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile.path);
      });
      setProfilePic(image!);
    }
  }

  //set profile using api
  Future<void> setProfilePic(File _image) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      setState(() {
        _isLoading = true;
      });
      try {
        var request = MultipartRequest('POST', Uri.parse(setProfileApi));
        request.headers.addAll(headers);
        request.fields[USER_ID] = CUR_USERID;
        request.fields[ACCESS_KEY] = access_key;
        var pic = await MultipartFile.fromPath(IMAGE, _image.path);
        request.files.add(pic);

        var response = await request.send();
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        if (response.statusCode == 200) {
          var getdata = json.decode(responseString);

          String error = getdata["error"];
          String msg = getdata['message'];
          profile = getdata['file_path'];
          if (error == "false") {
            setSnackbar(getTranslated(context, 'profile_success')!);
            setState(() {
              setPrefrence(PROFILE, profile);
            });
            String? img1 = await getPrefrence(PROFILE);
          } else {
            setSnackbar(msg);
          }
          setState(() {
            _isLoading = false;
          });
        } else {
          return null;
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  //set user update their name using api
  _setUpdateProfile(String name, String mono, String email) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      setState(() {
        _isLoading = true;
      });
      var param = {
        ACCESS_KEY: access_key,
        USER_ID: CUR_USERID,
      };
      if (name != "") {
        param[NAME] = name;
      }
      if (mono != "") {
        param[MOBILE] = mono;
      }
      if (email != "") {
        param[EMAIL] = email;
      }

      Response response = await post(Uri.parse(setUpdateProfileApi),
              body: param, headers: headers)
          .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      String error = getdata["error"];

      if (error == "false") {
        setState(() {
          _isLoading = false;

          if (name != "") {
            isEditName = false;
            CUR_USERNAME = name;
            setPrefrence(NAME, name);
          }
          if (email != "") {
            isEditEmail = false;
            CUR_USEREMAIL = email;
            setPrefrence(EMAIL, email);
          }
          if (mono != "") {
            isEditMono = false;
            setPrefrence(MOBILE, mono);
          }
        });

        setSnackbar(getTranslated(context, 'profile_update_msg')!);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
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

  //user profile upload function
  void _showPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)), //this end here
            child: Container(
                height: 130,
                width: 80,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: 50.0, end: 50.0, top: 10.0, bottom: 10.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                            icon: Icon(
                              Icons.photo_library,
                              color: Theme.of(context)
                                  .colorScheme
                                  .fontColor
                                  .withOpacity(0.7),
                            ),
                            label: Text(
                              getTranslated(context, 'photo_lib_lbl')!,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .fontColor
                                      .withOpacity(0.7),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              _getFromGallery();
                              Navigator.of(context).pop();
                            }),
                        TextButton.icon(
                          icon: Icon(
                            Icons.photo_camera,
                            color: Theme.of(context)
                                .colorScheme
                                .fontColor
                                .withOpacity(0.7),
                          ),
                          label: Text(
                            getTranslated(context, 'camera_lbl')!,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .fontColor
                                    .withOpacity(0.7),
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            _getFromCamera();
                            Navigator.of(context).pop();
                          },
                        )
                      ]),
                )));
      },
    );
  }

  setHeader() {
    var brightness =
        SchedulerBinding.instance.window.platformBrightness == Brightness.dark;
    double width = MediaQuery.of(context).size.width;
    return CUR_USERID != ""
        ? Stack(children: <Widget>[
            ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: profile == ""
                    ? Container(
                        height: 340.0,
                        width: width,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: colors.primary),
                      )
                    : Image.network(
                        profile,
                        height: 340.0,
                        width: width,
                        fit: BoxFit.cover,
                      )),
            Positioned.directional(
              textDirection: Directionality.of(context),
              bottom: 10.0,
              start: 10,
              end: 10,
              height: CUR_USEREMAIL != ""
                  ? 130
                  : CUR_USERNAME != ""
                      ? 130
                      : 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.all(15.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: colors.tempboxColor.withOpacity(0.7),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        CUR_USERNAME != ""
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Container(
                                      height: 20,
                                      width: 20,
                                      child: SvgPicture.asset(
                                        "assets/images/user_icon.svg",
                                        semanticsLabel: 'user icon',
                                      )),
                                  Padding(
                                      padding: EdgeInsetsDirectional.only(
                                          start: 20.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text(
                                              getTranslated(
                                                  context, 'name_lbl')!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .subtitle2
                                                  ?.copyWith(
                                                    color: colors.tempdarkColor,
                                                  )),
                                          Form(
                                              key: _formkey,
                                              child: Container(
                                                  width: deviceWidth! / 1.7,
                                                  child: TextFormField(
                                                    //enabled: isEdit ? false : true,
                                                    readOnly: isEditName
                                                        ? false
                                                        : true,
                                                    onSaved: (newValue) {
                                                      setState(() {
                                                        name = newValue;
                                                      });
                                                    },
                                                    validator: (val) =>
                                                        nameValidation(
                                                            val!, context),
                                                    decoration:
                                                        new InputDecoration(
                                                      border: InputBorder.none,
                                                      focusedBorder:
                                                          InputBorder.none,
                                                      enabledBorder:
                                                          InputBorder.none,
                                                      errorBorder:
                                                          InputBorder.none,
                                                      disabledBorder:
                                                          InputBorder.none,
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.all(0),
                                                    ),
                                                    controller: nameC,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .subtitle1
                                                        ?.copyWith(
                                                          color: colors
                                                              .tempdarkColor,
                                                        ),
                                                  ))),
                                        ],
                                      )),
                                  Spacer(),
                                  !isEditName
                                      ? InkWell(
                                          child: SvgPicture.asset(
                                              "assets/images/edit_icon.svg",
                                              semanticsLabel: 'edit icon',
                                              height: 16,
                                              width: 16,
                                              color: colors.darkColor1),
                                          onTap: () {
                                            setState(() {
                                              isEditName = true;
                                            });
                                          },
                                        )
                                      : InkWell(
                                          child: Icon(Icons.check_box,
                                              size: 20,
                                              color: colors.darkColor1),
                                          onTap: () {
                                            final form = _formkey.currentState;
                                            if (form!.validate()) {
                                              form.save();
                                              setState(() {
                                                name = nameC!.text;
                                              });
                                              _setUpdateProfile(name!, "", "");
                                            }
                                          },
                                        ),
                                ],
                              )
                            : Container(),
                        mobile != ""
                            ? Padding(
                                padding: EdgeInsets.only(top: 7.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Container(
                                        height: 20,
                                        width: 20,
                                        child: SvgPicture.asset(
                                          "assets/images/mobile_icon.svg",
                                          semanticsLabel: 'mobile',
                                        )),
                                    Padding(
                                        padding: EdgeInsetsDirectional.only(
                                            start: 20.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Text(
                                                getTranslated(
                                                    context, 'mobile_lbl')!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .subtitle2
                                                    ?.copyWith(
                                                      color:
                                                          colors.tempdarkColor,
                                                    )),
                                            Form(
                                                key: _formkey1,
                                                child: Container(
                                                    width: deviceWidth! / 1.7,
                                                    child: TextFormField(
                                                      //enabled: isEdit ? false : true,
                                                      readOnly: isEditMono
                                                          ? false
                                                          : true,
                                                      onSaved: (newValue) {
                                                        setState(() {
                                                          mobile = newValue!;
                                                        });
                                                      },
                                                      validator: (val) =>
                                                          mobValidation(
                                                              val!, context),
                                                      decoration:
                                                          new InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        focusedBorder:
                                                            InputBorder.none,
                                                        enabledBorder:
                                                            InputBorder.none,
                                                        errorBorder:
                                                            InputBorder.none,
                                                        disabledBorder:
                                                            InputBorder.none,
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets.all(0),
                                                      ),
                                                      controller: monoC,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .subtitle1
                                                          ?.copyWith(
                                                            color: colors
                                                                .tempdarkColor,
                                                          ),
                                                    ))),
                                          ],
                                        )),
                                    Spacer(),
                                    type != login_mbl
                                        ? !isEditMono
                                            ? InkWell(
                                                child: SvgPicture.asset(
                                                  "assets/images/edit_icon.svg",
                                                  semanticsLabel: 'edit icon',
                                                  height: 16,
                                                  width: 16,
                                                  color: colors.darkColor1,
                                                ),
                                                onTap: () {
                                                  setState(() {
                                                    isEditMono = true;
                                                  });
                                                },
                                              )
                                            : InkWell(
                                                child: Icon(
                                                  Icons.check_box,
                                                  size: 20,
                                                  color: colors.darkColor1,
                                                ),
                                                onTap: () {
                                                  final form =
                                                      _formkey1.currentState;
                                                  if (form!.validate()) {
                                                    form.save();
                                                    setState(() {
                                                      mobile = monoC!.text;
                                                    });
                                                    _setUpdateProfile(
                                                        "", mobile, "");
                                                  }
                                                },
                                              )
                                        : Container(),
                                  ],
                                ))
                            : Container(),
                        CUR_USEREMAIL != ""
                            ? Padding(
                                padding: EdgeInsets.only(top: 7.0),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Container(
                                          height: 20,
                                          width: 20,
                                          child: SvgPicture.asset(
                                            "assets/images/email_icon.svg",
                                            semanticsLabel: 'email',
                                          )),
                                      Padding(
                                        padding: EdgeInsetsDirectional.only(
                                            start: 20.0),
                                        child: Form(
                                            key: _formkey2,
                                            child: Container(
                                                width: deviceWidth! / 1.7,
                                                child: TextFormField(
                                                  //enabled: isEdit ? false : true,
                                                  readOnly: isEditEmail
                                                      ? false
                                                      : true,
                                                  onSaved: (newValue) {
                                                    setState(() {
                                                      email = newValue!;
                                                    });
                                                  },
                                                  validator: (val) =>
                                                      emailValidation(
                                                          val!, context),
                                                  decoration:
                                                      new InputDecoration(
                                                    border: InputBorder.none,
                                                    focusedBorder:
                                                        InputBorder.none,
                                                    enabledBorder:
                                                        InputBorder.none,
                                                    errorBorder:
                                                        InputBorder.none,
                                                    disabledBorder:
                                                        InputBorder.none,
                                                    isDense: true,
                                                    contentPadding:
                                                        EdgeInsets.all(0),
                                                  ),
                                                  controller: emailC,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle1
                                                      ?.copyWith(
                                                        color: colors
                                                            .tempdarkColor,
                                                      ),
                                                ))),
                                      ),
                                      Spacer(),
                                      type != login_email &&
                                              type != login_fb &&
                                              type != login_gmail
                                          ? !isEditEmail
                                              ? InkWell(
                                                  child: SvgPicture.asset(
                                                    "assets/images/edit_icon.svg",
                                                    semanticsLabel: 'edit icon',
                                                    height: 16,
                                                    width: 16,
                                                    color: colors.darkColor1,
                                                  ),
                                                  onTap: () {
                                                    setState(() {
                                                      isEditEmail = true;
                                                    });
                                                  },
                                                )
                                              : InkWell(
                                                  child: Icon(
                                                    Icons.check_box,
                                                    size: 20,
                                                    color: colors.darkColor1,
                                                  ),
                                                  onTap: () {
                                                    final form =
                                                        _formkey2.currentState;
                                                    if (form!.validate()) {
                                                      form.save();
                                                      setState(() {
                                                        email = emailC!.text;
                                                      });
                                                      _setUpdateProfile(
                                                          "", "", email!);
                                                    }
                                                  },
                                                )
                                          : Container(),
                                    ]))
                            : Container(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.directional(
                textDirection: Directionality.of(context),
                end: 13,
                top: 10,
                height: 35,
                width: 35,
                child: InkWell(
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(35.0),
                      child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: EdgeInsets.all(5.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(35.0),
                              color: colors.tempboxColor.withOpacity(0.7),
                            ),
                            child: Icon(
                              Icons.add_circle_outline,
                              color: colors.darkColor1,
                              size: 22,
                            ),
                          ))),
                  onTap: () {
                    _showPicker();
                  },
                ))
          ])
        : Stack(children: <Widget>[
            Container(
              height: 340,
              width: width,
              decoration: BoxDecoration(
                  color: !isDark! ? colors.primary : colors.tempdarkColor,
                  borderRadius: BorderRadius.circular(20)),
            ),
            Positioned.directional(
                textDirection: Directionality.of(context),
                end: 13,
                top: 10,
                height: 35,
                width: 35,
                child: InkWell(
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(35.0),
                      child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: EdgeInsets.all(5.0),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(35.0),
                                color: colors.tempboxColor),
                            child: Icon(
                              Icons.login_sharp,
                              color: colors.darkColor1,
                              size: 22,
                            ),
                          ))),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Login()),
                    );
                  },
                )),
            Positioned.directional(
                textDirection: Directionality.of(context),
                bottom: 12.0,
                start: 12,
                end: 12,
                height: 136,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.all(25.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              color: colors.tempboxColor.withOpacity(0.94),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  getTranslated(context, 'auth_required')!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1
                                      ?.copyWith(
                                          color: colors.tempdarkColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 19),
                                ),
                                Padding(
                                    padding: EdgeInsets.only(top: 13.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          getTranslated(context, 'plz_lbl')!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2
                                              ?.copyWith(
                                                color: colors.tempdarkColor,
                                              ),
                                        ),
                                        InkWell(
                                          child: Text(
                                            "\t" +
                                                getTranslated(
                                                    context, 'login_btn')!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .subtitle2
                                                ?.copyWith(
                                                    color: colors.primary,
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                          onTap: () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      Login()),
                                            );
                                          },
                                        ),
                                        Text(
                                          "\t" +
                                              getTranslated(
                                                  context, 'first_acc_lbl')!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2
                                              ?.copyWith(
                                                color: colors.tempdarkColor,
                                              ),
                                        ),
                                      ],
                                    )),
                                Text(
                                  getTranslated(context, 'all_fun_lbl')!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle2
                                      ?.copyWith(
                                        color: colors.tempdarkColor,
                                      ),
                                ),
                              ],
                            ))))),
            Padding(
                padding: EdgeInsets.only(top: 20.0, bottom: 20.0),
                child: Center(
                  child: Icon(
                    Icons.person_outline,
                    size: 160.0,
                    color: colors.tempboxColor,
                  ),
                ))
          ]);
  }

  void onThemeChanged(int value) async {
    if (value == 1) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
      themeNotifier!.setThemeMode(ThemeMode.light);
      setState(() {
        isDark = false;
      });
      setPrefrence(APP_THEME, LIGHT);
    } else if (value == 2) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
      themeNotifier!.setThemeMode(ThemeMode.dark);
      setState(() {
        isDark = true;
      });
      setPrefrence(APP_THEME, DARK);
    }
    theme = await getPrefrence(APP_THEME);
  }

  setBottomContent() {
    themeNotifier = Provider.of<ThemeNotifier>(context);
    return Padding(
        padding: EdgeInsets.only(top: 20.0, bottom: 80.0),
        child: Container(
            padding: EdgeInsetsDirectional.only(start: 20.0, end: 20.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                color: Theme.of(context).colorScheme.boxColor),
            child: ListView(
              padding: EdgeInsetsDirectional.only(top: 10.0),
              shrinkWrap: true,
              physics: BouncingScrollPhysics(),
              children: <Widget>[
                // setDrawerItem(
                //   getTranslated(context, 'darkmode_lbl')!,
                //   "assets/images/darkmode_icon.svg",
                // ),
                setDrawerItem(
                  getTranslated(context, 'notification_lbl')!,
                  "",
                ),
                // setDrawerItem(
                //   getTranslated(context, 'change_lang')!,
                //   "assets/images/language_icon.svg",
                // ),
                setDrawerItem(
                  getTranslated(context, 'manage_prefrences')!,
                  "assets/images/preferences_icon.svg",
                ),
                setDrawerItem(
                  getTranslated(context, 'contact_us')!,
                  "assets/images/contactus_icon.svg",
                ),
                setDrawerItem(
                  getTranslated(context, 'about_us')!,
                  "assets/images/about_us.svg",
                ),
                setDrawerItem(
                  getTranslated(context, 'term_cond')!,
                  "assets/images/termscond_icon.svg",
                ),
                setDrawerItem(
                  getTranslated(context, 'rate_us')!,
                  "assets/images/rateus_icon.svg",
                ),
                setDrawerItem(
                  getTranslated(context, 'privacy_policy')!,
                  "assets/images/privacypolicy_icon.svg",
                ),
                setDrawerItem(
                  getTranslated(context, 'share_app')!,
                  "assets/images/share_app.svg",
                ),
                // prefs!.getString(ID).toString() != "null" &&
                //     prefs!.getString(ID).toString() != ""
                // ? Positioned(
                //     right: deviceWidth! * 0.05,
                //     top: 35,
                //     child: Center(
                //       child: IconButton(
                //           onPressed: () {
                //             logOutDailog();
                //           },
                //           icon: Icon(Icons.settings, color: Colors.red)),
                //     ))
                // : Container()
                CUR_USERID != ""
                    ? setDrawerItem(
                        getTranslated(context, 'logout_lbl')!,
                        "assets/images/logout_icon.svg",
                      )
                    : Container(),
              ],
            )));
  }

  notiStatus() {
    if (notiEnable!) {
      notiEnable = false;
      setPrefrenceBool(NOTIENABLE, false);
    } else {
      notiEnable = true;
      setPrefrenceBool(NOTIENABLE, true);
    }
    setState(() {});
  }

  //rate app function
  Future<void> _openStoreListing() => _inAppReview.openStoreListing(
        appStoreId: appStoreId,
        microsoftStoreId: 'microsoftStoreId',
      );

  //set drawer item list press
  setDrawerItem(String title, String img) {
    return ListTile(
      dense: true,
      leading: img != ""
          ? SvgPicture.asset(
              img,
              height: 20,
              width: 20,
              color: Theme.of(context).colorScheme.darkColor,
            )
          : Icon(
              Icons.notifications,
              size: 20,
              color: Theme.of(context).colorScheme.darkColor,
            ),
      trailing: title == getTranslated(context, 'darkmode_lbl')! ||
              title == getTranslated(context, 'notification_lbl')!
          ? title == getTranslated(context, 'darkmode_lbl')!
              ? isDark!
                  ? Icon(
                      Icons.toggle_on_outlined,
                      size: 25,
                      color: Theme.of(context).colorScheme.darkColor,
                    )
                  : Icon(
                      Icons.toggle_off_sharp,
                      size: 25,
                      color: Theme.of(context).colorScheme.darkColor,
                    )
              : notiEnable!
                  ? Icon(
                      Icons.toggle_on_outlined,
                      size: 25,
                      color: colors.primary,
                    )
                  : Icon(
                      Icons.toggle_off_outlined,
                      size: 25,
                      color: Theme.of(context).colorScheme.darkColor,
                    )
          : null,
      title: Text(title,
          textScaleFactor: 1.07,
          style: Theme.of(context)
              .textTheme
              .subtitle1
              ?.copyWith(color: Theme.of(context).colorScheme.darkColor)),
      onTap: () async {
        if (title == getTranslated(context, 'darkmode_lbl')!) {
          if (isDark!) {
            _updateState(1);
          } else {
            _updateState(2);
          }
        } else if (title == getTranslated(context, 'notification_lbl')!) {
          notiStatus();
        } else if (title == getTranslated(context, 'change_lang')!) {
          languageDialog();
        } else if (title == getTranslated(context, 'manage_prefrences')!) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => ManagePref(
                        from: 1,
                      )));
        } else if (title == getTranslated(context, 'contact_us')!) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => PrivacyPolicy(
                        title: getTranslated(context, 'contact_us')!,
                        from: "home",
                      )));
        } else if (title == getTranslated(context, 'about_us')!) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => PrivacyPolicy(
                        title: getTranslated(context, 'about_us')!,
                        from: "home",
                      )));
        } else if (title == getTranslated(context, 'term_cond')!) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => PrivacyPolicy(
                        title: getTranslated(context, 'term_cond')!,
                        from: "home",
                      )));
        } else if (title == getTranslated(context, 'rate_us')!) {
          _openStoreListing();
        } else if (title == getTranslated(context, 'privacy_policy')!) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => PrivacyPolicy(
                        title: getTranslated(context, 'privacy_policy')!,
                        from: "home",
                      )));
        } else if (title == getTranslated(context, 'share_app')!) {
          var str =
              "$appName\n\n$APPFIND$androidLink$packageName\n\n $IOSLBL\n$iosLink\t$iosPackage";
          Share.share(str);
        } else if (title == getTranslated(context, 'logout_lbl')!) {
          logOutDailog();
        }
      },
    );
  }

  //google sign out function
  void signOutGoogle() async {
    await googleSignIn.signOut();

    print("User Signed Out");
  }

  //set logout dialogue
  logOutDailog() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0))),
              content: Text(
                getTranslated(context, 'LOGOUTTXT')!,
                style: Theme.of(this.context)
                    .textTheme
                    .subtitle1
                    ?.copyWith(color: Theme.of(context).colorScheme.fontColor),
              ),
              actions: <Widget>[
                new TextButton(
                    child: Text(
                      getTranslated(context, 'NO')!,
                      style: Theme.of(this.context)
                          .textTheme
                          .subtitle2
                          ?.copyWith(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    }),
                new TextButton(
                    child: Text(
                      getTranslated(context, 'YES')!,
                      style: Theme.of(this.context)
                          .textTheme
                          .subtitle2
                          ?.copyWith(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      try {
                        
                      await googleSignIn.signOut();
                      } catch (e) {
                      }
                      //await facebookSignIn.logOut();
                      await _auth.signOut();
                      clearUserSession();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Login()),
                      );
                    })
              ],
            );
          });
        });
  }

  bookbarkView() {
    return bookmarkList.length != 0
        ? Container(
            height: deviceHeight,
            child: Column(
              children: [
                Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Container(
                      height: deviceWidth! * 0.1,
                      alignment: Alignment.center,
                      color: Colors.grey.withOpacity(0.5),
                      child: Text("Saved Content",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: deviceWidth! * 0.04,
                            color: Colors.white,
                          )),
                    )),
                Expanded(
                  child: StaggeredGrid.count(
                    crossAxisCount: 3,
                    children: List.generate(bookmarkList.length, (index) {
                      return Container(
                          margin: EdgeInsets.all(deviceWidth! * 0.005),
                          child: FadeInImage(
                              fadeInDuration: Duration(milliseconds: 150),
                              image: CachedNetworkImageProvider(
                                  bookmarkList[index].image!),
                              fit: BoxFit.cover,
                              imageErrorBuilder: (context, error, stackTrace) =>
                                  errorWidget(250, 450),
                              placeholder: AssetImage(
                                placeHolder,
                              )));
                    }),
                  ),
                ),
              ],
            ),
          )
        : contentShimmer(context);
  }
}
