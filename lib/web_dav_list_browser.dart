import 'package:comicviewer/shared_preference_helper.dart';
import 'package:comicviewer/web_dav_browser.dart';
import 'package:flutter/material.dart';

class WebDavListBrowser extends StatefulWidget {
  const WebDavListBrowser({super.key});

  @override
  WebDavListBrowserState createState() => WebDavListBrowserState();
}

class WebDavListBrowserState extends State<WebDavListBrowser> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInputPopup(context),
        child: Icon(Icons.add),
      ),
      body: FutureBuilder(
          future: SharedPrefHelper.loadJson(),
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No Data found'));
            }

            final serverList = snapshot.data!;

            return ListView.builder(
              itemCount: serverList.length,
              itemBuilder: (_, index) {
                final serverName = serverList.keys.elementAt(index);

                return ListTile(
                  title: Text(serverName),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => WebDavBrowser(
                                  host: serverList[serverName]['host'],
                                  id: serverList[serverName]['id'],
                                  password: serverList[serverName]['password'],
                                )));
                  },
                );
              },
            );
          }),
    );
  }

  void _showInputPopup(BuildContext context) async {
    TextEditingController nameController = TextEditingController();
    TextEditingController hostController = TextEditingController();
    TextEditingController idController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter Connection Details"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: hostController,
                  decoration: InputDecoration(labelText: "Host"),
                ),
                TextField(
                  controller: idController,
                  decoration: InputDecoration(labelText: "ID"),
                ),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: "Password"),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                String name = nameController.text;
                String host = hostController.text;
                String id = idController.text;
                String password = passwordController.text;

                final jsonData = await SharedPrefHelper.loadJson();
                jsonData.putIfAbsent(name, () {
                  return {
                    'host': host,
                    'id': id,
                    'password': password,
                  };
                });
                await SharedPrefHelper.saveJson(jsonData);

                setState(() {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                });
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }
}
