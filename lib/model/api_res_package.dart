import 'dart:convert';

class ApiResPackage {
  late final int stateCode;
  late final String message;
  late dynamic data;

  ApiResPackage.fromJsonString(String packageStr) {
    final deMap = Map<String, dynamic>.from(json.decode(packageStr));
    stateCode = deMap["code"];
    message = deMap["message"];
    data = deMap["data"];
  }
  ApiResPackage.fromObject(dynamic resData){
    stateCode = resData["code"];
    message = resData["message"];
    data = resData["data"];
  }

  ApiResPackage(this.stateCode,this.data,this.message);

  String toJson() {
    return jsonEncode({
      "stateCode": stateCode,
      "message": message,
      "data": data,
    });
  }
}
