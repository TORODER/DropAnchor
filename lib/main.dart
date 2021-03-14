import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drop_anchor/page/IndexFrame.dart';
import 'package:drop_anchor/data.dart';
void main() {
  runApp(AppFrame());
}

class AppFrame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark),
    );
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.white,
        appBarTheme: AppBarTheme(elevation: 3,shadowColor: Colors.black26),
        primaryTextTheme: TextTheme(
          bodyText1: TextStyle(
            color: Colors.black,
          ),
          bodyText2: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
      home: IndexFrame(),
    );
  }
}
