import 'dart:convert';
import 'dart:io';

import 'package:drop_anchor/api/server_public_data.dart';
import 'package:drop_anchor/api/state_code.dart';
import 'package:drop_anchor/error/api_error.dart';
import 'package:drop_anchor/error/local_error.dart';
import 'package:drop_anchor/model/index_source.dart';
import 'package:drop_anchor/model/server_source.dart';
import 'package:drop_anchor/state/device_local_storage.dart';
import 'package:drop_anchor/tool/persist.dart';
import 'package:path/path.dart' as path;

const _indexPersistFileName = "REMOTECACHEINDEX";

class _RemoteCache {
  static _RemoteCache? remoteCacheElem;
  static Future<_RemoteCache>? loadState;

  factory _RemoteCache() {
    if (remoteCacheElem == null) {
      remoteCacheElem = _RemoteCache._initOnly();
    }
    return remoteCacheElem!;
  }

  _RemoteCache._initOnly() {
    _RemoteCache.loadState = Future(() async {
      final persistFile = await Persist.usePersist(_indexPersistFileName, "{}");
      return this;
    });
  }
}

class RemoteDataSource {
  late String? _base64Data;
  late Future<Iterable<int>> getState;

  RemoteDataSource.fromIndexSource(IndexSource fromIndexSource,
      {required ServerSourceBase fromServerSource}) {
    if (fromServerSource.token() == LocalStorageServerSource.staticToken) {
      getState = Future<Iterable<int>>(() async {
        final targetPath = path.relative(path.join(
            fromServerSource.source, "./${fromIndexSource.getCompletePath()}"));

        final targetFile = File(targetPath);
        final targetFileStat = await targetFile.stat();
        if (targetFileStat.type == FileSystemEntityType.file) {
          final data = await targetFile.readAsString();
          return utf8.encode(data);
        } else {
          throw LocalError(errorMessage: "Local File Type Error");
        }
      });
    } else {
      getState = Future<Iterable<int>>(() async {
        final getResPackage = await getServerPublicData(
            fromServerSource, fromIndexSource.getCompletePath());
        switch (getResPackage.stateCode) {
          case StateCode.RES_OK:
            _base64Data = getResPackage.data;
            return base64Decode(_base64Data!);
          case StateCode.RES_ERROR_PATH_FIND_NOT:
            throw PathFindNot(errorMessage: 'Target is Not Find');
          default:
            throw ApiErrorBash(
                errorApiStateCode: getResPackage.stateCode,
                errorMessage: "contrary to expectation state code");
        }
      });
    }
  }

  Iterable<int>? get data {
    if (_base64Data != null) {
      return base64Decode(_base64Data!);
    } else {
      return null;
    }
  }
}
