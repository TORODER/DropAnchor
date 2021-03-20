import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class IndexSource {
  int type;
  String name;
  late List<IndexSource> child;
  late bool isOpenChildList = false;

  IndexSource(this.type, this.name, dynamic child) {
    final listChild =
        List<Map<String, dynamic>>.from(child ?? [])
            .map((e) => IndexSource(e["type"], e["name"], e["child"]))
            .toList();
    this.child = listChild;
  }

  static IndexSource createIndexSource(dynamic indexRaw) {
    final indexMap = Map<String, dynamic>.from(indexRaw);
    return IndexSource(
      indexMap["type"],
      indexMap["name"],
      indexMap["child"] ?? [],
    );
  }
}

Widget indexSourceTypeLogo(int type) {
  switch (type) {
    case 0:
      return Image.asset("assets/blueg.png");
    case 1:
      return Image.asset("assets/blueb.png");
  }
  return Text("NullType");
}
