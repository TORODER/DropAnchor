import 'dart:io';
import 'package:drop_anchor/model/file_type.dart';
import 'package:drop_anchor/model/index_source.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class DeviceLocalStorage {
  static const String saveRootDirName = "DEVICELOCALSTORAGE";
  static DeviceLocalStorage? _deviceLocalStorageElem;



  late String saveRootDirPath;
  late Directory saveRootDirSource;
  late Future loadState;
  late final IndexSource? rootIndexSource;


  factory DeviceLocalStorage(){
    if(_deviceLocalStorageElem==null){
      _deviceLocalStorageElem=DeviceLocalStorage._init();
    }
    return _deviceLocalStorageElem!;
  }
  DeviceLocalStorage._init(){
    loadState=Future(()async{
      final appDocPath=(await getApplicationSupportDirectory()).path;
      saveRootDirPath=path.join(appDocPath,saveRootDirName);
      saveRootDirSource=Directory(saveRootDirPath);
      if(!await saveRootDirSource.exists()){
        await saveRootDirSource.create(recursive: true);
      }
      rootIndexSource=await _buildIndexSource(saveRootDirPath,null);
    });
  }
  static DeviceLocalStorage  get getOnlyElem{
    return DeviceLocalStorage();
  }

  Future<IndexSource> _buildIndexSource(String analysisPath,IndexSource? parent)async{
     final name=path.split(analysisPath).last;
     final fNode= IndexSource(FsFileType.DIR, name, [], parent: parent, fileType: FileType.UNDEFINITION);
     final childList=<IndexSource>[];
     final childSourceList=await (await Directory(analysisPath).list()).toList();
     for(final nextSource in childSourceList){
       if(nextSource is File){
         childList.add(IndexSource(FsFileType.FILE, path.split(nextSource.path).last, [], parent:fNode , fileType: FileType.UNDEFINITION));
       }else if(nextSource is Directory){
         childList.add(await _buildIndexSource(nextSource.path,fNode));
       }
     }
     fNode.child=childList;
     return fNode;
  }


}