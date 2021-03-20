import 'package:drop_anchor/tool/security_set_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../mddata.dart';
import 'book_index.dart';
import 'edit.dart';

class ShowMarkDown extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ShowMarkDownState();
  }
}

class _ShowMarkDownState extends SecurityState<ShowMarkDown> {
  Widget createDrawer() {
    return Container(
      color: Colors.white,
      width: 275,
      height: double.infinity,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  BookIndex(),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Row(
                    children: [
                      Text(
                        "使用Lib: Name0",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      )
                    ],
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                  )
                ],
              ),
              color: Colors.blue,
              height: 22,
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('is MarkDown Title'),
        actions: [
          IconButton(
            iconSize: 28,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (bc) => Edit(),
                ),
              );
            },
            icon: Image.asset(
              "assets/edit-file.png",
            ),
          ),
          SizedBox(
            width: 10,
          ),
        ],
      ),
      drawer: createDrawer(),
      drawerEdgeDragWidth: 250,
      body: Markdown(
        data: v1mdstr,
        selectable: true,
        physics: BouncingScrollPhysics(),
        onTapLink: (text, href, title) {
          if (href != null) {
            launch(href);
          }
          print([
            text,
            href ?? null,
            title,
          ]);
        },
      ),
    );
  }
}
