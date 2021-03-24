import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';


class PersistData {
  late File fileSource;
  PersistData(this.fileSource);
  Future<dynamic> read()async{
    return jsonDecode(await fileSource.readAsString());
  }
  Future<void> save(String content)async{
    await fileSource.writeAsString(content);
  }
}


class Persist {
  static Future<String> getPersistDir() async {
    final saveDirPath = await getApplicationSupportDirectory();
    final persistDir = Directory(path.join(saveDirPath.path, 'persist'));
    if (await persistDir.exists()) {
      await persistDir.create(recursive: true);
    }
    return persistDir.path;
  }

  static Future<PersistData> delPersist(String persistName) async {
    final persistDirPath = await getPersistDir();
    final usePersistFile=File(path.join(persistDirPath,persistName));
    if(await usePersistFile.exists()){
      await usePersistFile.delete();
    }
    return PersistData(usePersistFile);
  }

  static Future<PersistData> usePersist(String persistName,String initData) async {
    final persistDirPath = await getPersistDir();
    final usePersistFile=File(path.join(persistDirPath,persistName));
    if(! await usePersistFile.exists()) {
      await usePersistFile.create(recursive: true);
      await usePersistFile.writeAsString(initData);
    }
    return PersistData(usePersistFile);
  }
}
