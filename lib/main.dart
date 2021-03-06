// ignore_for_file: prefer_typing_uninitialized_variables, avoid_print, unnecessary_this, no_logic_in_create_state, prefer_const_constructors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';

///////// Data classes
class Note {
  String title;
  String level;
  DateTime dateCreate = DateTime.now();
  DateTime dateModify = DateTime.now();
  Note({this.title = '', this.level = 'none'});
  update(other) {
    this
      ..title = other.title
      ..level = other.level
      ..dateModify = DateTime.now();
  }
}

var sorts = {'Title', "Level", "Description"};

class Memo extends Note {
  String details = "";
  Memo({this.details = '', title = '', level = 'none'})
      : super(title: title, level: level);
  @override
  update(other) {
    super.update(other);
    this.details = other.details;
  }

  @override
  toString() => "memo||$title||$level||$details";
}

mixin Check {
  bool done = false;
}

//TODO class Event extend Todo with Date
//Container
class Notes {
  List<Note> items = [];
  var _curLevel = '*'; //filter value, * - all
  Notes() {
    //test items
    items.add(Memo(details: 'string1 \n string2', title: 'memo 1'));
    items.add(Memo(details: 'string1 \n string2', title: 'memo 2'));
    items.add(
        Memo(details: 'string1 \n string2', title: 'memo 3', level: 'high'));
    // items.add(Todo(isDone:false, details:'string1 \n string2', title:'todo 1',level:'high'));
    // items.add(Todo(isDone:true, details:'string1 \n string2', title:'todo2'));
    items.add(
        Memo(details: 'string1 \n string2', title: 'memo 4', level: 'high'));
  }
  get count => items.where(_filter).length;
  get item => (int i) => items.where(_filter).toList()[i];
  get levels => items.map((x) => x.level).toSet().toList();
  get filter => _curLevel == "" ? "*" : _curLevel;
  setFilter(lev) {
    _curLevel = lev;
  }

  bool _filter(x) {
    if (_curLevel == '*') {
      return true;
    } else {
      return _curLevel == x.level;
    }
  }

  load() async {
    //TODO load from file
    final directory = await getApplicationDocumentsDirectory();
    final file = File(directory.path + "/notes.json");
    print("load from $file");
    items.clear();
    for (String x in file.readAsLinesSync()) {
      print(x);
      var s = x.split("||");
      switch (s[0]) {
        case "memo":
          items.add(Memo(title: s[1], level: s[2], details: s[3]));
      }
    }
    print("load end");
  }

  save() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(directory.path + "/notes.json");
      print("save to $file");

      if (!file.existsSync()) {
        file.create();
      }
      file.openWrite();
      for (var x in items) {
        file.writeAsStringSync(x.toString() + '\n', mode: FileMode.append);
      }
    } catch (e) {
      print("Error while saving the file: " + e.toString());
    }
  }

  remove(item) {
    items.remove(item);
  }

  add<T extends Note>() {
    final factories = <Type, Function>{
      Memo: () => Memo(),
    };
    final one = (factories[T]!)();
    items.add(one);
    return one;
  }

  sorting(String type) {
    // var tryP(x) => int.tryParse(x)
    if (type == "Title") {
      items.sort((a, b) =>
          (int.tryParse(a.title) != null && int.tryParse(b.title) != null)
              ? int.parse(a.title).compareTo(int.parse(b.title))
              : a.title.compareTo(b.title));
    } else if (type == "Level") {
      items.sort((a, b) =>
          (int.tryParse(a.level) != null && int.tryParse(b.level) != null)
              ? int.parse(a.level).compareTo(int.parse(b.level))
              : a.level.compareTo(b.level));
    } else if (type == "Description") {
      items.sort((a, b) => (int.tryParse((a as Memo).details) != null &&
              int.tryParse((b as Memo).details) != null)
          ? int.parse((a).details).compareTo(int.parse((b).details))
          : (a).details.compareTo((b as Memo).details));
    } else {}
  }
}

////////////////////// Widgets
class ItemPage extends StatefulWidget {
  final _item, _levels;
  // ignore: use_key_in_widget_constructors
  const ItemPage(this._item, this._levels);
  @override
  _ItemPageState createState() => _ItemPageState(_item, _levels);
}

class _ItemPageState extends State<ItemPage> {
  final Memo _item;
  final _levels;
  bool _check = false;
  final cntTitle = TextEditingController();
  final cntLevel = TextEditingController();
  final cntDetails = TextEditingController();
  _ItemPageState(this._item, this._levels) {
    cntTitle.text = _item.title;
    cntLevel.text = _item.level;
    cntDetails.text = _item.details;
  }
  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    cntTitle.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  showDelDialog(context) {
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Confirm"),
      content: const Text("Would you like to remove item?"),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () {
            Navigator.pop(
              context,
            );
          },
        ),
        TextButton(
          child: const Text("Yes"),
          onPressed: () {
            Navigator.pop(
              context,
            );
            Navigator.pop(context, "del");
          },
        )
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_item.runtimeType}'),
        actions: [
          IconButton(
              icon: const Icon(Icons.done_outline_rounded),
              onPressed: () {
                Navigator.pop(context, _upd());
              }),
          IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () => showDelDialog(context))
        ],
      ),
      body: Center(
        child: Column(
          children: [
            TextField(
              controller: cntTitle,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            ListTile(
              trailing: PopupMenuButton(
                  icon: const Icon(Icons.more_horiz_rounded),
                  onSelected: (String newValue) {
                    setState(() {
                      cntLevel.text = newValue;
                    });
                  },
                  itemBuilder: (context) => [
                        for (String x in _levels)
                          PopupMenuItem(
                            value: x,
                            child: Text(x),
                          )
                      ]),
              title: TextField(
                controller: cntLevel,
                decoration: const InputDecoration(labelText: 'Level'),
              ),
            ),
            Expanded(
                child: TextField(
              controller: cntDetails,
              decoration: const InputDecoration(labelText: 'Details'),
              minLines: 5,
              maxLines: 10,
            )),
          ],
        ),
      ),
    );
  }

  _upd() {
    // ignore: unnecessary_type_check
    if (_item is Memo) {
      return Memo(
          details: cntDetails.text, title: cntTitle.text, level: cntLevel.text);
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: const HomePage(title: 'Simple notes'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key, this.title = ""}) : super(key: key);
  final String title;
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _searchBoolean = false; //add
  List<int> _searchIndexList = []; //add

  var notes = Notes();
  showItem(item) async {
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => ItemPage(item, notes.levels),
        ));
    if (result != null) {
      setState(() {
        if (result == "del") {
          notes.remove(item);
        } else {
          item.update(result);
        }
      });
    }
  }

  listItem(i, context) {
    final one = notes.item(i);

    if (one is Memo) {
      return ListTile(
        title: Text(one.title),
        subtitle: Text(one.level),
        trailing: Text(one.dateCreate.toString().substring(0, 10)),
        dense: true,
        onTap: () => showItem(one),
      );
    }
  }

  _HomePageState();

  @override
  void initState() {
    super.initState();
    (notes.load()).whenComplete(() => setState(() {}));
  }

  Widget _searchTextField() {
    return TextField(
        onChanged: (String smth) {
          //add
          setState(() {
            _searchIndexList = [];
            for (int i = 0; i < notes.count; i++) {
              if (notes.items[i].title.contains(smth) ||
                  notes.items[i].level.contains(smth) ||
                  (notes.items[i] as Memo).details.contains(smth)) {
                _searchIndexList.add(i);
              }
            }
          });
        },
        autofocus: true, //Display the keyboard when TextField is displayed
        cursorColor: Colors.white,
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
        ),
        textInputAction:
            TextInputAction.search, //Specify the action button on the keyboard
        decoration: InputDecoration(
          //Style of TextField
          enabledBorder: UnderlineInputBorder(
              //Default TextField border
              borderSide: BorderSide(color: Colors.white)),
          focusedBorder: UnderlineInputBorder(
              //Borders when a TextField is in focus
              borderSide: BorderSide(color: Colors.white)),
          hintText: 'Search', //Text that is displayed when nothing is entered.
          hintStyle: TextStyle(
            //Style of hintText
            color: Colors.white60,
            fontSize: 20,
          ),
        ));
  }

  searching() {}
  Widget _searchListView() {
    return ListView.builder(
        itemCount: _searchIndexList.length,
        itemBuilder: (context, index) {
          index = _searchIndexList[index];
          return Card(
              child: ListTile(
                  title: Text(notes.items[index].title),
                  subtitle: Text(notes.items[index].level)));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: !_searchBoolean ? Text(widget.title) : _searchTextField(),
            actions: !_searchBoolean
                ? [
                    IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          setState(() {
                            _searchBoolean = true;
                          });
                        }),
                    IconButton(
                        icon: const Icon(Icons.lightbulb),
                        onPressed: () {
                          Get.isDarkMode
                              ? Get.changeTheme(ThemeData.light())
                              : Get.changeTheme(ThemeData.dark());
                        })
                  ]
                : [
                    IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchBoolean = false;
                          });
                        })
                  ]),
        body: !_searchBoolean
            ? ListView.separated(
                separatorBuilder: (context, index) => const Divider(),
                itemCount: notes.count,
                itemBuilder: (context, i) => listItem(i, context),
              )
            : _searchListView(),
        drawer: Drawer(
            child: ListView(
          //itemExtent: 40.0,
          children: [
            const DrawerHeader(
              child: Text('Main menu'),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            const ListTile(title: Text('SORT')),
            for (var x in [...sorts])
              ListTile(
                title: Text(x),
                contentPadding: const EdgeInsets.only(left: 50),
                dense: true,
                onTap: () => setState(() {
                  Navigator.pop(context);
                  notes.sorting(x);
                }),
              ),
            const ListTile(title: Text('LEVELS')),
            for (var x in ["*", ...notes.levels])
              ListTile(
                title: Text(x),
                contentPadding: const EdgeInsets.only(left: 50),
                dense: true,
                selected: notes.filter == x,
                onTap: () => setState(() {
                  Navigator.pop(context);
                  notes.setFilter(x);
                }),
              ),
            const Divider(),
            ListTile(
                title: const Text('Save'),
                leading: const Icon(Icons.save_outlined),
                onTap: () {
                  notes.save();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Saved.'),
                    ),
                  );
                }),
            ListTile(
                title: const Text('Load'),
                leading: const Icon(Icons.file_upload),
                onTap: () async {
                  await notes.load();
                  setState(() {});
                }),
            const Divider(),
            const ListTile(title: Text('About...')),
          ],
        )),
        floatingActionButton:
            Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            FloatingActionButton(
              onPressed: () => showItem(notes.add<Memo>()),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15.0))),
              heroTag: 'memo',
              tooltip: 'new memo item',
              child: const Text('+memo'),
            ),
          ])
        ]));
  }
}

///////////////////////
void main() {
  runApp(const MyApp());
}
