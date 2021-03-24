import 'package:drop_anchor/model/token.dart';

class ServerSource implements Token {
  String source;
  String name;
  int port;
  ServerSource(this.name,this.source,this.port);
  Map<String,dynamic> toMap(){
    return {
      "source":source,
      "name":name,
      "port":port
    };
  }

  @override
  String token() {
    return '$source-$port';
  }
  String getUrl()=> "http://$source:$port";

}