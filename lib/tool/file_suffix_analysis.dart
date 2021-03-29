import 'package:drop_anchor/model/file_type.dart';
import 'package:flutter/material.dart';

class FileTypeSuffixAnalysisElem {
  late final List<String> targetSuffix;
  late final int typeId;

  FileTypeSuffixAnalysisElem(List<String> this.targetSuffix, {required this.typeId});

  bool? test(String testFileName) {
    final fileNameSlice = testFileName.split('.');
    if (fileNameSlice.isNotEmpty) {
      final fileTestSuffix = fileNameSlice.last;
      return targetSuffix.indexOf(fileTestSuffix) != -1;
    }
  }
}

class FileTypeSuffixAnalysis {
  static FileTypeSuffixAnalysis? _fileTypeSuffixAnalysisElem;

  static FileTypeSuffixAnalysis get onlyElem => FileTypeSuffixAnalysis();
  late List<FileTypeSuffixAnalysisElem> fileTypeSuffixAnalysisElems;

  factory FileTypeSuffixAnalysis() {
    if (_fileTypeSuffixAnalysisElem == null) {
      _fileTypeSuffixAnalysisElem = FileTypeSuffixAnalysis._init();
    }
    return _fileTypeSuffixAnalysisElem!;
  }

  FileTypeSuffixAnalysis._init() {
    fileTypeSuffixAnalysisElems = [];
    fileTypeSuffixAnalysisElems.addAll([
      FileTypeSuffixAnalysisElem(["js", "ts", "py", "yml", "xml", "iml", "txt", "java", "json", "text"],typeId: FileType.TEXT),
      FileTypeSuffixAnalysisElem(["md","markdown"],typeId: FileType.MARKDOWN),
    ]);
  }

  int testFileType(String fileName){
    for(final nextAnalysis in fileTypeSuffixAnalysisElems){
      final testRes=nextAnalysis.test(fileName);
      if(testRes==null)break;
      if(testRes){
        return nextAnalysis.typeId;
      }
    }
    return FileType.UNDEFINITION;
  }

}