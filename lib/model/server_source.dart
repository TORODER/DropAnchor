import 'dart:convert';

import 'package:drop_anchor/api/server_public_data.dart';
import 'package:drop_anchor/api/state_code.dart';
import 'package:drop_anchor/error/api_error.dart';
import 'package:drop_anchor/model/storage_system_interactive_interface.dart';
import 'package:drop_anchor/model/token.dart';

import 'index_source.dart';

class ServerSourceBase implements Token, StorageSystemInteractiveInterface {
  String source;
  String name;
  String agreement;
  int port;

  ServerSourceBase(this.name, this.source, this.port,
      {this.agreement = "http"});

  Map<String, dynamic> toMap() {
    return {
      "source": source,
      "name": name,
      "port": port
    };
  }

  @override
  String token() {
    return '$source-$port';
  }

  String getUri() => "$agreement://$source:$port";

  @override
  Future<bool> delete(IndexSource targetIndexSource) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<bool> downloadFile() {
    // TODO: implement downloadFile
    throw UnimplementedError();
  }

  @override
  Future<Iterable<int>> getFileContent(
      {required IndexSource fromIndexSource }) async {
    // TODO: implement rename
    throw UnimplementedError();
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


class ServerSource extends ServerSourceBase {
  ServerSource(String name, String source, int port)
      : super(name, source, port);

  @override
  Future<Iterable<int>> getFileContent(
      {required IndexSource fromIndexSource }) async {
    // TODO: implement rename
    var _base64Data;
    final getResPackage = await getServerPublicData(
        this, fromIndexSource.getCompletePath());
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
  }
}
