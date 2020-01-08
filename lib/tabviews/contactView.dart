import 'package:flutter/material.dart';
import 'package:ciphermonkey/model.dart';
import 'package:toast/toast.dart';
import 'package:flutter/services.dart';

class ContactView extends StatefulWidget {
  ContactView({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ContactViewState createState() => _ContactViewState();
}

class _ContactViewState extends State<ContactView> {
  List<CMKey> pubkeys = [];
  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    Future<List<CMKey>> pubkeyFuture = DB.queryKeys(type: "public");

    pubkeyFuture.then((keys) {
      pubkeys = keys;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: ListView.builder(
        // Let the ListView know how many items it needs to build.
        itemCount: pubkeys.length,
        // Provide a builder function. This is where the magic happens.
        // Convert each item into a widget based on the type of item it is.
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              "${pubkeys[index].name}",
              style: Theme.of(context).textTheme.title,
            ),
            subtitle: Text("${pubkeys[index].id}"),
            leading: Text("${(index + 1).toString()}"),
            onTap: () {
              DB.currentPublicKey = pubkeys[index];
              DefaultTabController.of(context).animateTo(1);
            },
          );
        },
      )),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Future<ClipboardData> clipboard = Clipboard.getData("text/plain");

          clipboard.then((value) {
            Toast.show("Copy to Clipboard Successed!!${value.text}", context,
                duration: Toast.LENGTH_SHORT, gravity: Toast.CENTER);
          });
        },
        label: Text('Add From Clipboard'),
        icon: Icon(Icons.add_circle),
        backgroundColor: Colors.green,
      ),
    );
  }
}
