import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drop_anchor/api/state_code.dart';
import 'package:drop_anchor/model/api_res_package.dart';
import 'package:drop_anchor/model/index_source.dart';
import 'package:drop_anchor/model/server_source.dart';

Future<ApiResPackage> getServerPublicDataIndex(
    ServerSource serverSource) async {
  final req=(await Dio()
      .getUri(Uri.parse("${serverSource.getUrl()}/api/v0/public/index")));
  if(req.statusCode==200){
    return ApiResPackage.fromObject(req.data);
  }else{
    return ApiResPackage(req.statusCode!,[],"");
  }
}

Future<ApiResPackage> getServerPublicData(
    ServerSource serverSource, String path) async {
  return ApiResPackage.fromObject(
    (await Dio().get("${serverSource.getUrl()}/api/v0/public/file",
            queryParameters: {"path": path}))
        .data,
  );
}
