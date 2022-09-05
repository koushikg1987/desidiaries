import 'package:flutter/material.dart';
import 'package:news/Helper/String.dart';

Widget appBarTitle({String? title}) {
  return Center(
    child: Container(
      width: deviceWidth!*0.6,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, children: [
        Container(
          child: Image.asset(
            "assets/images/onlycon.png",
            height: deviceWidth! * 0.08,
            width: deviceWidth! * 0.08,
          ),
        ),
        Container(
          margin: EdgeInsets.only(left: deviceWidth! * 0.03),
          child: Text(
          title??  "Desi Diaries",
            style: TextStyle(
                fontSize: deviceWidth! * 0.045,
                fontWeight: FontWeight.bold,
                color: Color(0xff64b8d0)),
          ),
        )
      ]),
    ),
  );
}
