class ServerSource {
  String source;
  String name;
  int port;
  ServerSource(this.source,this.name,this.port);
  Map<String,dynamic> toMap(){
    return {
      "source":source,
      "name":name,
      "port":port
    };
  }
}