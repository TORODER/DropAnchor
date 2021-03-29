import 'package:drop_anchor/model/server_source.dart';
import 'package:drop_anchor/state/data.dart';
import 'package:drop_anchor/tool/security_set_state.dart';
import 'package:drop_anchor/widget/free_expansion_panel_list.dart';
import 'package:flutter/material.dart';
import 'package:drop_anchor/model/index_source.dart';
import 'package:drop_anchor/widget/free_popup_menu_button.dart';

FreeExpansionPanel indexSourceCreateView(IndexSource indexSource,
    {
    ServerSourceBase? useServerSource,
    IndexSource? rootIndexSource}) {
  assert(
    (useServerSource == null && rootIndexSource == null) ||
        (useServerSource != null && rootIndexSource != null),
  );

  // 抹除 local source 和 net source 的 ServerSourceBase 来源差异
  final nowTargetServer = useServerSource ??
      AppDataSource.getOnlyExist.activationIndexSourceManage.serverSource;
  switch (indexSource.type) {
    //DIR
    case 0:
      return FreeExpansionPanel(
        canTapOnHeader: true,
        openStateIcon: Container(),
        closeStateIcon: Container(),
        isExpanded: indexSource.isOpenChildList,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(
            8,
            0,
            0,
            0,
          ),
          child: BookIndex.createLibChild(indexSource.child,
              useServerSource: useServerSource,
              rootIndexSource: rootIndexSource,
              ),
        ),
        headerBuilder: (bc, openState) => FreePopupMenuButton<Function>(
          padding: EdgeInsets.all(0),
          enabled: true,
          offset: Offset(10, 10),
          onSelected: (useF) {
            useF();
          },
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem(
                child: Text("修改名称"),
                value: () {
                  print("修改名称");
                },
              ),
              PopupMenuItem(
                child: Text("添加子文件夹"),
                value: () {
                  print("添加子文件夹");
                },
              ),
              PopupMenuItem(
                child: Text("创建新文件"),
                value: () {
                  print("创建新文件");
                },
              )
            ];
          },
          child: ListTile(
            title: Text(
              indexSource.name,
              style: const TextStyle(fontSize: 16),
            ),
            leading: SizedBox(
              child: indexSourceTypeLogo(indexSource.type,
                  typeState: indexSource.isOpenChildList ? 1 : 0),
              width: 35,
            ),
          ),
        ),
      );
    //FILE
    case 1:
    default:
      return FreeExpansionPanel(
        canTapOnHeader: true,
        openStateIcon: Container(),
        closeStateIcon: Container(),
        headerBuilder: (bc, openState) => PopupMenuButton<Function>(
          onSelected: (selectRunFunc) {
            selectRunFunc();
          },
          itemBuilder: (bc) => [
            PopupMenuItem(
              child: const Text("查看"),
              value: () {
                if (useServerSource != null && rootIndexSource != null) {
                  AppDataSource.getOnlyExist.activationIndexSourceManage
                      .fromLocalReadIndexSource(
                    useServerSource,
                    rootIndexSource: rootIndexSource,
                    showIndexSource: indexSource,
                  );
                }
                AppDataSource.getOnlyExist.activationIndexSourceManage
                    .setShowIndexSource = indexSource;
                AppDataSource.getOnlyExist.notifyListeners();
              },
            ),
            PopupMenuItem(
              child: const Text("修改"),
              value: () {
                print("修改");
              },
            ),
            PopupMenuItem(
              child: const Text("下载"),
              value: () {
                print("下载");
              },
            ),
            PopupMenuItem(
              child: const Text("删除"),
              value: () {
                showDialog(
                    context: bc,
                    builder: (bc) {
                      return AlertDialog(
                        content:
                            Text("是否删除 ${indexSource.getCompletePath()} ?"),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(bc);
                            },
                            child: Text("取消"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: bc,
                                builder: (bc) => FutureBuilder(
                                  future: nowTargetServer!.delete(indexSource),
                                  builder: (bc, futureState) {
                                    if (futureState.connectionState !=
                                        ConnectionState.done) {
                                      return CircularProgressIndicator();
                                    }
                                    Future(() => Navigator.of(bc).pop()).then(
                                        (value) => Navigator.of(bc).pop());
                                    return Container();
                                  },
                                ),
                              );
                            },
                            child: Text("确定"),
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all(Colors.red),
                              textStyle: MaterialStateProperty.all(
                                TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    });
                print("删除");
              },
            ),
          ],
          child: ListTile(
            title: Text(
              indexSource.name,
              style: const TextStyle(fontSize: 16),
            ),
            leading: SizedBox(
              child: indexSourceTypeLogo(indexSource.type),
              width: 35,
            ),
          ),
          offset: const Offset(
            0,
            40,
          ),
        ),
        body: Container(),
      );
  }
}

class BookIndex extends StatelessWidget {
  static Widget createLibChild(List<IndexSource> childData,
      {
      ServerSourceBase? useServerSource,
      IndexSource? rootIndexSource}) {
    return SecurityStatefulBuilder(
      builder: (bc, ns) {
        return Column(
          children: [
            FreeExpansionPanelList(
              elevation: 0,
              expansionCallback: (index, openState) {
                childData[index].isOpenChildList = !openState;
                ns(() => null);
              },
              expandedHeaderPadding: const EdgeInsets.all(0),
              children: childData
                  .map(
                    (e) => indexSourceCreateView(e,
                        useServerSource: useServerSource,
                        rootIndexSource: rootIndexSource,),
                  )
                  .toList(),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rootChild = <IndexSource>[];
    if (AppDataSource
            .getOnlyExist.activationIndexSourceManage.rootIndexSource !=
        null) {
      rootChild.addAll(AppDataSource
          .getOnlyExist.activationIndexSourceManage.rootIndexSource!.child);
    }
    return ListView(
      physics: const BouncingScrollPhysics(),
      shrinkWrap: true,
      children: [
        const SizedBox(
          height: 10,
        ),
        createLibChild(rootChild)
      ],
    );
  }
}
