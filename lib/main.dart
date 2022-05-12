// ignore_for_file: prefer_typing_uninitialized_variables, avoid_print, unnecessary_this

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

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

class Todo extends Memo with Check {
  Todo({isDone = false, details = '', title = '', level = 'none'})
      : super(title: title, level: level) {
    done = isDone;
  }
  @override
  update(other) {
    super.update(other);
    this.done = other.done;
  }

  @override
  toString() => "todo||$done||$title||$level||$details";
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
    print("load from $directory");
    final file = File(directory.path + "/notes.json");
    items.clear();
    for (String x in file.readAsLinesSync()) {
      print(x);
      var s = x.split("||");
      switch (s[0]) {
        case "todo":
          items.add(Todo(
              isDone: s[1] == "true", title: s[2], level: s[3], details: s[4]));
          break;
        case "memo":
          items.add(Memo(title: s[1], level: s[2], details: s[3]));
      }
    }
    print("load end");
  }

  save() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      print("save to $directory");
      final file = File(directory.path + "/notes.json");
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
    final factories = <Type, Function>{Memo: () => Memo(), Todo: () => Todo()};
    final one = (factories[T]!)();
    items.add(one);
    return one;
  }

  sorting(String type) {
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
    if (_item is Todo) _check = (_item as Todo).done;
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
            if (_item is Todo)
              CheckboxListTile(
                value: _check,
                title: const Text("Done"),
                onChanged: (chk) {
                  setState(() {
                    _check = chk!;
                  });
                },
              ),
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
    if (_item is Todo) {
      return Todo(
          isDone: _check,
          details: cntDetails.text,
          title: cntTitle.text,
          level: cntLevel.text);
    }
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
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: 'Simple notes'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key? key, this.title = ""}) : super(key: key);
  final String title;
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController editingController = TextEditingController();

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
    if (one is Todo) {
      return ListTile(
        leading: Icon(
          Icons.done,
          color: one.done ? Colors.lightGreen : Colors.white,
        ),
        title: Text(one.title),
        subtitle: Text(one.level),
        trailing: Text(one.dateCreate.toString().substring(0, 10)),
        dense: true,
        onTap: () => showItem(one),
      );
    }
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

  searching() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            // Navigate to the Search Screen
            IconButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchPage())),
                icon: const Icon(Icons.search))
          ],
        ),
        body: ListView.separated(
          separatorBuilder: (context, index) => const Divider(),
          itemCount: notes.count,
          itemBuilder: (context, i) => listItem(i, context),
        ),
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
            FloatingActionButton(
              onPressed: () => showItem(notes.add<Todo>()),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15.0))),
              heroTag: 'todo',
              tooltip: 'new todo item',
              child: const Text('+todo'),
            )
          ])
        ]));
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          // The search area here
          title: Container(
        width: double.infinity,
        height: 40,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(5)),
        child: Center(
          child: TextField(
            decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    /* Clear the search field */
                  },
                ),
                hintText: 'Search...',
                border: InputBorder.none),
          ),
        ),
      )),
    );
  }
}

///////////////////////
void main() {
  runApp(const MyApp());
}
