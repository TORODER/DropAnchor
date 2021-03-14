import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';


class PersistData {
  late File fileSource;
  PersistData(File _fileSource){
    this.fileSource=_fileSource;
  }
  Future<dynamic> read()async{
    return jsonDecode(await fileSource.readAsString());
  }
  Future<void> save(String content)async{
    await this.fileSource.writeAsString(content);
  }
}


class Persist {
  static Future<String> getPersistDir() async {
    final saveDirPath = await getApplicationSupportDirectory();
    final PersistDir = new Directory(path.join(saveDirPath.path, 'persist'));
    if (await PersistDir.exists()) {
      await PersistDir.create(recursive: true);
    }
    return PersistDir.path;
  }

  static Future<PersistData> usePersist(String PersistName,String initData) async {
    final String persistDirPath = await getPersistDir();
    final usePersistFile=File(path.join(persistDirPath,PersistName));
    if(! await usePersistFile.exists()) {
      await usePersistFile.create(recursive: true);
      await usePersistFile.writeAsString(initData);
    }
    return PersistData(usePersistFile);
  }
}
