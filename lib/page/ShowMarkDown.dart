import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../mddata.dart';

class ShowMarkDown extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ShowMarkDownState();
  }
}

class ShowMarkDownState extends State<ShowMarkDown> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('is MarkDown Title'),
      ),
      body: Markdown(
        data: v1mdstr,
        physics: BouncingScrollPhysics(),
      ),
    );
  }
}
