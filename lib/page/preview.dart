import 'dart:convert';

import 'package:drop_anchor/model/file_type.dart';
import 'package:drop_anchor/tool/security_set_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class PreView extends StatefulWidget {
  dynamic data;
  int fileType;

  PreView(this.data, {required this.fileType});

  @override
  State<StatefulWidget> createState() {
    return PreViewState();
  }
}

class PreViewState extends SecurityState<PreView> {
  @override
  Widget build(BuildContext context) {
    Widget viewContent;
    switch (widget.fileType) {
      case FileType.MARKDOWN:
        if (widget.data is String) {
          viewContent = Markdown(
            data: widget.data,
          );
        } else {
          viewContent = Markdown(
            data: utf8.decode(widget.data),
          );
        }

        break;
      case FileType.TEXT:
        if (widget.data is String) {
          viewContent = Text(widget.data);
        } else {
          viewContent = Text(utf8.decode(widget.data));
        }
        break;

      case FileType.UNDEFINITION:
      default:
        viewContent = Text('不能处理的类型');
        break;
    }
    return Scaffold(
      body: viewContent,
    );
  }
}
