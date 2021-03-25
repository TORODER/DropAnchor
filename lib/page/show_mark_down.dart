import 'dart:convert';

import 'package:drop_anchor/error/api_error.dart';
import 'package:drop_anchor/model/file_type.dart';
import 'package:drop_anchor/model/index_source.dart';
import 'package:drop_anchor/model/remote_data_source.dart';
import 'package:drop_anchor/model/server_source.dart';
import 'package:drop_anchor/state/app.dart';
import 'package:drop_anchor/tool/security_set_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../mddata.dart';
import 'book_index.dart';
import 'edit.dart';

class ShowMarkdown extends StatelessWidget {
  Widget createDrawer() {
    return Container(
      color: Colors.white,
      width: 275,
      height: double.infinity,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BookIndex(),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Row(
                    children: [
                      Text(
                        "Use Lib : ${AppDataSource.getOnlyExist.activationIndexSourceManage.serverSource?.name ?? ""}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      )
                    ],
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                  )
                ],
              ),
              color: Colors.blue,
              height: 22,
            )
          ],
        ),
      ),
    );
  }

  Widget createView(Iterable<int> data, int fileType) {
    switch (fileType) {
      case FileType.MARKDOWN:
        {
          return Markdown(
            padding: EdgeInsets.all(14),
            data: utf8.decode(data.toList()),
            selectable: true,
            physics: BouncingScrollPhysics(),
            onTapLink: (text, href, title) {
              if (href != null) {
                launch(href);
              }
            },
          );
        }
      case FileType.UNDEFINITION:
      case FileType.TEXT:
      default:
        return ListView(
          children: [
            Container(
              child: Text(utf8.decode(data.toList())),
              padding: EdgeInsets.all(14),
            ),
          ],
        );
    }
  }

  Widget createMarkdownView(
      ServerSource serverSource, IndexSource indexSource) {
    return FutureBuilder(
      future: Future<dynamic>(() async {
        await AppDataSource
            .getOnlyExist.activationIndexSourceManage.activationLoad;
        final remoteDataSource = RemoteDataSource.fromIndexSource(
          indexSource,
          fromServerSource: serverSource,
        );
        return await remoteDataSource.getState;
      }),
      builder: (bc, futureState) {
        if (futureState.hasError) {
          print(futureState.error.toString());
          return Text("${futureState.error}");
        }
        if (futureState.connectionState != ConnectionState.done) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        return createView(
          futureState.data as Iterable<int>,
          indexSource.fileType,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AppDataSource.getOnlyExist),
      ],
      child: SecurityStatefulBuilder(
        builder: (bc, securityNewState) => Scaffold(
          body: FutureBuilder(
            future: AppDataSource.getOnlyExist.initState,
            builder: (bc, futureState) {
              if (futureState.hasError) {
                print(futureState.error);
                return Text(futureState.error.toString());
              }
              if (futureState.connectionState != ConnectionState.done) {
                return CircularProgressIndicator();
              }
              if (bc
                      .watch<AppDataSource>()
                      .activationIndexSourceManage
                      .getShowIndexSource !=
                  null) {
                return Scaffold(
                  appBar: AppBar(
                    automaticallyImplyLeading: false,
                    title: Text(
                        '${bc.watch<AppDataSource>().activationIndexSourceManage.getShowIndexSource!.name}'),
                    actions: [
                      IconButton(
                        iconSize: 28,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (router_bc) => Edit(
                                fromIndexSource: bc
                                    .read<AppDataSource>()
                                    .activationIndexSourceManage
                                    .getShowIndexSource!,
                                fromServerSource: bc
                                    .read<AppDataSource>()
                                    .activationIndexSourceManage
                                    .serverSource!,
                              ),
                            ),
                          );
                        },
                        icon: Image.asset(
                          "assets/edit-file.png",
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                    ],
                  ),
                  drawer: createDrawer(),
                  drawerEdgeDragWidth: 250,
                  body: createMarkdownView(
                    bc
                        .watch<AppDataSource>()
                        .activationIndexSourceManage
                        .serverSource!,
                    bc
                        .watch<AppDataSource>()
                        .activationIndexSourceManage
                        .getShowIndexSource!,
                  ),
                );
              } else {
                return Scaffold(
                  body: Center(
                    child: Text("No Show Doc !"),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
