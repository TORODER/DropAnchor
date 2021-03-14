import 'package:flutter/material.dart';
import 'package:drop_anchor/data.dart';
import 'package:drop_anchor/model/ServerSource.dart';

class LibIndex extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return LibIndexState();
  }
}

class LibIndexState extends State<LibIndex> {
  Widget createAutoInput({
    String preText = '',
    bool showEdit = false,
    bool useStatic = true,
    TextEditingController? textEditingController,
    TextStyle? textStyle,
  }) {
    return StatefulBuilder(
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
    return Card(
      child: Stack(
        children: [
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                createAutoInput(
                    showEdit: true,
                    textEditingController: AppDataSourceElem
                        .listServerNameConMap[sourceElem.source]!['editName'],
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    )),
                createAutoInput(
                  textEditingController:
                      TextEditingController(text: '源: ' + sourceElem.source),
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
                    child: SizedBox(
                      child: ElevatedButton(
                        onPressed: () {},
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
                  ),
                )
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: PopupMenuButton<Function>(
              padding: EdgeInsets.all(0),
              onSelected: (f) {
                f();
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  child: Text('删除'),
                  height: 25,
                  value: () {
                    AppDataSourceElem.deleteServer(sourceElem).then(
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
          ),
        ],
      ),
      elevation: 5,
      shadowColor: Colors.black38,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(1))),
    );
  }

  Widget showMainView() {
    return Scaffold(
      appBar: AppBar(
        title: Text("文库"),
      ),
      body: ListView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
        children: [
          ...AppDataSourceElem.listServer
              .map(
                (e) => createLibCard(e, AppDataSourceElem),
              )
              .toList()
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (bc) {
              return AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(),
                  ],
                ),
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AppDataSourceElem.initState,
      builder: (bc, nowState) {
        if (nowState.hasError) {
          return Center(
            child: Text(nowState.error.toString()),
          );
        }
        switch (nowState.connectionState) {
          case ConnectionState.done:
            return showMainView();
          default:
            return Center(
              child: CircularProgressIndicator(),
            );
        }
      },
    );
  }
}
