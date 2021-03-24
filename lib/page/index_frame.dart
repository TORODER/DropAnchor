import 'package:flutter/material.dart';
import 'package:drop_anchor/tool/security_set_state.dart';
import 'lib_index.dart';
import 'setting.dart';
import 'show_mark_down.dart';

class IndexFrame extends StatefulWidget {
  final List<Widget> showPageList = [
    ShowMarkdown(),
    LibIndex(),
    Setting(),
  ];

  IndexFrame();

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
          children: widget.showPageList,
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
                  height: 1,
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
                  height: 1,
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
                  height: 1,
                ),
                const Text("Setting"),
              ],
              mainAxisSize: MainAxisSize.min,
            )
          ],
        ),
    );
  }
}
