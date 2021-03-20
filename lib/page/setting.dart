import 'package:flutter/material.dart';

import '../tool/security_set_state.dart';
import 'test_page.dart';

class Setting extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SettingState();
  }
}

class SettingState extends SecurityState<Setting> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        physics: BouncingScrollPhysics(),
        children: [
          // ListTile(leading: Image.asset(""),)
          ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (bc) => TestPage()));
              },
              child: Text("进入接口测试"))
        ],
      ),
    );
  }
}
