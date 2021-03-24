

import 'package:drop_anchor/api/state_code.dart';

abstract class ApiError implements Exception{
  late int errorApiStateCode;
  late String errorMessage;

  @override
  String toString() {
    return super.toString();
  }
}
class ApiErrorBash implements ApiError{
  @override
  int errorApiStateCode;

  @override
  String errorMessage;
  ApiErrorBash({required this.errorApiStateCode,required this.errorMessage});

  @override
  String toString() {
    return "${super.toString()}\n StateCode:$errorApiStateCode\n Message:$errorMessage";
  }

}


class PathFindNot implements ApiError{
  @override
  int errorApiStateCode=StateCode.RES_ERROR_PATH_FIND_NOT;
  @override
  late String errorMessage;
  PathFindNot({required String this.errorMessage});

  @override
  String toString() {
    return "${super.toString()}\n StateCode:$errorApiStateCode\n Message:$errorMessage";
  }
}