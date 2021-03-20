import 'package:dio/dio.dart';
import 'package:drop_anchor/model/server_source.dart';

void getPublicTree(ServerSource serverSource)async{
  final dio=Dio();
  final res= await dio.getUri(Uri.parse("${serverSource.getUrl()}/api/v0/public/index"));
  print(res.data);
}