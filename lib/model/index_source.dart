import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FsFileType {
  static const int DIR = 0;
  static const int FILE = 1;
}

class IndexSource {
  int type;
  String name;
  late final IndexSource? parent;
  late List<IndexSource> child;
  late bool isOpenChildList = false;
  late final int fileType;

  IndexSource(this.type, this.name, dynamic child,
      {required this.parent, required this.fileType}) {
    final listChild = List<Map<String, dynamic>>.from(child ?? [])
        .map(
          (e) => IndexSource(
            e["type"],
            e["name"],
            e["child"],
            parent: this,
            fileType: e["fileType"],
          ),
        )
        .toList();
    this.child = listChild;
  }

  String getCompletePath() {
    IndexSource? nowIndexSourceTarget = this;
    var pathSlice = <String>[nowIndexSourceTarget.name];
    while (nowIndexSourceTarget!.parent != null) {
      nowIndexSourceTarget = nowIndexSourceTarget.parent;
      if (nowIndexSourceTarget!.parent != null) {
        pathSlice.add(nowIndexSourceTarget.name);
      }
    }
    return "/${pathSlice.reversed.toList().join("/")}";
  }

  static IndexSource helperCreate(dynamic indexRaw,
      {required IndexSource? parent}) {
    final indexMap = Map<String, dynamic>.from(indexRaw);
    return IndexSource(
      indexMap["type"],
      indexMap["name"],
      indexMap["child"] ?? [],
      parent: parent,
      fileType: indexMap["fileType"],
    );
  }
}

Widget indexSourceTypeLogo(int type, {int typeState = 0}) {
  switch (type) {
    case FsFileType.DIR:
      {
        switch (typeState) {
          case 1:
            return Image.asset("assets/open_folder.png");
          case 0:
          default:
            return Image.asset("assets/folder.png");
        }
      }
    case FsFileType.FILE:
      return Image.asset("assets/bookred.png");
  }
  TextField;
  return const Text("NullType");
}
