import 'package:drop_anchor/widget/textField/FreeTextField.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

class EditState with ChangeNotifier, DiagnosticableTreeMixin {
  late TextEditingController textEditingController;

  EditState() {
    textEditingController = new TextEditingController();
  }
}

class Edit extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (bc) => EditState())],
      child: StatefulBuilder(
        builder: (bc, ns) => Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    AppBar(
                      title: SizedBox(
                        height: 30,
                        child: ListView(
                          shrinkWrap: true,
                          children: [Text("123123")],
                          scrollDirection: Axis.horizontal,
                        ),
                      ),
                      actions: [
                        Column(
                          children: [
                            PopupMenuButton<Function>(
                              offset: Offset(-5, 15),
                              padding: EdgeInsets.all(5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  1,
                                ),
                              ),
                              itemBuilder: (bc) {
                                return [
                                  ...[
                                    {
                                      "content": Text("保存到服务器"),
                                      "icon": Padding(
                                        child: Image.asset(
                                          "assets/saveblue.png",
                                          width: 18,
                                          height: 18,
                                        ),
                                        padding: EdgeInsets.fromLTRB(
                                          0,
                                          0,
                                          10,
                                          0,
                                        ),
                                      ),
                                      "value": () {
                                        print("save");
                                      }
                                    },
                                    {
                                      "content": Text("保存到本地"),
                                      "icon": Padding(
                                        child: Image.asset(
                                          "assets/saveblue.png",
                                          width: 18,
                                          height: 18,
                                        ),
                                        padding: EdgeInsets.fromLTRB(
                                          0,
                                          0,
                                          10,
                                          0,
                                        ),
                                      ),
                                      "value": () {
                                        print("save");
                                      }
                                    }
                                  ]
                                      .map((e) => PopupMenuItem(
                                            value: e["value"] as Function,
                                            height: 25,
                                            child: Container(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  e["icon"] as Widget,
                                                  e["content"] as Widget,
                                                ],
                                              ),
                                              constraints: BoxConstraints(
                                                minWidth: 100,
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                vertical: 7,
                                              ),
                                            ),
                                          ))
                                      .toList()
                                ];
                              },
                              onSelected: (callbackFunc) {
                                callbackFunc();
                              },
                              child: Image.asset(
                                "assets/menuless.png",
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ],
                          mainAxisAlignment: MainAxisAlignment.center,
                        ),
                        SizedBox(
                          width: 15,
                        ),
                      ],
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: FreeTextField(
                          scrollPhysics: BouncingScrollPhysics(),
                          decoration: InputDecoration(border: InputBorder.none),
                          controller:
                              bc.read<EditState>().textEditingController,
                          maxLines: null,
                        ),
                      ),
                    ),
                  ],
                ),
                Align(
                  child: Container(
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black38,
                          offset: Offset(0, 1),
                          blurRadius: 1,
                        ),
                      ],
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ..."#<>/\"\`[]|\\|{}-=".split("").map(
                              (e) => Container(
                                width: 30,
                                height: 30,
                                child: Material(
                                  child: IconButton(
                                    iconSize: 10,
                                    padding: EdgeInsets.all(0),
                                    icon: FittedBox(
                                      child: Text(
                                        e,
                                        style: TextStyle(
                                          fontSize: 24,
                                        ),
                                      ),
                                    ),
                                    onPressed: () {
                                      final TextEditingController textEditing =
                                          bc
                                              .read<EditState>()
                                              .textEditingController;
                                      final startIndex = max(
                                        min(textEditing.selection.baseOffset,
                                            textEditing.selection.extentOffset),
                                        0,
                                      );
                                      final endIndex = max(
                                        max(textEditing.selection.baseOffset,
                                            textEditing.selection.extentOffset),
                                        0,
                                      );
                                      final contentList =
                                          textEditing.text.split("");
                                      final startString =
                                          contentList.sublist(0, startIndex);
                                      final endString =
                                          contentList.sublist(endIndex);
                                      final resString = [
                                        ...startString,
                                        ...e.split(""),
                                        ...endString
                                      ].join("");
                                      textEditing.text = resString;
                                      textEditing.selection = TextSelection(
                                        baseOffset: startIndex + e.length,
                                        extentOffset: startIndex + e.length,
                                      );
                                      bc.read<EditState>().notifyListeners();
                                    },
                                  ),
                                ),
                                padding: EdgeInsets.all(4),
                              ),
                            ),
                      ],
                    ),
                  ),
                  alignment: Alignment.bottomCenter,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
