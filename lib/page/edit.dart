import 'dart:convert';
import 'dart:math';

import 'package:drop_anchor/model/index_source.dart';
import 'package:drop_anchor/model/remote_data_source.dart';
import 'package:drop_anchor/model/server_source.dart';
import 'package:drop_anchor/page/preview.dart';
import 'package:drop_anchor/tool/security_set_state.dart';
import 'package:drop_anchor/widget/textField/free_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditState with ChangeNotifier, DiagnosticableTreeMixin {
  late TextEditingController textEditingControllerContent;
  late TextEditingController textEditingControllerTitle;
  late String editDocName;

  EditState({required String name, required String content}) {
    textEditingControllerContent = TextEditingController();
    textEditingControllerTitle = TextEditingController();
    textEditingControllerContent.text = content;
    textEditingControllerTitle.text = name;
  }
}

class Edit extends StatelessWidget {
  IndexSource fromIndexSource;

  ServerSource fromServerSource;

  Edit({required this.fromIndexSource, required this.fromServerSource});

  bool preview = false;

  Widget createEditBody(Iterable<int> data) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (bc) => EditState(
            name: fromIndexSource.name,
            content: utf8.decode(List<int>.from(data)),
          ),
        )
      ],
      child: SecurityStatefulBuilder(
        builder: (bc, ns) => Scaffold(
          body:  !preview
              ? Stack(
            children: [
              Column(
                children: [
                  AppBar(
                    title: SizedBox(
                      child: TextField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                        ),
                        scrollPadding: EdgeInsets.fromLTRB(
                          8,
                          4,
                          0,
                          12,
                        ),
                        controller: bc
                            .read<EditState>()
                            .textEditingControllerTitle,
                      ),
                    ),
                    actions: [
                      Column(
                        children: [
                          createOperationMenu(
                              controller: bc
                                  .read<EditState>()
                                  .textEditingControllerContent),
                        ],
                        mainAxisAlignment: MainAxisAlignment.center,
                      ),
                      SizedBox(
                        width: 15,
                      ),
                    ],
                  ),
                  Expanded(
                    child: Scrollbar(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 4,
                            ),
                            child: TextField(
                              onChanged: (v) {},
                              scrollPhysics:
                              const BouncingScrollPhysics(),
                              decoration: InputDecoration(
                                  border: InputBorder.none),
                              controller: bc
                                  .read<EditState>()
                                  .textEditingControllerContent,
                              maxLines: null,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
              : PreView(
              bc.read<EditState>().textEditingControllerContent.text,
              fileType: fromIndexSource.fileType),
          bottomNavigationBar: Container(
            constraints: BoxConstraints(maxHeight: 35,maxWidth: double.infinity),
            margin: const EdgeInsets.symmetric(horizontal: 2,vertical: 2),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                0,
              ),
            ),
            child: FittedBox(
              child: Row(
                children: [
                  ..."#<>\`[]|\\|{}-".split("").map(
                        (e) => Container(

                      height: 32,
                      child: Material(
                        color: Colors.white,
                        child: IconButton(
                          color: Colors.white,
                          padding: EdgeInsets.all(2),
                          icon: FittedBox(
                            child: Text(
                              e,
                              style: TextStyle(
                                fontSize: 26,
                              ),
                            ),
                          ),
                          onPressed: () {
                            final textEditing = bc
                                .read<EditState>()
                                .textEditingControllerContent;
                            final startIndex = max(
                              min(
                                  textEditing
                                      .selection.baseOffset,
                                  textEditing.selection
                                      .extentOffset),
                              0,
                            );
                            final endIndex = max(
                              max(
                                  textEditing
                                      .selection.baseOffset,
                                  textEditing.selection
                                      .extentOffset),
                              0,
                            );
                            final contentList =
                            textEditing.text.split("");
                            final startString = contentList
                                .sublist(0, startIndex);
                            final endString =
                            contentList.sublist(endIndex);
                            final resString = [
                              ...startString,
                              ...e.split(""),
                              ...endString
                            ].join("");
                            textEditing.text = resString;
                            textEditing.selection =
                                TextSelection(
                                  baseOffset:
                                  startIndex + e.length,
                                  extentOffset:
                                  startIndex + e.length,
                                );
                            bc
                                .read<EditState>()
                                .notifyListeners();
                          },
                        ),
                      ),
                      padding: EdgeInsets.all(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(

            onPressed: () {
              preview = !preview;
              ns(() => null);
            },
            backgroundColor: Colors.white,
            child: Container(
              child: preview
                  ? Image.asset("assets/pen.png")
                  : Image.asset("assets/preview.png"),
              padding: EdgeInsets.all(12),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(future: Future(() async {
        final remoteDataSource = RemoteDataSource.fromIndexSource(
            fromIndexSource,
            fromServerSource: fromServerSource);
        return await remoteDataSource.getState;
      }), builder: (bc, futureState) {
        if (futureState.hasError) {
          print("${futureState.error}");
        }
        if (futureState.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return createEditBody(futureState.data as Iterable<int>);
      }),
    );
  }

  PopupMenuButton<Function> createOperationMenu(
      {required TextEditingController controller}) {
    return PopupMenuButton<Function>(
      offset: const Offset(-5, 15),
      padding: const EdgeInsets.all(5),
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
                padding: const EdgeInsets.fromLTRB(
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
                padding: const EdgeInsets.fromLTRB(
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
              "content": Text("清空"),
              "icon": Padding(
                child: Image.asset(
                  "assets/deletedoc.png",
                  width: 24,
                  height: 24,
                ),
                padding: const EdgeInsets.fromLTRB(
                  0,
                  0,
                  10,
                  0,
                ),
              ),
              "value": () {
                controller.text = "";
                print("delete");
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
                      constraints: const BoxConstraints(
                        minWidth: 100,
                      ),
                      padding: const EdgeInsets.symmetric(
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
    );
  }
}
