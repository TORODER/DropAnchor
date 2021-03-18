import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class IndexSource {
  int type;
  String name;
  late List<IndexSource> child;
  late bool isOpenChildList = false;

  IndexSource(this.type, this.name, dynamic child) {
    final List<IndexSource> listChild =
        List<Map<String, dynamic>>.from(child ?? [])
            .map((e) => IndexSource(e["type"], e["name"], e["child"]))
            .toList();
    this.child = listChild;
  }

  static IndexSource createIndexSource(dynamic indexRaw) {
    final IndexMap = Map<String, dynamic>.from(indexRaw);
    return IndexSource(
      IndexMap["type"],
      IndexMap["name"],
      IndexMap["child"] ?? [],
    );
  }
}

Widget IndexSourceTypeLogo(int type) {
  switch (type) {
    case 0:
      return Image.asset("assets/blueg.png");
    case 1:
      return Image.asset("assets/blueb.png");
  }
  return Text("NullType");
}
