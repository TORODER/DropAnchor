import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '';

class IndexSource {
  int type;
  String path;
  late List<IndexSource> child;

  IndexSource(this.type, this.path, dynamic child) {
    final List<IndexSource> listChild =
        List<Map<String, dynamic>>.from(child ?? [])
            .map((e) => IndexSource(e["type"], e["path"], e["child"]))
            .toList();
    this.child = listChild;
  }

  Widget createView() {
    return ListTile(
      title: Text(
        this.path,
        style: TextStyle(fontSize: 16),
      ),
      trailing: SizedBox(
        child: typeLogo(this.type),
        width: 40,
      ),

    );
  }

  Widget typeLogo(int type) {
    switch (type) {
      case 0:
        return Image.asset("assets/blueg.png");
      case 1:
        return Image.asset("assets/blueb.png");
    }
    return Text("NullType");
  }

  static IndexSource createIndexSource(dynamic indexRaw) {
    final IndexMap = Map<String, dynamic>.from(indexRaw);
    return IndexSource(
        IndexMap["type"], IndexMap["path"], IndexMap["child"] ?? []);
  }
}
