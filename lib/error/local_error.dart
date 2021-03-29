import 'package:drop_anchor/error/base_error.dart';

class LocalError implements BaseError{
  @override
  late String errorMessage;
  LocalError({required this.errorMessage});
}