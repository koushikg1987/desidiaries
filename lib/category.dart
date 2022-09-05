import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
import 'package:news/Home.dart';
import 'package:news/Model/BreakingNews.dart';
import 'package:news/Model/News.dart';
import 'package:news/NewsTag.dart';
import 'package:news/NotificationList.dart';
import 'package:news/Search.dart';
import 'package:news/Profile.dart';
import 'package:news/appBarTitle.dart';
import 'package:news/categoryNews.dart';
import 'package:shimmer/shimmer.dart';
import 'Helper/PushNotificationService.dart';
import 'Live.dart';
import 'Login.dart';
import 'Model/Category.dart';
import 'Model/WeatherData.dart';
import 'NewsDetails.dart';
import 'SubHome.dart';
import 'main.dart';

class Categoryy extends StatefulWidget {
  @override
  CategoryyState createState() => CategoryyState();
}

class CategoryyState extends State<Categoryy> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool isTab = false;
  List<Category> tempCatList = [];
  List<Category> catList = [];
  bool _isNetworkAvail = true;
  bool _isLoading = true;
  FocusNode _searchFocusNode = FocusNode();
  int? selectSubCat = 0;
  SubHome subHome = SubHome();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.unfocus();

    getCat();
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

  @override
  Widget build(BuildContext context) {
    deviceWidth = MediaQuery.of(context).size.width;
    deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
        backgroundColor: colors.bgColor,
        key: _scaffoldKey,
        appBar: PreferredSize(
            preferredSize: Size(double.infinity, 45),
            child: AppBar(
              leadingWidth: 50,
              elevation: 0.0,
               actions: [
                Container(
                  width: 50,
                )
              ],
              centerTitle: true,
              backgroundColor: Colors.transparent,
              title: appBarTitle(),
                leading: Container(width:0),

            )),
        body:
            // isTab
            //     ? subHome
            //     :
            SafeArea(
                child: catList.length != 0

                    // ? GridView.builder(
                    //     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    //       crossAxisCount: 2,
                    //       crossAxisSpacing: 1.5,
                    //       mainAxisSpacing: 1.5,
                    //       childAspectRatio: 1.5,
                    //     ),
                    //     shrinkWrap: true,
                    //     physics: NeverScrollableScrollPhysics(),
                    //     padding: EdgeInsets.zero,
                    //     itemCount: tempCatList.length,
                    //     itemBuilder: (context, index) =>
                    //         itemView(tempCatList[index]))
                    ? Container(
                        height: deviceHeight,
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 25.0, vertical: 15.0),
                              child: TextField(
                                autofocus: false,
                                focusNode: _searchFocusNode,
                                decoration: InputDecoration(
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 10.0),
                                    hintText: "Search",
                                    hintStyle: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .darkColor
                                            .withOpacity(0.5)),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                                    suffixIcon: Icon(Icons.search),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                                    fillColor: colors.bgColor),
                                // onChanged: (query) => updateSearchQuery(query),
                              ),
                            ),
                            Expanded(
                              child: StaggeredGrid.count(
                                crossAxisCount: 3,
                                children:
                                    List.generate(tempCatList.length, (index) {
                                  return
                                      // catList[index].subData!.length != 0
                                      //     ?
                                      InkWell(
                                    onTap: () {
                                      // Navigator.of(context).push(
                                      //     MaterialPageRoute(
                                      //         builder: (BuildContext context) =>
                                      //             HomePage()));
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (BuildContext context) =>
                                                  CategoryNews(categoryId: tempCatList[index].id.toString(),)));
                                      // isTab = true;
                                      // selectSubCat = index;

                                      // if (index == 0) {
                                      //   subHome =  SubHome(
                                      //       subCatId: "1",
                                      //       curTabId: catList[index].id!,
                                      //       index: index,
                                      //       isSubCat: true,
                                      //       catList: catList,
                                      //       scrollController: null,
                                      //     );
                                      // } else {
                                      //   subHome =  SubHome(
                                      //       subCatId:"1",
                                      //       curTabId: "0",
                                      //       index: index,
                                      //       isSubCat: true,
                                      //       catList: catList,
                                      //       scrollController: null,
                                      //     );
                                      // }
                                      // setState(() {});
                                      //  if (index == 0) {
                                      //     Navigator.of(context).push(MaterialPageRoute(
                                      //     builder: (BuildContext context) =>
                                      //     SubHome(
                                      //   subCatId: "0",
                                      //   curTabId: catList[index].id!,
                                      //   index: index,
                                      //   isSubCat: true,
                                      //   catList: catList,
                                      //   scrollController: null,
                                      // )));

                                      //   } else {
                                      //      Navigator.of(context).push(MaterialPageRoute(
                                      //     builder: (BuildContext context) =>
                                      //      SubHome(
                                      //   subCatId: catList[index]
                                      //       .subData![0]
                                      //       .id!,
                                      //   curTabId: "0",
                                      //   index: index,
                                      //   isSubCat: true,
                                      //   catList: catList,
                                      //   scrollController: null,
                                      // )));

                                      //   }
                                    },
                                    child: Container(
                                        margin: EdgeInsets.all(
                                            deviceWidth! * 0.002),
                                        child: FadeInImage(
                                            fadeInDuration:
                                                Duration(milliseconds: 150),
                                            image: CachedNetworkImageProvider(
                                                tempCatList[index].image!),
                                            fit: BoxFit.cover,
                                            imageErrorBuilder:
                                                (context, error, stackTrace) =>
                                                    errorWidget(250, 450),
                                            placeholder: AssetImage(
                                              placeHolder,
                                            ))),
                                  )
                                      // : Container()
                                      ;
                                }),
                              ),
                            ),
                          ],
                        ),
                      )
// Wrap(

//                       children: List.generate(tempCatList.length, (index) {
//                         return Container(
//                             child: FadeInImage(
//                                 fadeInDuration: Duration(milliseconds: 150),
//                                 image: CachedNetworkImageProvider(
//                                     tempCatList[index].image!),
//                                 fit: BoxFit.cover,
//                                 imageErrorBuilder: (context, error, stackTrace) =>
//                                     errorWidget(250, 450),
//                                 placeholder: AssetImage(
//                                   placeHolder,
//                                 )));
//                       }),
//                     ),
//                 )
                    : contentShimmer(context)));
  }

  itemView(Category itemData) {
    return Center(
      child: Container(
        width: deviceWidth! * 0.3,
        height: deviceWidth! * 0.3,
        child: Stack(
          children: [
            Container(
              width: deviceWidth! * 0.3,
              height: deviceWidth! * 0.3,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: FadeInImage(
                      fadeInDuration: Duration(milliseconds: 150),
                      image: CachedNetworkImageProvider(itemData.image!),
                      height: 250.0,
                      width: 450.0,
                      fit: BoxFit.cover,
                      imageErrorBuilder: (context, error, stackTrace) =>
                          errorWidget(250, 450),
                      placeholder: AssetImage(
                        placeHolder,
                      ))),
            ),
            Container(
              width: deviceWidth! * 0.3,
              height: deviceWidth! * 0.3,
              alignment: Alignment.center,
              color: Colors.black.withOpacity(0.1),
              child: Text(
                itemData.categoryName!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

//get all category using api
  Future<void> getCat() async {
    if (category_mode == "1") {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        var param = {
          ACCESS_KEY: access_key,
        };
        try {
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
            setState(() {});
          }
        } catch (e) {}
      }
    }
  }
}
