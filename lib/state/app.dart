import 'dart:async';
import 'dart:convert';

import 'package:drop_anchor/mddata.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:drop_anchor/model/index_source.dart';
import 'package:drop_anchor/model/server_source.dart';
import 'package:drop_anchor/tool/persist.dart';

IndexSource deIndex(String pathStruct) {
  final deres = jsonDecode(pathStruct);
  return IndexSource.createIndexSource(deres);
}

class _ManageRemoteServer {
  late final Future loadState;
  late final List<ServerSource> listServer;
  late final PersistData listServerPersist;
  late final Map<String, Map<String, TextEditingController>>
  listServerNameConMap = {};

  _ManageRemoteServer() {
    loadState = Future(() async {
      listServerPersist = await Persist.usePersist("LIBDATA", jsonEncode([]));
      //use vir data
      var libList =
      List<dynamic>.from(await listServerPersist.read())
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      listServer =
          libList.map((e) => ServerSource(e['source'], e['name'], e['port']))
              .toList();
      //init con
      listServer.forEach(addListServerCont);
    })
      ..then((_) async {
        await saveServer();
      });
  }

  void addListServerCont(ServerSource serverSource) {
    final createMap = <String, TextEditingController>{};
    final editNameCon = TextEditingController();
    createMap['editName'] = editNameCon;
    editNameCon.text = serverSource.name;
    listServerNameConMap[serverSource.token()] = createMap;
  }

  Future saveServer() async {
    await loadState;
    await listServerPersist
        .save(jsonEncode(listServer.map((e) => e.toMap()).toList()));
  }

  Future deleteServer(ServerSource removeServerSource) async {
    await loadState;
    listServer.remove(removeServerSource);
    await saveServer();
  }

  Future addServer(String source, String name, int port) async {
    await loadState;
    final newServerSource = ServerSource(source, name, port);
    listServer.add(newServerSource);
    addListServerCont(newServerSource);
    await saveServer();
  }
}



class _SelectIndexSourceManage{
  IndexSource? useIndexSource;
  IndexSource? nowIndexSource;
  late List<String> showPath = [];
  _SelectIndexSourceManage(){
    useIndexSource = deIndex(bookPathData);
    nowIndexSource = useIndexSource;
  }
}



class AppDataSource with ChangeNotifier, DiagnosticableTreeMixin {

  late final Future initState;
  late final Map<String, String> appConfig = {};

  final _ManageRemoteServer manageRemoteServer = _ManageRemoteServer();
  final _SelectIndexSourceManage selectIndexSourceManage = _SelectIndexSourceManage();

  static AppDataSource? _appDataSourceElem;
  factory AppDataSource() => getOnlyExist;

  static AppDataSource get getOnlyExist {
    if (_appDataSourceElem == null) {
      _appDataSourceElem = AppDataSource._initOnlyExist();
    }
    return _appDataSourceElem!;
  }

  @override
  AppDataSource._initOnlyExist() {
    initState = Future(() async {
      await manageRemoteServer.loadState;
    });
  }
}
