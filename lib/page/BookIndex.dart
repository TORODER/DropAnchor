import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:drop_anchor/model/IndexSource.dart';
import '../mddata.dart';

IndexSource getIndex() {
  final deres = jsonDecode(bookPaht);
  return IndexSource.createIndexSource(deres);
}

class BookIndex extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return BookIndexState();
  }
}

class BookIndexState extends State<BookIndex> {
  late IndexSource startIndexSource;
  late IndexSource rootSource;
  late List<String> path;
  static String separatorChar = '/';

  BookIndexState() {
    path = [];
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    startIndexSource = getIndex();
    rootSource = startIndexSource;
  }

  IndexSource goInPath(List<String> startP) {
    final goPathList = startP;
    var nowNode = rootSource;
    if (goPathList.last == '..') {
      goPathList.removeLast();
      goPathList.removeLast();
    }
    for (int i = 0; i < goPathList.length; i++) {
      for (int ii = 0; ii < nowNode.child.length; ii++) {
        if (nowNode.child[ii].path == goPathList[i]) {
          nowNode = nowNode.child[ii];
          break;
        }
        if (ii == nowNode.child.length) {
          print(
              'no find ${goPathList.join('/')}\nnow path ${goPathList.sublist(0, i).join('/')}');
          return nowNode;
        }
      }
    }
    return nowNode;
  }

  @override
  Widget build(BuildContext context) {
    print(path);
    List<IndexSource> iss = [];
    if (path.isNotEmpty) {
      iss.add(IndexSource(0, "..", []));
    }
    iss.addAll(startIndexSource.child);
    return Scaffold(
      appBar: AppBar(
        title: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Text("/${path.join("/")}"),
          width: double.infinity,
        ),
        actions: [
          SizedBox(
            width: 30,
            child: Image.asset(
              "assets/infoi.png",
            ),
          ),
          SizedBox(
            width: 20,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              physics: BouncingScrollPhysics(),
              children: iss
                     .map(
                    (e) => InkWell(
                      child: e.createView(),
                      onTap: () {
                        switch (e.type) {
                          case 0:
                            setState(() {
                              path.add(e.path);
                              startIndexSource = goInPath(path);
                            });
                            break;
                          case 1:
                            break;
                        }
                      },
                    ),
                  )
                  .toList(),
            ),
          )
        ],
      ),
    );
  }
}
