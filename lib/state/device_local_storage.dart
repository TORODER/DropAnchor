import 'dart:convert';
import 'dart:io';
import 'package:drop_anchor/error/local_error.dart';
import 'package:drop_anchor/model/file_type.dart';
import 'package:drop_anchor/model/index_source.dart';
import 'package:drop_anchor/model/server_source.dart';
import 'package:drop_anchor/tool/file_suffix_analysis.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class LocalStorageServerSource implements ServerSourceBase {
  static const String staticToken = 'LocalStorageSource';

  @override
  String agreement = "";

  @override
  String name = "";

  @override
  int port = 0;

  @override
  String source = "";

  LocalStorageServerSource({required this.source});

  @override
  String getUri() {
    return source;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "agreement": agreement,
      "name": name,
      "port": port,
      "source": source
    };
  }

  @override
  String token() {
    return staticToken;
  }

  @override
  Future<bool> delete(IndexSource targetIndexSource) async {
    try {
      final targetPath = DeviceLocalStorage.getOnlyElem
          .getIndexSourceFileSystemPath(targetIndexSource);
      await File(targetPath).delete();
      return true;
    } on Exception catch (e) {
      print(e);
      return false;
    }
  }

  @override
  Future<bool> downloadFile() {
    // TODO: implement downloadFile
    throw UnimplementedError();
  }

  @override
  Future<Iterable<int>> getFileContent({required IndexSource fromIndexSource}) {
    return Future<Iterable<int>>(() async {
      final targetPath = DeviceLocalStorage.getOnlyElem
          .getIndexSourceFileSystemPath(fromIndexSource);

      final targetFile = File(targetPath);
      final targetFileStat = await targetFile.stat();
      if (targetFileStat.type == FileSystemEntityType.file) {
        final data = await targetFile.readAsString();
        return utf8.encode(data);
      } else {
        throw LocalError(errorMessage: "Local File Type Error");
      }
    });
  }

  @override
  Future<bool> rename() {
    // TODO: implement rename
    throw UnimplementedError();
  }

  @override
  Future<bool> uploadFile() {
    // TODO: implement uploadFile
    throw UnimplementedError();
  }

  @override
  Future<bool> createDir() {
    // TODO: implement createDir
    throw UnimplementedError();
  }
}

class DeviceLocalStorage {
  static const String saveRootDirName = "DEVICELOCALSTORAGE";
  static DeviceLocalStorage? _deviceLocalStorageElem;

  late String saveRootDirPath;
  late Directory saveRootDirSource;
  late Future loadState;
  late final IndexSource? rootIndexSource;
  late final ServerSourceBase serverSource;

  String getIndexSourceFileSystemPath(IndexSource indexSource) {
    print( path.relative( path.join(saveRootDirPath,"./${indexSource.getCompletePath()}") ) );
    return path.relative(path.join(saveRootDirPath,
        "./${indexSource.getCompletePath()}"));
  }

  factory DeviceLocalStorage() {
    if (_deviceLocalStorageElem == null) {
      _deviceLocalStorageElem = DeviceLocalStorage._init();
    }
    return _deviceLocalStorageElem!;
  }

  DeviceLocalStorage._init() {
    loadState = Future(() async {
      final appDocPath = (await getApplicationSupportDirectory()).path;
      saveRootDirPath = path.join(appDocPath, saveRootDirName);
      serverSource = LocalStorageServerSource(source: saveRootDirPath);
      saveRootDirSource = Directory(saveRootDirPath);
      if (!await saveRootDirSource.exists()) {
        await saveRootDirSource.create(recursive: true);
      }
      rootIndexSource = await _buildIndexSource(saveRootDirPath, null);
    });
  }

  static DeviceLocalStorage get getOnlyElem {
    return DeviceLocalStorage();
  }

  Future<IndexSource> _buildIndexSource(
      String analysisPath, IndexSource? parent) async {
    final name = path.split(analysisPath).last;
    final fNode = IndexSource(FsFileType.DIR, name, [],
        parent: parent, fileType: FileType.UNDEFINITION);
    final childList = <IndexSource>[];
    final childSourceList =
        await (await Directory(analysisPath).list()).toList();
    for (final nextSource in childSourceList) {
      if (nextSource is File) {
        childList.add(
          IndexSource(
            FsFileType.FILE,
            path.split(nextSource.path).last,
            [],
            parent: fNode,
            fileType: FileTypeSuffixAnalysis().testFileType(
              path.basename(nextSource.path),
            ),
          ),
        );
      } else if (nextSource is Directory) {
        childList.add(await _buildIndexSource(nextSource.path, fNode));
      }
    }
    fNode.child = childList;
    return fNode;
  }
}
