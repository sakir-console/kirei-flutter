import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/other_config.dart';
import 'package:active_ecommerce_flutter/social_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:active_ecommerce_flutter/custom/input_decorations.dart';
import 'package:active_ecommerce_flutter/custom/intl_phone_input.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_gradients/flutter_gradients.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:active_ecommerce_flutter/screens/registration.dart';
import 'package:active_ecommerce_flutter/screens/main.dart';
import 'package:active_ecommerce_flutter/screens/password_forget.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:toast/toast.dart';
import 'package:active_ecommerce_flutter/repositories/auth_repository.dart';
import 'package:active_ecommerce_flutter/helpers/auth_helper.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twitter_login/twitter_login.dart';


class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String _login_by = "email"; //phone or email
  String initialCountry = 'BD';
  PhoneNumber phoneCode = PhoneNumber(isoCode: 'BD', dialCode: "+880");
  String _phone = "";

  //controllers
  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    //on Splash Screen hide statusbar
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    super.initState();
  }

  @override
  void dispose() {
    //before going to other screen show statusbar
    SystemChrome.setEnabledSystemUIOverlays(
        [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    super.dispose();
  }

  onPressedLogin() async {
    var email = _emailController.text.toString();
    var password = _passwordController.text.toString();

    if (_login_by == 'email' && email == "") {
      ToastComponent.showDialog(AppLocalizations.of(context).login_screen_email_warning, context,
          gravity: Toast.CENTER, duration: Toast.LENGTH_LONG);
      return;
    } else if (_login_by == 'phone' && _phone == "") {
      ToastComponent.showDialog(AppLocalizations.of(context).login_screen_phone_warning, context,
          gravity: Toast.CENTER, duration: Toast.LENGTH_LONG);
      return;
    } else if (password == "") {
      ToastComponent.showDialog(AppLocalizations.of(context).login_screen_password_warning, context,
          gravity: Toast.CENTER, duration: Toast.LENGTH_LONG);
      return;
    }

    var loginResponse = await AuthRepository()
        .getLoginResponse(_login_by == 'email' ? email : _phone, password);
    if (loginResponse.result == false) {
      ToastComponent.showDialog(loginResponse.message, context,
          gravity: Toast.CENTER, duration: Toast.LENGTH_LONG);
    } else {

      ToastComponent.showDialog(loginResponse.message, context,
          gravity: Toast.CENTER, duration: Toast.LENGTH_LONG);
      AuthHelper().setUserData(loginResponse);
      // push notification starts
      if (OtherConfig.USE_PUSH_NOTIFICATION) {
        final FirebaseMessaging _fcm = FirebaseMessaging.instance;

        await _fcm.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        String fcmToken = await _fcm.getToken();

        if (fcmToken != null) {
          print("--fcm token--");
          print(fcmToken);
          if (is_logged_in.$ == true) {
            print("true------------------------");
            // update device token
            var deviceTokenUpdateResponse = await ProfileRepository()
                .getDeviceTokenUpdateResponse(fcmToken);
            print("hmmmm------------------------");
          }
        }
      }

      //push norification ends

      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return Main();
      }));
    }
  }

  onPressedFacebookLogin() async {
    final facebookLogin =await FacebookAuth.instance.login(loginBehavior: LoginBehavior.webOnly);

    if (facebookLogin.status == LoginStatus.success) {

      // get the user data
      // by default we get the userId, email,name and picture
      final userData = await FacebookAuth.instance.getUserData();
      var loginResponse = await AuthRepository().getSocialLoginResponse("facebook",
          userData['name'].toString(), userData['email'].toString(), userData['id'].toString(),access_token: facebookLogin.accessToken.token);
      print("..........................${loginResponse.toString()}");
      if (loginResponse.result == false) {
        ToastComponent.showDialog(loginResponse.message, context,
            gravity: Toast.CENTER, duration: Toast.LENGTH_LONG);
      } else {
        ToastComponent.showDialog(loginResponse.message, context,
            gravity: Toast.CENTER, duration: Toast.LENGTH_LONG);
        AuthHelper().setUserData(loginResponse);
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return Main();
        }));
        FacebookAuth.instance.logOut();
      }
      // final userData = await FacebookAuth.instance.getUserData(fields: "email,birthday,friends,gender,link");

    } else {
      print("....Facebook auth Failed.........");
      print(facebookLogin.status);
      print(facebookLogin.message);
    }



  }

  onPressedGoogleLogin() async {
    try {
      final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();


      print(googleUser.toString());

      GoogleSignInAuthentication googleSignInAuthentication =
      await googleUser.authentication;
      String accessToken = googleSignInAuthentication.accessToken;


      var loginResponse = await AuthRepository().getSocialLoginResponse("google",
          googleUser.displayName, googleUser.email, googleUser.id,access_token: accessToken);

      if (loginResponse.result == false) {
        ToastComponent.showDialog(loginResponse.message, context,
            gravity: Toast.CENTER, duration: Toast.LENGTH_LONG);
      } else {
        ToastComponent.showDialog(loginResponse.message, context,
            gravity: Toast.CENTER, duration: Toast.LENGTH_LONG);
        AuthHelper().setUserData(loginResponse);
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return Main();
        }));
      }
      GoogleSignIn().disconnect();
    } on Exception catch (e) {
      print("error is ....... $e");
      // TODO
    }



  }

  onPressedTwitterLogin() async {
    try {

      final twitterLogin = new TwitterLogin(
          apiKey: SocialConfig().twitter_consumer_key,
          apiSecretKey:SocialConfig().twitter_consumer_secret,
          redirectURI: 'activeecommerceflutterapp://'

      );
      // Trigger the sign-in flow
      final authResult = await twitterLogin.login();

      var loginResponse = await AuthRepository().getSocialLoginResponse("twitter",
          authResult.user.name, authResult.user.email, authResult.user.id.toString(),access_token: authResult.authToken);
      print(loginResponse);
      if (loginResponse.result == false) {
        ToastComponent.showDialog(loginResponse.message, context,
            gravity: Toast.CENTER, duration: Toast.LENGTH_LONG);
      } else {
        ToastComponent.showDialog(loginResponse.message, context,
            gravity: Toast.CENTER, duration: Toast.LENGTH_LONG);
        AuthHelper().setUserData(loginResponse);
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return Main();
        }));
      }
    } on Exception catch (e) {
      print("error is ....... $e");
      // TODO
    }



  }

  @override
  Widget build(BuildContext context) {
    final _screen_height = MediaQuery.of(context).size.height;
    final _screen_width = MediaQuery.of(context).size.width;
    return Directionality(
      textDirection: app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Container(
              width: _screen_width * (3 / 4),
              child: Image.asset(
                  "assets/image_02.png"),
            ),
            Container(
              width: double.infinity,
              child: SingleChildScrollView(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0, bottom: 15),
                    child: Container(
                      width: 305,
                      height: 175,
                      child:
                          Image.asset('assets/image_01.png'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      "Login to get full access",
                      style: GoogleFonts.ubuntu(color: Theme.of(context)
                          .buttonTheme
                          .colorScheme
                          .primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)
                    ),
                  ),
                  Container(
                    width: _screen_width * (3 / 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        if (_login_by == "email")
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  height: 56,
                                  child:  TextField(
                                    controller: _emailController,
                                    autofocus: false,
                                    autocorrect: true,

                                    decoration: InputDecoration(
                                      hintText: 'Enter Your Email Here...',
                                      prefixIcon:  _login_by == "email" ? Icon(Icons.email) :Icon( Icons.local_phone_outlined),
                                      hintStyle: TextStyle(color: Colors.grey),
                                      filled: true,
                                      fillColor: Colors.white70,


                                    ),),




                                ),
                                otp_addon_installed.$
                                    ? GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _login_by = "phone";
                                          });
                                        },
                                        child:
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Icon(Icons.phone_android_rounded,size: 18,),
                                            Text(
                                              "Use Phone",
                                              style: GoogleFonts.ubuntu(color: Colors.grey,fontSize: 16),
                                            ),
                                          ],),

                                      )
                                    : Container()
                              ],
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  height: 36,
                                  child: CustomInternationalPhoneNumberInput(

                                    onInputChanged: (PhoneNumber number) {
                                      print(number.phoneNumber);
                                      setState(() {
                                        _phone = number.phoneNumber;
                                      });
                                    },
                                    onInputValidated: (bool value) {
                                      print(value);
                                    },
                                    selectorConfig: SelectorConfig(
                                      selectorType: PhoneInputSelectorType.DIALOG,
                                    ),
                                    ignoreBlank: false,
                                    autoValidateMode: AutovalidateMode.disabled,
                                    selectorTextStyle:
                                        TextStyle(color: MyTheme.font_grey),
                                    textStyle:
                                        TextStyle(color: MyTheme.font_grey),
                                    initialValue: phoneCode,
                                    textFieldController: _phoneNumberController,
                                    formatInput: true,
                                    keyboardType: TextInputType.numberWithOptions(
                                        signed: true, decimal: true),
                                    inputDecoration: InputDecorations
                                        .buildInputDecoration_phone(
                                            hint_text: "1710 333 558"),
                                    onSaved: (PhoneNumber number) {
                                      print('On Saved: $number');
                                    },
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _login_by = "email";
                                    });
                                  },
                                  child:      Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Icon(Icons.email_outlined,size: 18,),
                                      Text(
                                        " Use Email",
                                        style: GoogleFonts.ubuntu(color: Colors.grey,fontSize: 16),
                                      ),
                                    ],),
                                )
                              ],
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0,top: 10),
                          child: Text(
                            AppLocalizations.of(context).login_screen_password,
                              style: GoogleFonts.ubuntu(color: Theme.of(context)
                                  .buttonTheme
                                  .colorScheme
                                  .primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                height: 36,
                                child: TextField(
                                  controller: _passwordController,
                                  autofocus: false,
                                  obscureText: true,
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  decoration:
                                      InputDecorations.buildInputDecoration_1(
                                          hint_text: "• • • • • • • •"),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return PasswordForget();
                                  }));
                                },
                                child: Text(
                                    AppLocalizations.of(context).login_screen_forgot_password,
                                  style: TextStyle(
                                      color: MyTheme.accent_color,
                                      fontStyle: FontStyle.italic,
                                      decoration: TextDecoration.underline),
                                ),
                              )
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: RaisedButton(
                            onPressed:  onPressedLogin,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40.0)),
                            padding: EdgeInsets.all(0.0),
                            child: Ink(
                              decoration: BoxDecoration(

                                  borderRadius: BorderRadius.circular(30.0)
                              ),
                              child: Container(
                                constraints: BoxConstraints(maxWidth: 300.0, minHeight: 50.0),
                                alignment: Alignment.center,
                                child: Text(
                                  "Log In",
                                  textAlign: TextAlign.center,
                                  style:GoogleFonts.ubuntu(color:Colors.white,fontSize: 20 ),
                                ),
                              ),
                            ),
                          ),
                        ),



                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Center(
                              child: Text(
                                AppLocalizations.of(context).login_screen_or_create_new_account,
                            style: TextStyle(
                                color: MyTheme.medium_grey, fontSize: 12),
                          )),
                        ),


                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: RaisedButton(
                            onPressed:  (){
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                    return Registration();
                                  }));
                            },
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                            padding: EdgeInsets.all(0.0),
                            child: Ink(
                              decoration: BoxDecoration(

                                  borderRadius: BorderRadius.circular(10.0)
                              ),
                              child: Container(
                                constraints: BoxConstraints(maxWidth: 300.0, minHeight: 50.0),
                                alignment: Alignment.center,
                                child: Text(
                                  "Sign Up",
                                  textAlign: TextAlign.center,
                                  style:GoogleFonts.ubuntu(color:Colors.white,fontSize: 20 ),
                                ),
                              ),
                            ),
                          ),
                        ),



                        Visibility(
                          visible: allow_google_login.$ ||
                              allow_facebook_login.$,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Center(
                                child: Text(
                                  AppLocalizations.of(context).login_screen_login_with,
                              style: TextStyle(
                                  color: MyTheme.medium_grey, fontSize: 14),
                            )),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 30.0),
                          child: Center(
                            child: Container(
                              width: 120,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Visibility(
                                    visible: allow_google_login.$,
                                    child: InkWell(
                                      onTap: () {
                                        onPressedGoogleLogin();
                                      },
                                      child: Container(
                                        width: 28,
                                        child:
                                            Image.asset("assets/google_logo.png"),
                                      ),
                                    ),
                                  ),
                                  Visibility(
                                    visible: allow_facebook_login.$,
                                    child: InkWell(
                                      onTap: () {
                                        onPressedFacebookLogin();
                                      },
                                      child: Container(
                                        width: 28,
                                        child: Image.asset(
                                            "assets/facebook_logo.png"),
                                      ),
                                    ),
                                  ),
                                  Visibility(
                                    visible: allow_twitter_login.$,
                                    child: InkWell(
                                      onTap: () {
                                         onPressedTwitterLogin();
                                      },
                                      child: Container(
                                        width: 28,
                                        child: Image.asset(
                                            "assets/twitter_logo.png"),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              )),
            )
          ],
        ),
      ),
    );
  }
}
