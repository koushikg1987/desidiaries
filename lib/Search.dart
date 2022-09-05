import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/String.dart';
import 'Helper/Session.dart';
import 'Login.dart';
import 'Model/News.dart';
import 'NewsDetails.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

bool buildResult = false;

class _SearchState extends State<Search> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  int pos = 0;
  bool _isProgress = false;
  List<News> searchList = [];
  List<TextEditingController> _controllerList = [];
  bool _isNetworkAvail = true;

  String query = "";
  int notificationoffset = 0;
  ScrollController? notificationcontroller;
  bool notificationisloadmore = true,
      notificationisgettingdata = false,
      notificationisnodata = false;

  late AnimationController _animationController;
  Timer? _debounce;
  List<News> history = [];
  bool _hasSpeech = false;
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;

  String lastStatus = '';
  String _currentLocaleId = '';
  String lastWords = '';
  late StateSetter setStater;
  List<String> hisList = [];

  @override
  void initState() {
    super.initState();
    //getHistory();
    searchList.clear();

    notificationoffset = 0;

    notificationcontroller = ScrollController(keepScrollOffset: true);
    notificationcontroller!.addListener(_transactionscrollListener);

    _controller.addListener(() {
      if (_controller.text.isEmpty) {
        if (mounted)
          setState(() {
            query = "";
          });
      } else {
        query = _controller.text;
        notificationoffset = 0;
        notificationisnodata = false;
        buildResult = false;
        if (query.trim().length > 0) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            if (query.trim().length > 0) {
              notificationisloadmore = true;
              notificationoffset = 0;

              getSearchNews();
            }
          });
        }
      }
    });
  }

  _transactionscrollListener() {
    if (notificationcontroller!.offset >=
            notificationcontroller!.position.maxScrollExtent &&
        !notificationcontroller!.position.outOfRange) {
      if (mounted)
        setState(() {
          getSearchNews();
        });
    }
  }

  Future<List<String>> getHistory() async {
    hisList = (await getPrefrenceList(HISTORY_LIST))!;
    return hisList;
  }

  @override
  void dispose() {
    notificationcontroller!.dispose();
    _controller.dispose();
    for (int i = 0; i < _controllerList.length; i++)
      _controllerList[i].dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: Builder(builder: (BuildContext context) {
          return Padding(
              padding: EdgeInsetsDirectional.only(
                  start: 10.0, top: 6.0, bottom: 6.0),
              child: Container(
                  height: 35,
                  padding: EdgeInsets.all(10.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: SvgPicture.asset(
                      "assets/images/back_icon.svg",
                      semanticsLabel: 'back icon',
                      color: colors.primary,
                    ),
                  )));
        }),
        backgroundColor: Theme.of(context).canvasColor,
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
              hintText: "Search",
              hintStyle: TextStyle(
                  color:
                      Theme.of(context).colorScheme.darkColor.withOpacity(0.5)),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.boxColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.boxColor),
              ),
              fillColor: colors.bgColor),
          // onChanged: (query) => updateSearchQuery(query),
        ),
        titleSpacing: 0,
        actions: [
          IconButton(
            onPressed: () {
              _controller.text = '';
            },
            icon: Icon(
              Icons.close,
              color: colors.primary,
            ),
          )
        ],
      ),
      body: _showContent(),
    );
  }

  Widget listItem(int index) {
    News model = searchList[index];

    if (_controllerList.length < index + 1)
      _controllerList.add(new TextEditingController());
    return Hero(
      tag: searchList[index].id!,
      child: Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 7.0),
          child: ListTile(
              title: Text(
                searchList[index].title!,
                style: Theme.of(context).textTheme.subtitle2!.copyWith(
                    color: Theme.of(context).colorScheme.fontColor,
                    fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              leading: ClipRRect(
                  borderRadius: BorderRadius.circular(7.0),
                  child: FadeInImage.assetNetwork(
                    image: searchList[index].image!,
                    fadeInDuration: Duration(milliseconds: 10),
                    fit: BoxFit.cover,
                    height: 80,
                    width: 80,
                    placeholder: placeHolder,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return errorWidget(80, 80);
                    },
                  )),
              onTap: () async {
                FocusScope.of(context).requestFocus(new FocusNode());
                News model = searchList[index];
                List<News> seList = [];
                seList.addAll(searchList);
                seList.removeAt(index);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => NewsDetails(
                          model: model,
                          index: index,
                          //updateParent: updateHome,
                          id: model.id,
                          isFav: false,
                          isDetails: true,
                          news: seList,
                          //updateHome: updateHome,
                        )));
              })),
    );
    /* return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Hero(
                      tag: "$index${model.id}",
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(7.0),
                          child: FadeInImage.assetNetwork(
                            image: searchList[index].image!,
                            height: 80.0,
                            width: 80.0,
                            fit: BoxFit.cover,
                            imageErrorBuilder: (context, error, stackTrace) =>
                                errorWidget(80,80),
                            placeholder: placeHolder,
                          ))),
                  Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              model.title!,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle2!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                      fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )),
                  )
                ],
              ),
            ],
          ),
          splashColor: colors.primary.withOpacity(0.2),
          onTap: () {
            FocusScope.of(context).requestFocus(new FocusNode());
            News model = searchList[index];
            List<News> seList=[];
            seList.addAll(seList);
            seList.removeAt(index);
            Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) => NewsDetails(
                      model: model,
                      index: index,
                      //updateParent: updateHome,
                      id: model.id,
                      isFav: false,
                      isDetails: true,
                      news: seList,
                      //updateHome: updateHome,
                    )));
          },
        ),
      ),
    );*/
  }

  //searchbar shown
  /*listItem(int index) {
    return InkWell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(
              flex: 1,
              child: SvgPicture.asset(
                "assets/images/search_icon.svg",
                height: 18,
                width: 18,
                color: Theme.of(context).colorScheme.fontColor,
              ),
            ),
            Expanded(
                flex: 10,
                child: Padding(
                    padding: EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                    child: Text(searchList[index].title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.subtitle2!.copyWith(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold),))),
            Expanded(
                flex: 1,
                child: Image.asset(
                  "assets/images/search bar arrow.png",
                  color: Theme.of(context).colorScheme.fontColor,
                ))
          ]),
          Divider(
            color: Theme.of(context).colorScheme.fontColor,
          ),
        ],
      ),
      onTap: () async {
        _controller.clear();
        News model = searchList[index];
        Navigator.of(context).push(MaterialPageRoute(
            builder: (BuildContext context) => NewsDetails(
                  model: model,
                  index: index,
                  //updateParent: updateHome,
                  id: model.id,
                  isFav: false,
                  isDetails: true,
                  //updateHome: updateHome,
                )));
      },
    );
  }*/

  Future getSearchNews() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (notificationisloadmore) {
          setState(() {
            notificationisloadmore = false;
            notificationisgettingdata = true;
            if (notificationoffset == 0) {
              searchList = [];
            }
          });

          var parameter = {
            ACCESS_KEY: access_key,
            SEARCH: query.trim(),
            LIMIT: perPage.toString(),
            OFFSET: notificationoffset.toString(),
            USER_ID: CUR_USERID != "" ? CUR_USERID : "0"
          };

          Response response = await post(Uri.parse(getNewsApi),
                  headers: headers, body: parameter)
              .timeout(Duration(seconds: timeOut));

          var getdata = json.decode(response.body);

          String error = getdata["error"];
          //String msg = getdata["message"];

          notificationisgettingdata = false;
          if (notificationoffset == 0) if (error == "false") {
            notificationisnodata = false;
          } else {
            notificationisnodata = true;
          }

          if (error == "false") {
            if (mounted) {
              new Future.delayed(
                  Duration.zero,
                  () => setState(() {
                        List mainlist = getdata['data'];

                        if (mainlist.length != 0) {
                          List<News> items = [];
                          List<News> allItems = [];

                          items.addAll(mainlist
                              .map((data) => new News.fromJson(data))
                              .toList());

                          allItems.addAll(items);

                          if (notificationoffset == 0 && !buildResult) {
                            News element = News(
                                title: 'Search Result for "$query"',
                                image: "",
                                history: false);
                            searchList.insert(0, element);
                            for (int i = 0; i < history.length; i++) {
                              if (history[i].title == query)
                                searchList.insert(0, history[i]);
                            }
                          }

                          for (News item in items) {
                            searchList.where((i) => i.id == item.id).map((obj) {
                              allItems.remove(item);
                              return obj;
                            }).toList();
                          }
                          searchList.addAll(allItems);
                          notificationisloadmore = true;
                          notificationoffset = notificationoffset + perPage;
                        } else {
                          notificationisloadmore = false;
                        }
                      }));
            }
          } else {
            notificationisloadmore = false;
            setState(() {});
          }
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
        setState(() {
          notificationisloadmore = false;
        });
      }
    } else {
      setState(() {
        _isNetworkAvail = false;
      });
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

  clearAll() {
    setState(() {
      query = _controller.text;
      notificationoffset = 0;
      notificationisloadmore = true;
      searchList.clear();
    });
  }

  _showContent() {
    if (_controller.text == "") {
      return FutureBuilder<List<String>>(
          future: getHistory(),
          builder:
              (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              final entities = snapshot.data!;
              List<News> itemList = [];
              for (int i = 0; i < entities.length; i++) {
                News item = News.history(entities[i]);
                itemList.add(item);
              }
              history.clear();
              history.addAll(itemList);

              return SingleChildScrollView(
                padding: EdgeInsetsDirectional.only(top: 15.0),
                child: Column(
                  children: [
                    _SuggestionList(
                      textController: _controller,
                      suggestions: itemList,
                      notificationcontroller: notificationcontroller,
                      getProduct: getSearchNews,
                      clearAll: clearAll,
                    ),
                  ],
                ),
              );
            } else {
              return Column();
            }
          });
    } else if (buildResult) {
      return notificationisnodata
          ? Center(child: Text(getTranslated(context, 'no_news')!))
          : Padding(
              padding: EdgeInsetsDirectional.only(top: 15.0),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: ListView.builder(
                        padding: EdgeInsetsDirectional.only(
                            bottom: 5, start: 10, end: 10, top: 12),
                        controller: notificationcontroller,
                        physics: BouncingScrollPhysics(),
                        itemCount: searchList.length,
                        itemBuilder: (context, index) {
                          News? item;
                          try {
                            item =
                                searchList.isEmpty ? null : searchList[index];
                            if (notificationisloadmore &&
                                index == (searchList.length - 1) &&
                                notificationcontroller!.position.pixels <= 0) {
                              getSearchNews();
                            }
                          } on Exception catch (_) {}

                          return item == null ? Container() : listItem(index);
                        }),
                  ),
                  notificationisgettingdata
                      ? Padding(
                          padding:
                              EdgeInsetsDirectional.only(top: 5, bottom: 5),
                          child: CircularProgressIndicator(),
                        )
                      : Container(),
                ],
              ));
    }
    return notificationisnodata
        ? Center(child: Text(getTranslated(context, 'no_news')!))
        : Padding(
            padding: EdgeInsetsDirectional.only(top: 15.0),
            child: Column(
              children: <Widget>[
                Expanded(
                    child: _SuggestionList(
                  textController: _controller,
                  suggestions: searchList,
                  notificationcontroller: notificationcontroller,

                  getProduct: getSearchNews,
                  clearAll: clearAll,
                  // onSelected: (String suggestion) {
                  //   query = suggestion;
                  // },
                )),
                notificationisgettingdata
                    ? Padding(
                        padding: EdgeInsetsDirectional.only(top: 5, bottom: 5),
                        child: CircularProgressIndicator(),
                      )
                    : Container(),
              ],
            ));
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList(
      {this.suggestions,
      this.textController,
      this.searchDelegate,
      this.notificationcontroller,
      this.getProduct,
      this.clearAll});

  final List<News>? suggestions;
  final TextEditingController? textController;

  final notificationcontroller;
  final SearchDelegate<News>? searchDelegate;
  final Function? getProduct, clearAll;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: suggestions!.length,
      shrinkWrap: true,
      controller: notificationcontroller,
      separatorBuilder: (BuildContext context, int index) => Divider(),
      itemBuilder: (BuildContext context, int i) {
        final News suggestion = suggestions![i];

        return Hero(
          tag: suggestion.id!,
          child: ListTile(
              title: Text(
                suggestion.title!,
                style: Theme.of(context).textTheme.subtitle2!.copyWith(
                    color: Theme.of(context).colorScheme.fontColor,
                    fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              leading: textController!.text.toString().trim().isEmpty ||
                      suggestion.history!
                  ? Icon(Icons.history)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(7.0),
                      child: suggestion.image == ''
                          ? Image.asset(
                              'assets/images/placeholder.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : FadeInImage.assetNetwork(
                              image: suggestion.image!,
                              fadeInDuration: Duration(milliseconds: 10),
                              fit: BoxFit.cover,
                              height: 80,
                              width: 80,
                              placeholder: placeHolder,
                              imageErrorBuilder: (context, error, stackTrace) {
                                return errorWidget(80, 80);
                              },
                            )),
              trailing: Image.asset(
                "assets/images/search bar arrow.png",
                color: Theme.of(context).colorScheme.fontColor,
              ),
              onTap: () async {
                if (suggestion.title!.startsWith('Search Result for ')) {
                  setPrefrenceList(
                      HISTORY_LIST, textController!.text.toString().trim());
                  buildResult = true;
                  clearAll!();
                  getProduct!();
                } else if (suggestion.history!) {
                  clearAll!();

                  buildResult = true;
                  textController!.text = suggestion.title!;
                  textController!.selection = TextSelection.fromPosition(
                      TextPosition(offset: textController!.text.length));
                } else {
                  setPrefrenceList(
                      HISTORY_LIST, textController!.text.toString().trim());
                  buildResult = false;
                  News model = suggestion;
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => NewsDetails(
                            model: model,
                            //index: index,
                            //updateParent: updateHome,
                            id: model.id,
                            isFav: false,
                            isDetails: true,
                            news: [],
                            //updateHome: updateHome,
                          )));
                }
              }),
        );
      },
    );
  }
}
