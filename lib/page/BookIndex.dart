import 'package:drop_anchor/data.dart';
import 'package:drop_anchor/widget/FreeExpansionPanelList.dart';
import 'package:flutter/material.dart';
import 'package:drop_anchor/model/IndexSource.dart';
import 'package:provider/provider.dart';

IndexSource goInPath(List<String> startP, IndexSource rootSource) {
  final goPathList = startP;
  var nowNode = rootSource;
  if (goPathList.last == '..') {
    goPathList.removeLast();
    goPathList.removeLast();
  }
  for (int i = 0; i < goPathList.length; i++) {
    for (int ii = 0; ii < nowNode.child.length; ii++) {
      if (nowNode.child[ii].name == goPathList[i]) {
        nowNode = nowNode.child[ii];
        break;
      }
      if (ii == nowNode.child.length) {
        print(
          'no find ${goPathList.join('/')}\nnow name ${goPathList.sublist(0, i).join('/')}',
        );
        return nowNode;
      }
    }
  }
  return nowNode;
}

FreeExpansionPanel indexSourceCreateView(IndexSource indexSource) {
  switch (indexSource.type) {
    case 0:
      return FreeExpansionPanel(
        backgroundColor: Color.fromRGBO(248, 248, 248, 0.6),
        canTapOnHeader: true,
        openStateIcon: Container(),
        closeStateIcon: Container(),
        isExpanded: indexSource.isOpenChildList,
        body: Padding(
          padding: EdgeInsets.fromLTRB(
            8,
            0,
            0,
            0,
          ),
          child: createLibChild(indexSource.child),
        ),
        headerBuilder: (bc, openState) => ListTile(
          title: Text(
            indexSource.name,
            style: TextStyle(fontSize: 16),
          ),
          trailing: SizedBox(
            child: IndexSourceTypeLogo(indexSource.type),
            width: 35,
          ),
        ),
      );
    case 1:
    default:
      return FreeExpansionPanel(
        backgroundColor: Color.fromRGBO(248, 248, 248, 0.6),
        canTapOnHeader: true,
        openStateIcon: Container(),
        closeStateIcon: Container(),
        headerBuilder: (bc, openState) => ListTile(
          title: Text(
            indexSource.name,
            style: TextStyle(fontSize: 16),
          ),
          trailing: SizedBox(
            child: IndexSourceTypeLogo(indexSource.type),
            width: 35,
          ),
        ),
        body: Container(),
      );
  }
}

createLibChild(List<IndexSource> childData) {
  return Column(
    children: [
      FreeExpansionPanelList(
        elevation: 0,
        expansionCallback: (index, openState) {
          childData[index].isOpenChildList = !openState;
          AppDataSource.getOnlyExist.notifyListeners();
        },
        expandedHeaderPadding: EdgeInsets.all(0),
        // physics: BouncingScrollPhysics(),
        children: childData.map((e) => indexSourceCreateView(e)).toList(),
      )
    ],
  );
}

class BookIndex extends StatelessWidget {
  BookIndex() {}

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AppDataSource.getOnlyExist),
      ],
      child: StatefulBuilder(builder: (bc, ns) {
        List<IndexSource> rootChild = [];
        if (bc.watch<AppDataSource>().nowIndexSource != null)
          rootChild.addAll(bc.watch<AppDataSource>().nowIndexSource!.child);
        return Column(
          children: [
            SizedBox(
              height: 10,
            ),
            createLibChild(rootChild)
          ],
        );
      }),
    );
  }
}
