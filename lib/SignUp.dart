import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:news/Helper/Color.dart';
import 'package:news/Helper/Constant.dart';
import 'package:news/Helper/Session.dart';
import 'package:news/Helper/String.dart';
import 'package:news/Login.dart';

import 'Privacy.dart';

class SignUp extends StatefulWidget {
  @override
  SignUpState createState() => SignUpState();
}

class SignUpState extends State<SignUp> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  FocusNode emailFocus = FocusNode();
  FocusNode passFocus = FocusNode();
  FocusNode nameFocus = FocusNode();
  FocusNode confPassFocus = FocusNode();
  TextEditingController emailC = TextEditingController();
  TextEditingController passC = TextEditingController();
  TextEditingController nameC = TextEditingController();
  TextEditingController confPassC = TextEditingController();
  String? email, pass, name, confPass;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  bool _isNetworkAvail = true;
  bool isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _passowrdHide = true;
  bool _cPassowrdHide = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromRGBO(253, 254, 255, 1),
        key: _scaffoldKey,
        body: Stack(
          children: <Widget>[
            showContent(),
            showCircularProgress(isLoading, colors.primary)
          ],
        ));
  }

  //show form content
  showContent() {
    return SingleChildScrollView(
        padding: EdgeInsetsDirectional.only(
            top: 70.0, bottom: 20.0, start: 20.0, end: 20.0),
        child: Form(
            key: _formkey,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  signUpTxt(),
                  nameSet(),
                  emailSet(),
                  passSet(),
                  confPassSet(),
                  signUpBtn(),
                  alreadyAccTxt(),
                  termPolicyTxt()
                ])));
  }

  signUpTxt() {
    return Text(
      getTranslated(context, 'signup_lbl')!,
      style: Theme.of(context).textTheme.headline5?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5),
    );
  }

  _fieldFocusChange(
      BuildContext context, FocusNode currentFocus, FocusNode nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  nameSet() {
    return Padding(
      padding: EdgeInsets.only(top: 40.0),
      child: TextFormField(
        focusNode: nameFocus,
        textInputAction: TextInputAction.next,
        controller: nameC,
        style: Theme.of(this.context).textTheme.subtitle1?.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
            ),
        validator: (val) => nameValidation(val!, context),
        onChanged: (String value) {
          setState(() {
            name = value;
          });
        },
        onFieldSubmitted: (v) {
          _fieldFocusChange(context, nameFocus, emailFocus);
        },
        decoration: InputDecoration(
          hintText: "${getTranslated(context, 'name_lbl')} *",
          hintStyle: Theme.of(this.context)
              .textTheme
              .subtitle1
              ?.copyWith(color: Theme.of(context).colorScheme.fontColor),
          filled: true,
          fillColor: Theme.of(context).colorScheme.boxColor,
          contentPadding: EdgeInsets.symmetric(horizontal: 25, vertical: 17),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color:
                    Theme.of(context).colorScheme.borderColor.withOpacity(0.7)),
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color:
                    Theme.of(context).colorScheme.borderColor.withOpacity(0.7),
                width: 1.5),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  emailSet() {
    return Padding(
      padding: EdgeInsets.only(top: 20.0),
      child: TextFormField(
        focusNode: emailFocus,
        textInputAction: TextInputAction.next,
        controller: emailC,
        style: Theme.of(this.context).textTheme.subtitle1?.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
            ),
        validator: (val) => emailValidation(val!, context),
        onChanged: (String value) {
          setState(() {
            email = value;
          });
        },
        onFieldSubmitted: (v) {
          _fieldFocusChange(context, emailFocus, passFocus);
        },
        decoration: InputDecoration(
          hintText: "${getTranslated(context, 'email_lbl')} *",
          hintStyle: Theme.of(this.context).textTheme.subtitle1?.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
              ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.boxColor,
          contentPadding: EdgeInsets.symmetric(horizontal: 25, vertical: 17),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color:
                    Theme.of(context).colorScheme.borderColor.withOpacity(0.7)),
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color:
                    Theme.of(context).colorScheme.borderColor.withOpacity(0.7),
                width: 1.5),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  passSet() {
    return Padding(
        padding: EdgeInsets.only(top: 20.0),
        child: TextFormField(
          focusNode: passFocus,
          textInputAction: TextInputAction.next,
          controller: passC,
          style: Theme.of(this.context).textTheme.subtitle1?.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
              ),
          validator: (val) => passValidation(val!, context),
          onChanged: (String value) {
            setState(() {
              pass = value;
            });
          },
          onFieldSubmitted: (v) {
            _fieldFocusChange(context, passFocus, confPassFocus);
          },
          obscureText: _passowrdHide,
          decoration: InputDecoration(
            hintText: "${getTranslated(context, 'pass_lbl')} *",
            hintStyle: Theme.of(this.context).textTheme.subtitle1?.copyWith(
                  color: Theme.of(context).colorScheme.fontColor,
                ),
            suffixIcon: Padding(
                padding: EdgeInsetsDirectional.only(end: 12.0),
                child: IconButton(
                  icon: Icon(
                    _passowrdHide ? Icons.visibility : Icons.visibility_off,
                    color: Theme.of(context).colorScheme.fontColor,
                  ),
                  // SvgPicture.asset(
                  //   "assets/images/eye_icon.svg",
                  //   semanticsLabel: 'eye icon',
                  //   height: 11.0,
                  //   width: 11.0,
                  //   color: Theme.of(context).colorScheme.fontColor,
                  // ),
                  onPressed: () {
                    setState(() {
                      _passowrdHide = !_passowrdHide;
                    });
                  },
                )),
            filled: true,
            fillColor: Theme.of(context).colorScheme.boxColor,
            contentPadding: EdgeInsets.symmetric(horizontal: 25, vertical: 17),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .borderColor
                      .withOpacity(0.7)),
              borderRadius: BorderRadius.circular(10.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .borderColor
                      .withOpacity(0.7),
                  width: 1.5),
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ));
  }

  confPassSet() {
    return Padding(
        padding: EdgeInsets.only(top: 20.0),
        child: TextFormField(
          focusNode: confPassFocus,
          textInputAction: TextInputAction.done,
          controller: confPassC,
          style: Theme.of(this.context).textTheme.subtitle1?.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
              ),
          validator: (value) {
            if (value?.length == 0)
              return getTranslated(context, 'confpass_required')!;
            if (value != pass) {
              return getTranslated(context, 'confpass_not_match')!;
            } else {
              return null;
            }
          },
          onChanged: (String value) {
            setState(() {
              confPass = value;
            });
          },
          obscureText: _cPassowrdHide,
          decoration: InputDecoration(
            hintText: "${getTranslated(context, 'confpass_lbl')} *",
            hintStyle: Theme.of(this.context).textTheme.subtitle1?.copyWith(
                  color: Theme.of(context).colorScheme.fontColor,
                ),
            suffixIcon: Padding(
                padding: EdgeInsetsDirectional.only(end: 12.0),
                child: IconButton(
                  icon: Icon(
                    _cPassowrdHide ? Icons.visibility : Icons.visibility_off,
                    color: Theme.of(context).colorScheme.fontColor,
                  ),
                  // SvgPicture.asset(
                  //   "assets/images/eye_icon.svg",
                  //   semanticsLabel: 'eye icon',
                  //   height: 11.0,
                  //   width: 11.0,
                  //   color: Theme.of(context).colorScheme.fontColor,
                  // ),
                  onPressed: () {
                    setState(() {
                      _cPassowrdHide = !_cPassowrdHide;
                    });
                  },
                )),
            filled: true,
            fillColor: Theme.of(context).colorScheme.boxColor,
            contentPadding: EdgeInsets.symmetric(horizontal: 25, vertical: 17),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .borderColor
                      .withOpacity(0.7)),
              borderRadius: BorderRadius.circular(10.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .borderColor
                      .withOpacity(0.7),
                  width: 1.5),
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ));
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

  //register with email and password function
  registerWithEmailPassword(String email, String password) async {
    await _auth
        .createUserWithEmailAndPassword(
      email: email,
      password: password,
    )
        .then((user) async {
      setState(() {
        isLoading = false;
      });
      await user.user?.sendEmailVerification().then((value) async {
        setSnackbar('${getTranslated(context, 'varif_sent_mail')}+$email');
        await user.user?.updateDisplayName(name?.trim());
        await user.user?.reload();
        final User? updatedUser = _auth.currentUser;

        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context);
        });

        return user.user?.uid;
      }).catchError((e) {
        print("An error occured while trying to send email verification");
        print(e.message);
        AuthCredential authCredential =
            EmailAuthProvider.credential(email: email, password: password);
        user.user?.reauthenticateWithCredential(authCredential);
        user.user?.delete();
      });
    }).catchError((e) async {
      print('**Error: $e');
      setState(() {
        isLoading = false;
      });
      String _errorMessage = e.message ?? e.toString();
      setSnackbar(_errorMessage);
    });
  }

  signUpBtn() {
    return Padding(
      padding: EdgeInsets.only(top: 45.0),
      child: InkWell(
        child: Container(
          height: 48.0,
          width: deviceWidth! * 0.6,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: colors.primary, borderRadius: BorderRadius.circular(7.0)),
          child: Text(
            getTranslated(context, 'signup_btn')!,
            style: Theme.of(this.context).textTheme.headline6?.copyWith(
                color: colors.tempboxColor,
                fontWeight: FontWeight.w600,
                fontSize: 21,
                letterSpacing: 0.6),
          ),
        ),
        onTap: () async {
          final form = _formkey.currentState;
          if (form!.validate()) {
            form.save();
            _isNetworkAvail = await isNetworkAvailable();
            if (_isNetworkAvail) {
              setState(() {
                isLoading = true;
              });
              registerWithEmailPassword(email!.trim(), pass!);
            } else {
              setState(() {
                isLoading = false;
              });
              setSnackbar(getTranslated(context, 'internetmsg')!);
            }
          }
        },
      ),
    );
  }

  alreadyAccTxt() {
    return Padding(
      padding: EdgeInsets.only(top: 30.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            getTranslated(context, 'already_acc_lbl')!,
            style: Theme.of(context).textTheme.subtitle1?.copyWith(
                  color:
                      Theme.of(context).colorScheme.fontColor.withOpacity(0.8),
                ),
          ),
          Expanded(
              child: InkWell(
                  onTap: () async {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) => Login()));
                  },
                  child: Text(
                    getTranslated(context, 'login_btn')!,
                    style: Theme.of(context).textTheme.subtitle1?.copyWith(
                        color: colors.primary, fontWeight: FontWeight.w600),
                  )))
        ],
      ),
    );
  }

  //set term and policy text
  termPolicyTxt() {
    return Padding(
        padding: EdgeInsets.only(bottom: 30.0, top: 35.0),
        child: Column(children: <Widget>[
          Text(
            getTranslated(context, 'agreeTermPolicy_lbl')!,
            style: Theme.of(context).textTheme.bodyText1?.copyWith(
                  color:
                      Theme.of(context).colorScheme.fontColor.withOpacity(0.7),
                ),
          ),
          Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                InkWell(
                  child: Text(
                    getTranslated(context, 'term_lbl')!,
                    style: Theme.of(context).textTheme.bodyText1?.copyWith(
                          color: colors.primary,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) => PrivacyPolicy(
                                  title: getTranslated(context, 'term_cond')!,
                                  from: getTranslated(context, 'signup_lbl')!,
                                )));
                  },
                ),
                Text(
                  getTranslated(context, 'and_lbl')!,
                  style: Theme.of(context).textTheme.bodyText1?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .fontColor
                            .withOpacity(0.7),
                      ),
                ),
                InkWell(
                  child: Text(
                    getTranslated(context, 'pri_policy')!,
                    style: Theme.of(context).textTheme.bodyText1?.copyWith(
                          color: colors.primary,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) => PrivacyPolicy(
                                  title:
                                      getTranslated(context, 'privacy_policy')!,
                                  from: getTranslated(context, 'signup_lbl')!,
                                )));
                  },
                ),
              ])
        ]));
  }
}
