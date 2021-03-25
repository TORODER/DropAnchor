import 'package:drop_anchor/state/data.dart';
import 'package:drop_anchor/tool/security_set_state.dart';
import 'package:drop_anchor/widget/free_expansion_panel_list.dart';
import 'package:flutter/material.dart';
import 'package:drop_anchor/model/index_source.dart';

FreeExpansionPanel indexSourceCreateView(IndexSource indexSource) {
  switch (indexSource.type) {
    //DIR
    case 0:
      return FreeExpansionPanel(
        canTapOnHeader: true,
        openStateIcon:  Container(),
        closeStateIcon: Container(),
        isExpanded: indexSource.isOpenChildList,
        body:  Padding(
          padding: const  EdgeInsets.fromLTRB(
            8,
            0,
            0,
            0,
          ),
          child: BookIndex.createLibChild(indexSource.child),
        ),
        headerBuilder: (bc, openState) => ListTile(
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
      );
    //FILE
    case 1:
    default:
      return FreeExpansionPanel(
        canTapOnHeader: true,
        openStateIcon:  Container(),
        closeStateIcon:  Container(),
        headerBuilder: (bc, openState) => PopupMenuButton<Function>(
          onSelected: (selectRunFunc) {
            selectRunFunc();
          },
          itemBuilder: (bc) => [
            PopupMenuItem(
              child: const Text("Show"),
              value: () {
                AppDataSource.getOnlyExist.activationIndexSourceManage
                    .setShowIndexSource = indexSource;
                AppDataSource.getOnlyExist.notifyListeners();
              },
            ),
            PopupMenuItem(
              child: const Text("Edit"),
              value: () {},
            ),
            PopupMenuItem(
              child: const Text("Download"),
              value: () {},
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
        body:  Container(),
      );
  }
}



class BookIndex extends StatelessWidget {
  BookIndex();


  static Widget createLibChild(List<IndexSource> childData) {
    return SecurityStatefulBuilder(
      builder: (bc, ns) {
        return Column(
          children: [
            FreeExpansionPanelList(
              elevation: 0,
              expansionCallback: (index, openState) {
                childData[index].isOpenChildList = !openState;
                ns(()=>null);
              },
              expandedHeaderPadding: const EdgeInsets.all(0),
              children: childData.map(indexSourceCreateView).toList(),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rootChild = <IndexSource>[];
    if (AppDataSource.getOnlyExist.activationIndexSourceManage.nowIndexSource !=
        null) {
      rootChild.addAll(AppDataSource
          .getOnlyExist.activationIndexSourceManage.nowIndexSource!.child);
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
