import 'package:active_ecommerce_flutter/helpers/addons_helper.dart';
import 'package:active_ecommerce_flutter/helpers/auth_helper.dart';
import 'package:active_ecommerce_flutter/helpers/business_setting_helper.dart';
import 'package:active_ecommerce_flutter/other_config.dart';
import 'package:active_ecommerce_flutter/theme/appThemes.dart';
import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/screens/splash.dart';
import 'package:shared_value/shared_value.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'dart:async';
import 'app_config.dart';
import 'package:active_ecommerce_flutter/services/push_notification_service.dart';
import 'package:one_context/one_context.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:active_ecommerce_flutter/providers/locale_provider.dart';
import 'lang_config.dart';
import 'package:firebase_core/firebase_core.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  print("app_mobile_language.1isEmpty${app_mobile_language.$.isEmpty}");
  AddonsHelper().setAddonsData();
  BusinessSettingHelper().setBusinessSettingData();
  app_language.load();
  app_mobile_language.load();
  app_language_rtl.load();

  access_token.load().whenComplete(() {
    AuthHelper().fetch_and_set();
  });

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  runApp(
    SharedValue.wrapApp(
      MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    if (OtherConfig.USE_PUSH_NOTIFICATION) {
      Future.delayed(Duration(milliseconds: 100), () async {
        PushNotificationService().initialise();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = Theme.of(context).textTheme;

    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ],
        child: Consumer<LocaleProvider>(builder: (context, provider, snapshot) {
          return DynamicTheme(
              themeCollection: themeCollection,
              defaultThemeId: AppThemes.Default,
              builder: (context, theme) {
                return Container(
                  child:  MaterialApp(
                    builder: OneContext().builder,
                    navigatorKey: OneContext().navigator.key,
                    title: AppConfig.app_name,
                    debugShowCheckedModeBanner: false,
                    theme: theme,
                    localizationsDelegates: [
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                      AppLocalizations.delegate,
                    ],
                    locale: provider.locale,
                    supportedLocales: LangConfig().supportedLocales(),
                    home: Splash(),
                    //home: Main(),
                  )
                );
              });
        }));
  }
}
