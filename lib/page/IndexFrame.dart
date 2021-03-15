import 'package:flutter/material.dart';

import 'BookIndex.dart';
import 'LibIndex.dart';
import 'ShowMarkDown.dart';

class IndexFrame extends StatefulWidget {
  List<Widget> showPageList = [
    ShowMarkDown(),
    BookIndex(),
    LibIndex(),
    Scaffold(),
  ];

  IndexFrame() {}

  @override
  State<StatefulWidget> createState() {
    return IndexFrameState();
  }
}

class IndexFrameState extends State<IndexFrame> {
  int showPageIndex = 0;
  late PageController pageController;
  Function? setBottomBarState;

  IndexFrameState() {
    pageController = PageController(initialPage: showPageIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PageView(
          controller: pageController,
          children: this.widget.showPageList,
          onPageChanged: (index) {
            showPageIndex = index;
            (setBottomBarState ?? () => null)();
          },
        ),
        bottomNavigationBar: StatefulBuilder(
          builder: (bc, ns) {
            setBottomBarState = () => ns(() => null);
            return BottomNavigationBar(
              // type: BottomNavigationBarType.shifting,
              // showSelectedLabels: false,
              // showUnselectedLabels: false,
              // selectedFontSize: 0,
              // unselectedFontSize: 0,
              type: BottomNavigationBarType.fixed,
              unselectedItemColor: Colors.black45,
              selectedItemColor: Colors.black45,
              currentIndex: showPageIndex,
              onTap: (index) {
                showPageIndex = index;
                pageController.animateToPage(
                  showPageIndex,
                  curve: Curves.ease,
                  duration: Duration(milliseconds: 500),
                );
                (setBottomBarState ?? () => null)();
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
                BottomNavigationBarItem(
                    icon: Image.asset(
                      "./assets/setting.png",
                      width: 36,
                    ),
                    label: "Setting"),
              ],
            );
          },
        ));
  }
}
