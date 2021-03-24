import 'package:drop_anchor/state/data.dart';
import 'package:drop_anchor/widget/free_expansion_panel_list.dart';
import 'package:flutter/material.dart';
import 'package:drop_anchor/model/index_source.dart';
import 'package:provider/provider.dart';

FreeExpansionPanel indexSourceCreateView(IndexSource indexSource) {
  switch (indexSource.type) {
    //DIR
    case 0:
      return FreeExpansionPanel(
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
          leading: SizedBox(
            child: indexSourceTypeLogo(indexSource.type,
                typeState: indexSource.isOpenChildList ? 1 : 0),
            width: 35,
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
          onSelected: (selectRunFunc){
            selectRunFunc();
          },
          itemBuilder: (bc) => [
            PopupMenuItem(
              child: Text("Show"),
              value: () {
                AppDataSource.getOnlyExist.activationIndexSourceManage.setShowIndexSource=indexSource;
                AppDataSource.getOnlyExist.notifyListeners();
              },
            ),
            PopupMenuItem(
              child: Text("Edit"),
              value: () {},
            ),
            PopupMenuItem(
              child: Text("Download"),
              value: () {},
            ),
          ],
          child: ListTile(
            title: Text(
              indexSource.name,
              style: TextStyle(fontSize: 16),
            ),
            leading: SizedBox(
              child: indexSourceTypeLogo(indexSource.type),
              width: 35,
            ),
          ),
          offset: Offset(
            0,
            40,
          ),
        ),
        body: Container(),
      );
  }
}

Widget createLibChild(List<IndexSource> childData) {
  return Column(
    children: [
      FreeExpansionPanelList(
        elevation: 0,
        expansionCallback: (index, openState) {
          childData[index].isOpenChildList = !openState;
          AppDataSource.getOnlyExist.notifyListeners();
        },
        expandedHeaderPadding: EdgeInsets.all(0),
        children: childData.map(indexSourceCreateView).toList(),
      )
    ],
  );
}

class BookIndex extends StatelessWidget {
  BookIndex();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AppDataSource.getOnlyExist),
      ],
      child: StatefulBuilder(builder: (bc, ns) {
        var rootChild = <IndexSource>[];
        if (bc
                .watch<AppDataSource>()
                .activationIndexSourceManage
                .nowIndexSource !=
            null) {
          rootChild.addAll(bc
              .watch<AppDataSource>()
              .activationIndexSourceManage
              .nowIndexSource!
              .child);
        }
        return ListView(
          physics: BouncingScrollPhysics(),
          shrinkWrap: true,
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
