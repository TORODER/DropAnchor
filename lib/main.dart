import 'package:drop_anchor/state/device_local_storage.dart';
import 'package:drop_anchor/tool/file_suffix_analysis.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drop_anchor/page/index_frame.dart';

void main() {
  DeviceLocalStorage();
  runApp(
    AppFrame(),
  );
}

class AppFrame extends StatelessWidget {

  /// WhiteMode Build Function
  static ThemeData  get whiteMode =>
      ThemeData(
        primaryColor: Colors.white,
        appBarTheme: AppBarTheme(elevation: 0, shadowColor: Colors.black26),
        primaryTextTheme: TextTheme(
          bodyText1: TextStyle(
            color: Colors.black,
          ),
          bodyText2: TextStyle(
            color: Colors.black,
          ),
        ),
      );

  /// DarkMode Build Function
  /// Experimental function
  static ThemeData  get darkMode =>
      ThemeData.dark();

  @override
  Widget build(BuildContext context) {


    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme:AppFrame.whiteMode,
      home: IndexFrame(),
    );
  }
}
