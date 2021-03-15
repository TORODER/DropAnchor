import 'package:drop_anchor/tool/SecuritySetState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../mddata.dart';

class ShowMarkDown extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ShowMarkDownState();
  }
}

class ShowMarkDownState extends SecurityState<ShowMarkDown> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('is MarkDown Title'),
      ),
      drawer: Container(
        color: Colors.white,
        width: 300,
        height: double.infinity,
        child: Column(
          children: [],
        ),
      ),
      body: Markdown(
        data: v1mdstr,
        selectable: true,
        physics: BouncingScrollPhysics(),
        onTapLink: (String text, String? href, String title) {
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
