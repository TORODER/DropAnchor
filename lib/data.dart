import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:drop_anchor/model/IndexSource.dart';
import 'package:drop_anchor/model/ServerSource.dart';
import 'package:drop_anchor/persist.dart';



class AppDataSource with ChangeNotifier, DiagnosticableTreeMixin {
  late final List<ServerSource> listServer;

  late final Map<String, Map<String, TextEditingController>>
      listServerNameConMap = new Map();
  late final Future initState;
  late final PersistData listServerData;
  late IndexSource BookIndex;

  AppDataSource() {
    initState = Future(() async {
      listServerData = await Persist.usePersist("LIBDATA", jsonEncode([]));

      List<Map<String, dynamic>> LibList =
          List<dynamic>.from(await listServerData.read())
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

      this.listServer =
          LibList.map((e) => ServerSource(e['source'], e['name'], e['port']))
              .toList();

      listServer.forEach((element) => createListServerCont(element));
      await listServerData.save(jsonEncode(listServer.map((e) => e.toMap()).toList()));
    });
  }

  Future deleteServer(ServerSource removeServerSource)async{
    await this.initState;
    this.listServer.remove(removeServerSource);
    await listServerData.save(jsonEncode(listServer.map((e) => e.toMap()).toList()));
  }

  createListServerCont(ServerSource serverSource) {
    final createMap = new Map<String, TextEditingController>();
    final editNameCon = new TextEditingController();
    createMap['editName'] = editNameCon;
    editNameCon.text = serverSource.name;
    listServerNameConMap[serverSource.source] = createMap;
  }
}

final AppDataSourceElem = new AppDataSource();
