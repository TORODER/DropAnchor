import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:drop_anchor/tool/security_set_state.dart';
import 'device_local_storage_tree.dart';
import 'lib_index.dart';
import 'setting.dart';
import 'show_mark_down.dart';

class IndexFrame extends StatefulWidget {
  final List<Widget> showPageList = [
    ShowMarkdown(),
    LibIndex(),
    DeviceLocalStorageTree(),
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
  // late TabController tabController;
  int activeIndex = 1;

  IndexFrameState() {
    // tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 120,
            color: Colors.white,
            child: Column(

              children: [
                "Show",
                "Lib",
                "Local",
                "Setting",
              ]
                  .asMap()
                  .map(
                    (index, e) => MapEntry(
                      index,
                      SizedBox(
                        height: 50,
                        child: InkWell(
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.only(left: 20),
                              child: Text(
                                e,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              width: double.infinity,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              activeIndex = index;
                            });
                          },
                        ),
                      ),
                    ),
                  )
                  .values
                  .toList(),
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          ),
          Expanded(
            child: widget.showPageList[activeIndex],
          ),
        ],
      ),
    );
  }
}

// TabBar(
//               labelColor: Colors.black87,
//               unselectedLabelColor: Colors.black54,
//               controller: tabController,
//               indicatorWeight: 3.0,
//               unselectedLabelStyle: TextStyle(fontSize: 12.0),
//               tabs: [
//                 FittedBox(
//                   child: Row(
//                     children: [
//                       FittedBox(
//                         child: const Text(
//                           "Show",
//                           style: TextStyle(fontSize: 16),
//                         ),
//                       ),
//                     ],
//                     mainAxisSize: MainAxisSize.min,
//                   ),
//                 ),
//                 FittedBox(
//                   child: Row(
//                     children: [
//                       FittedBox(
//                         child: const Text(
//                           "Lib",
//                           style: TextStyle(fontSize: 14),
//                         ),
//                       )
//                     ],
//                     mainAxisSize: MainAxisSize.min,
//                   ),
//                 ),
//                 FittedBox(
//                     child: Row(
//                   children: [
//                     FittedBox(
//                       child: const Text(
//                         "Local",
//                         style: TextStyle(fontSize: 16),
//                       ),
//                     ),
//                   ],
//                   mainAxisSize: MainAxisSize.min,
//                 )),
//                 FittedBox(
//                   child: Row(
//                     children: [
//                       FittedBox(
//                         child: const Text(
//                           "Setting",
//                           style: TextStyle(fontSize: 16),
//                         ),
//                       ),
//                     ],
//                     mainAxisSize: MainAxisSize.min,
//                   ),
//                 ),
//               ],
//             )
