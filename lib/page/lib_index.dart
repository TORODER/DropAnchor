import 'package:drop_anchor/page/book_index.dart';
import 'package:drop_anchor/tool/security_set_state.dart';
import 'package:drop_anchor/tool/text_input_filter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:drop_anchor/state/data.dart';
import 'package:drop_anchor/model/server_source.dart';
import 'package:flutter/services.dart';

class LibIndex extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return LibIndexState();
  }
}

class LibIndexState extends SecurityState<LibIndex> {
  Widget createAutoInput({
    String preText = '',
    bool showEdit = false,
    bool useStatic = true,
    TextEditingController? textEditingController,
    TextStyle? textStyle,
  }) {
    return SecurityStatefulBuilder(
        builder: (bc, ns) => FittedBox(
              child: Container(
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        child: TextField(
                          controller: textEditingController,
                          style: textStyle,
                          decoration: InputDecoration(
                            enabled: useStatic,
                            contentPadding: EdgeInsets.fromLTRB(1, 0, 10, 12),
                            prefixText: preText,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    showEdit
                        ? SizedBox(
                            child: RawMaterialButton(
                              padding: EdgeInsets.all(5),
                              child: Image.asset(
                                "assets/pen.png",
                              ),
                              onPressed: () => ns(() => useStatic = !useStatic),
                            ),
                            width: 30,
                            height: 30,
                          )
                        : Container()
                  ],
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black26,
                      width: 0.5,
                    ),
                  ),
                ),
                width: 180,
                height: 32,
              ),
            ));
  }

  Widget createLibCard(ServerSource sourceElem, AppDataSource appDataSource) {
    return Container(
      child: Material(
        color: Colors.white,
        child: InkWell(
          onLongPress: () {},
          child: Card(
            elevation: 0,
            color: Colors.transparent,
            child: Stack(
              children: [
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      createAutoInput(
                        showEdit: true,
                        textEditingController: appDataSource
                                .manageRemoteServer.listServerNameConMap[
                            sourceElem.token()]!['editName'],
                        textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      createAutoInput(
                        textEditingController: TextEditingController(
                            text: '源: ${sourceElem.source}'),
                        textStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w400,
                        ),
                        useStatic: false,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      ElevatedButtonTheme(
                        data: ElevatedButtonThemeData(
                          style: ButtonStyle(
                            elevation: MaterialStateProperty.all(0),
                            backgroundColor: MaterialStateProperty.all(
                              Colors.amber,
                            ),
                          ),
                        ),
                        child: FittedBox(
                          child: Row(
                            children: [
                              SizedBox(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() => appDataSource
                                            .activationIndexSourceManage
                                            .fromRemoteServer(sourceElem)
                                            .then((value) {
                                          showDialog(
                                            context: context,
                                            builder: (bc) => AlertDialog(
                                              contentPadding: EdgeInsets.all(8),
                                              content: SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.6,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.6,
                                                child: Container(
                                                  child: BookIndex(),
                                                ),
                                              ),
                                            ),
                                          );
                                        }));
                                  },
                                  child: Text('查询'),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 0,
                                      vertical: 0,
                                    ),
                                  ),
                                ),
                                height: 30,
                                width: 100,
                              ),
                              (appDataSource.activationIndexSourceManage
                                              .serverSource) ==
                                          sourceElem &&
                                      (appDataSource.activationIndexSourceManage
                                              .activationLoad) !=
                                          null
                                  ? Container(
                                      margin: EdgeInsets.fromLTRB(
                                        4,
                                        0,
                                        0,
                                        0,
                                      ),
                                      child: FutureBuilder(
                                        future: appDataSource
                                            .activationIndexSourceManage
                                            .activationLoad,
                                        builder: (bc, futureState) {
                                          if (futureState.hasError) {
                                            print(futureState.error);
                                            return Icon(
                                              Icons.close,
                                              color: Colors.red,
                                            );
                                          }
                                          if (futureState.connectionState !=
                                              ConnectionState.done) {
                                            return SizedBox(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            );
                                          }
                                          return Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          );
                                        },
                                      ),
                                      width: 20.5,
                                      height: 20,
                                    )
                                  : Container(),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<Function>(
                        padding: EdgeInsets.all(0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            3,
                          ),
                        ),
                        onSelected: (f) {
                          f();
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: Text('删除'),
                            height: 25,
                            value: () {
                              appDataSource.manageRemoteServer
                                  .deleteServer(sourceElem)
                                  .then(
                                    (value) => setState(() => null),
                                  );
                            },
                          ),
                        ],
                        child: Image.asset(
                          "assets/menu.png",
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(1))),
          ),
        ),
      ),
      decoration: BoxDecoration(color: Colors.white),
    );
  }

  Widget createAddLib(AppDataSource appDataSource) {
    var nameController = TextEditingController();
    var sourceController = TextEditingController();
    var portController = TextEditingController();
    Function? updateButtonState;
    return AlertDialog(
      actions: [
        Container(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                child: Row(
                  children: [
                    Image.asset(
                      "assets/blues.png",
                      height: 40,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Text(
                      "创建库链接",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                  mainAxisAlignment: MainAxisAlignment.start,
                ),
              ),
              ...[
                {
                  "Label": "名字",
                  "Controller": nameController,
                  "OnChanged": (e) {
                    print(updateButtonState);
                    (updateButtonState ?? () => {})();
                  },
                  "KeyboardType": TextInputType.text
                },
                {
                  "Label": "来源",
                  "Controller": sourceController,
                  "OnChanged": (e) {
                    print(updateButtonState);
                    (updateButtonState ?? () => {})();
                  },
                  "KeyboardType": TextInputType.text
                },
                {
                  "Label": "端口",
                  "Controller": portController,
                  "OnChanged": (e) {
                    (updateButtonState ?? () => {})();
                  },
                  "KeyboardType": TextInputType.number,
                  "InputFilter": inputNumberFilter
                },
              ]
                  .map((e) => Container(
                        height: 40,
                        child: Row(
                          children: [
                            Text(e["Label"] as String),
                            SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: SizedBox(
                                child: TextField(
                                  inputFormatters: e["InputFilter"] != null
                                      ? [e["InputFilter"] as TextInputFormatter]
                                      : [],
                                  controller:
                                      e["Controller"] as TextEditingController,
                                  keyboardType:
                                      e["KeyboardType"] as TextInputType,
                                  onChanged:
                                      e["OnChanged"] as ValueChanged<String>,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.fromLTRB(
                                      5,
                                      0,
                                      0,
                                      20,
                                    ),
                                    border: InputBorder.none,
                                    filled: true,
                                  ),
                                ),
                                height: 30,
                              ),
                            )
                          ],
                        ),
                      ))
                  .toList(),
              SecurityStatefulBuilder(builder: (bc, ns) {
                updateButtonState = () => ns(() => null);
                return Container(
                  width: double.infinity,
                  height: 45,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton(
                    onPressed: nameController.text.isNotEmpty &&
                            sourceController.text.isNotEmpty &&
                            portController.text.isNotEmpty
                        ? () {
                            final name = nameController.text;
                            final source = sourceController.text;
                            final port = int.parse(portController.text);
                            appDataSource.manageRemoteServer.addServer(
                              name,
                              source,
                              port,
                            );
                            setState(() {});
                            Navigator.pop(context);
                          }
                        : null,
                    child: Text("创建"),
                    style: ButtonStyle(
                      elevation: MaterialStateProperty.all(0),
                    ),
                  ),
                );
              })
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 8,
          ),
        ),
      ],
    );
  }

  Widget showMainView(AppDataSource appDataSource) {
    return Scaffold(
      appBar: AppBar(
        title: Text("文库"),
      ),
      body: ListView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
        children: [
          ...appDataSource.manageRemoteServer.listServer
              .map(
                (e) => createLibCard(e, appDataSource),
              )
              .toList()
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (bc) {
              return createAddLib(appDataSource);
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppDataSource>(
      future: AppDataSource.getOnlyExist.initState,
      builder: (bc, futureState) {
        if (futureState.hasError) {
          return Center(
            child: Text(futureState.error.toString()),
          );
        }
        switch (futureState.connectionState) {
          case ConnectionState.done:
            return showMainView(futureState.data!);
          default:
            return Center(
              child: CircularProgressIndicator(),
            );
        }
      },
    );
  }
}
