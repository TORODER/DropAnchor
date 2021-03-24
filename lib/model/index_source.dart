import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class IndexSource {
  int type;
  String name;
  late final IndexSource? parent;
  late List<IndexSource> child;
  late bool isOpenChildList = false;
  IndexSource(this.type, this.name, dynamic child,{required this.parent}) {
    final listChild = List<Map<String, dynamic>>.from(child ?? [])
        .map((e) => IndexSource(e["type"], e["name"], e["child"],parent: this))
        .toList();
    this.child = listChild;
  }

  String getCompletePath(){
    IndexSource? nowIndexSourceTarget = this;
    var pathSlice=<String>[nowIndexSourceTarget.name];
    while(nowIndexSourceTarget!.parent!=null){
      nowIndexSourceTarget=nowIndexSourceTarget.parent;
      if(nowIndexSourceTarget!.parent!=null){
        pathSlice.add(nowIndexSourceTarget.name);
      }
    }
    return "/${pathSlice.reversed.toList().join("/")}";
  }


  static IndexSource helperCreate(dynamic indexRaw,{required IndexSource? parent}) {
    final indexMap = Map<String, dynamic>.from(indexRaw);
    return IndexSource(
      indexMap["type"],
      indexMap["name"],
      indexMap["child"] ?? [],
      parent: parent,
    );
  }
}

Widget indexSourceTypeLogo(int type, {int typeState = 0}) {
  switch (type) {
    case 0:
      {
        switch (typeState) {
          case 1:
            return Image.asset("assets/open_folder.png");
          case 0:
          default:
            return Image.asset("assets/folder.png");
        }
      }
    case 1:
      return Image.asset("assets/blueb.png");
  }
  return Text("NullType");
}
