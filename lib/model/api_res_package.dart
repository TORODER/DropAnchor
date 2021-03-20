
import 'dart:convert';

class ApiResPackage{
  late final int staticCode;
  late final String explain;
  late dynamic data;
  ApiResPackage.fromJsonString(String packageStr){
     final deMap=Map<String,dynamic>.from(json.decode(packageStr));
     staticCode=deMap["code"];
     explain=deMap["explain"];
     data=deMap["data"];
   }
}