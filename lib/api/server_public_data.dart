
import 'package:dio/dio.dart';
import 'package:drop_anchor/model/api_res_package.dart';
import 'package:drop_anchor/model/server_source.dart';

Future<ApiResPackage> getServerPublicDataIndex(
    ServerSourceBase serverSource,) async {
  final req = (await Dio()
      .getUri(Uri.parse("${serverSource.getUri()}/api/v0/public/index")));
  if (req.statusCode == 200) {
    return ApiResPackage.fromObject(req.data);
  } else {
    return ApiResPackage(req.statusCode!, [], "");
  }
}

Future<ApiResPackage> getServerPublicData(ServerSourceBase serverSource,
    String path) async {
  return ApiResPackage.fromObject(
    (await Dio().get("${serverSource.getUri()}/api/v0/public/file",
        queryParameters: {"path": path}))
        .data,
  );
}
