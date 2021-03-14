import 'package:flutter/material.dart';

import 'BookIndex.dart';
import 'LibIndex.dart';
import 'ShowMarkDown.dart';

class IndexFrame extends StatefulWidget {


  List<Widget> showPageList=[
    ShowMarkDown(),
    BookIndex(),
    LibIndex(),
  ];
  IndexFrame() {
  }
  @override
  State<StatefulWidget> createState() {
    return IndexFrameState();
  }
}

class IndexFrameState extends State<IndexFrame> {
  int showPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: this.widget.showPageList[showPageIndex],
      bottomNavigationBar: BottomNavigationBar(
        // type: BottomNavigationBarType.shifting,
        // showSelectedLabels: false,
        // showUnselectedLabels: false,
        // selectedFontSize: 0,
        // unselectedFontSize: 0,
        unselectedItemColor: Colors.black45,
        selectedItemColor: Colors.black45,
        currentIndex: showPageIndex,
        onTap: (index) {
          setState(() {
            showPageIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
              icon: Image.asset(
                "./assets/redb.png",
                width: 36,
              ),
              label: "Show"),
          BottomNavigationBarItem(
              icon: Image.asset(
                "./assets/redsb.png",
                width: 36,
              ),
              label: "Index"),
          BottomNavigationBarItem(
              icon: Image.asset(
                "./assets/blues.png",
                width: 36,
              ),
              label: "Lib"),
        ],
      ),
    );
  }
}
