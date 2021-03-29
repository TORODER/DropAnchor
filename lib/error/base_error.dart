abstract class BaseError implements Exception{
  late String errorMessage;
  BaseError(){}
  @override
  String toString() {
    return "errorMessage: $errorMessage";
  }
}