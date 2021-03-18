import 'dart:async';
import 'dart:convert';

import 'package:drop_anchor/mddata.dart';
import 'package:drop_anchor/page/BookIndex.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:drop_anchor/model/IndexSource.dart';
import 'package:drop_anchor/model/ServerSource.dart';
import 'package:drop_anchor/persist.dart';

IndexSource deIndex(String pathStruct) {
  final deres = jsonDecode(pathStruct);
  return IndexSource.createIndexSource(deres);
}

class AppDataSource with ChangeNotifier, DiagnosticableTreeMixin  {
  late final List<ServerSource> listServer;

  late final Map<String, Map<String, TextEditingController>>
      listServerNameConMap = new Map();
  late final Future initState;
  late final PersistData listServerData;
  late final Map<String,String> appConfig=new Map();
  late List<String> showPath = [];
  IndexSource? useIndexSource;
  IndexSource? nowIndexSource;
  static AppDataSource? _AppDataSourceElem;


  factory AppDataSource() => getOnlyExist;

  @override
  static AppDataSource get  getOnlyExist{
    if (_AppDataSourceElem == null) {
      _AppDataSourceElem = new AppDataSource._initOnlyExist();
    }
    return _AppDataSourceElem!;
  } 


  addListServerCont(ServerSource serverSource) {
    final createMap = new Map<String, TextEditingController>();
    final editNameCon = new TextEditingController();
    createMap['editName'] = editNameCon;
    editNameCon.text = serverSource.name;
    listServerNameConMap[serverSource.token()] = createMap;
  }

  @override
  AppDataSource._initOnlyExist() {
    initState = Future(() async {
      {
          await Persist.usePersist("APPCONFIG", jsonEncode({}));
      }

      // init read LIBDATA
      {
        listServerData = await Persist.usePersist("LIBDATA", jsonEncode([]));
        //use vir data
        List<Map<String, dynamic>> LibList =
            List<dynamic>.from(await listServerData.read())
                .map((e) => Map<String, dynamic>.from(e))
                .toList();

        this.listServer =
            LibList.map((e) => ServerSource(e['source'], e['name'], e['port']))
                .toList();
        //create init con
        listServer.forEach((element) => addListServerCont(element));

        await this.saveServer();
      }

    });

    //use vir data
    this.useIndexSource = deIndex(bookPathData);
    this.nowIndexSource = this.useIndexSource;
  }

  Future saveServer() async {
    await listServerData
        .save(jsonEncode(listServer.map((e) => e.toMap()).toList()));
  }

  Future deleteServer(ServerSource removeServerSource) async {
    await this.initState;
    this.listServer.remove(removeServerSource);
    await this.saveServer();
  }

  Future addServer(String source, String name, int port) async {
    final newServerSource = ServerSource(source, name, port);
    this.listServer.add(newServerSource);
    this.addListServerCont(newServerSource);
    await this.saveServer();
  }

}
