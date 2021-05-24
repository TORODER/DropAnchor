import 'dart:async';
import 'dart:convert';

import 'package:drop_anchor/api/server_public_data.dart';
import 'package:drop_anchor/api/state_code.dart';
import 'package:drop_anchor/model/file_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:drop_anchor/model/index_source.dart';
import 'package:drop_anchor/model/server_source.dart';
import 'package:drop_anchor/tool/persist.dart';

IndexSource deIndex(String pathStruct) {
  final deres = jsonDecode(pathStruct);
  return IndexSource.helperCreate(deres, parent: null);
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
      var libList = List<dynamic>.from(await listServerPersist.read())
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      listServer = libList
          .map((e) => ServerSource(
                e['name'],
                e['source'],
                e['port'],
              ))
          .toList();
      //init con
      listServer.forEach(addListServerCont);
    })
      ..then((_) async {
        await saveServer();
      });
  }

  void addListServerCont(ServerSourceBase serverSource) {
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

  Future deleteServer(ServerSourceBase removeServerSource) async {
    await loadState;
    listServer.remove(removeServerSource);
    await saveServer();
  }

  Future addServer(String name, String source, int port) async {
    await loadState;
    final newServerSource = ServerSource(name, source, port);
    listServer.add(newServerSource);
    addListServerCont(newServerSource);
    await saveServer();
  }
}

class _ActivationIndexSourceManage {
  IndexSource? _rootIndexSource;
  IndexSource? _showIndexSource;

  ServerSourceBase? _serverSource;
  Future<bool>? activationLoad;

  _ActivationIndexSourceManage() {
    _rootIndexSource = null;
  }

  Future<bool> fromRemoteServerReadIndexSource(ServerSourceBase serverSource) {
    _serverSource = serverSource;
    activationLoad = Future<bool>(() async {
      final resPack = await getServerPublicDataIndex(serverSource);
      switch (resPack.stateCode) {
        case StateCode.RES_OK:
          _rootIndexSource = IndexSource(
              FsFileType.DIR, "RemoteLibExport", resPack.data,
              parent: null, fileType: FileType.UNDEFINITION);
          return true;
        default:
          // throw error
          print(resPack);
          return false;
      }
    });
    return activationLoad ?? Future.value(false);
  }

  Future<bool> fromLocalReadIndexSource(
    ServerSourceBase serverSource, {
    required IndexSource rootIndexSource,
    required IndexSource showIndexSource,
  }) {
    _serverSource = serverSource;
    _rootIndexSource = rootIndexSource;
    _showIndexSource = showIndexSource;
    activationLoad = Future.value(true);
    final resFutureOver = Future.value(true);
    return resFutureOver;
  }

  ServerSourceBase? get serverSource => _serverSource;

  IndexSource? get getShowIndexSource => _showIndexSource;

  set setShowIndexSource(IndexSource showIndexSource) {
    if (_serverSource != null) {
      _showIndexSource = showIndexSource;
    }
  }

  IndexSource? get rootIndexSource => _rootIndexSource;
}

class AppDataSource with ChangeNotifier, DiagnosticableTreeMixin {
  late final Future<AppDataSource> initState;

  final _ManageRemoteServer manageRemoteServer = _ManageRemoteServer();
  final _ActivationIndexSourceManage activationIndexSourceManage =
      _ActivationIndexSourceManage();

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
      return this;
    });
  }
}
