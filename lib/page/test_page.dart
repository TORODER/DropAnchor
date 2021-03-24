import 'package:drop_anchor/api/server_public_data.dart';
import 'package:drop_anchor/model/server_source.dart';
import 'package:drop_anchor/state/app.dart';
import 'package:flutter/material.dart';

class TestPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _TestPageState();
  }
}

class _TestPageState extends State<TestPage> {
  ServerSource? activationServer;
  _TestPageState():activationServer=null;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(future:AppDataSource.getOnlyExist.initState,builder: (bc,fstate){
        if(fstate.hasError){
          print(fstate.error);
          return Text("${fstate.error}");
        }
        if(fstate.connectionState!=ConnectionState.done){
          return CircularProgressIndicator();
        }
        return ListView(
          children: [
            DropdownButton<ServerSource>(
              value:activationServer,
              items: AppDataSource.getOnlyExist.manageRemoteServer.listServer
                  .map(
                    (e) => DropdownMenuItem(
                  child: Text(e.name),
                  value: e,
                ),
              )
                  .toList(),
              icon: Icon(Icons.local_fire_department),
              onChanged: (v)=>setState(()=>activationServer=v),
            ),
            ElevatedButton(
              onPressed: () {
                if(activationServer!=null){
                  getServerPublicDataIndex(activationServer!).then((v)=>print(v.toJson()));
                }
              },
              child: Text("TestGetPublicDataIndex"),
            ),
            ElevatedButton(
              onPressed: () {
                if(activationServer!=null){
                  getServerPublicData(activationServer!,"/main/java/org/toroder/JavaAnchor/Api/StateCode.java").then((v)=>print(v.toJson()));
                }
              },
              child: Text("TestGetPublicDataContent"),
            ),
          ],
        );
      },),
    );
  }
}
