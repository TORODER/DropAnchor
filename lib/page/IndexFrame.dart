import 'package:flutter/material.dart';
import 'package:drop_anchor/tool/SecuritySetState.dart';
import 'BookIndex.dart';
import 'LibIndex.dart';
import 'Setting.dart';
import 'ShowMarkDown.dart';

class IndexFrame extends StatefulWidget {
  List<Widget> showPageList = [
    ShowMarkDown(),
    LibIndex(),
    Setting(),
  ];

  IndexFrame() {}

  @override
  State<StatefulWidget> createState() {
    return IndexFrameState();
  }
}

class IndexFrameState extends SecurityState<IndexFrame>
    with TickerProviderStateMixin {
  late TabController tabController;

  IndexFrameState() {
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: TabBarView(
          controller: tabController,
          children: this.widget.showPageList,
        ),
        bottomNavigationBar: TabBar(
          labelColor: Colors.black,
          controller: tabController,
          indicatorWeight: 3.0,
          tabs: [
            Column(
              children: [
                Image.asset(
                  "./assets/redb.png",
                  width: 36,
                ),
                const SizedBox(
                  height: 2,
                ),
                const Text("Show"),
              ],
              mainAxisSize: MainAxisSize.min,
            ),
            Column(
              children: [
                Image.asset(
                  "./assets/blues.png",
                  width: 36,
                ),
                const SizedBox(
                  height: 2,
                ),
                const Text("Lib"),
              ],
              mainAxisSize: MainAxisSize.min,
            ),
            Column(
              children: [
                Image.asset(
                  "./assets/setting.png",
                  width: 36,
                ),
                const SizedBox(
                  height: 2,
                ),
                const Text("Setting"),
              ],
              mainAxisSize: MainAxisSize.min,
            )
          ],
        ));
  }
}
