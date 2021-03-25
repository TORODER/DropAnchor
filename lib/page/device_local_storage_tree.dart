import 'package:drop_anchor/page/book_index.dart';
import 'package:drop_anchor/state/device_local_storage.dart';
import 'package:drop_anchor/tool/security_set_state.dart';
import 'package:flutter/material.dart';

class DeviceLocalStorageTree extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: DeviceLocalStorage.getOnlyElem.loadState,
        builder: (BuildContext context, futureState) {
          if (futureState.hasError) {
            print(futureState.error);
          }
          if (futureState.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return ListView(
            children: [
              BookIndex.createLibChild(
                  DeviceLocalStorage.getOnlyElem.rootIndexSource!.child)
            ],
          );
        },
      ),
    );
  }
}
