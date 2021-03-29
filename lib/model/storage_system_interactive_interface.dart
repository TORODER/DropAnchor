import 'dart:async';

import 'index_source.dart';

abstract class StorageSystemInteractiveInterface {
  Future<bool> uploadFile() {
    throw UnimplementedError();
  }

  Future<bool> downloadFile() {
    throw UnimplementedError();
  }


  Future<Iterable<int>> getFileContent({required IndexSource fromIndexSource }) {
    throw UnimplementedError();
  }

  Future<bool> createDir(){
    throw UnimplementedError();
  }

  Future<bool> delete(IndexSource targetIndexSource) {
    throw UnimplementedError();
  }

  Future<bool> rename() {
    throw UnimplementedError();
  }
}
