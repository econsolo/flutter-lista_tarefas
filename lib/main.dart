import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home()
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  @override
  void initState() {
    super.initState();

    _readData().then((dados) {
      setState(() {
        _toDoList = json.decode(dados);
      });
    });
  }

  final _controller = TextEditingController();

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _controller.text;
      newToDo["done"] = false;
      _controller.text = "";
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(milliseconds: 1500));

    setState(() {
      _toDoList.sort((a, b) {
        if (a["done"] && !b["done"]) return 1;
        else if (!a["done"] && b["done"]) return -1;
        else return 0;
      });

      _saveData();
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(
                            color: Colors.blueAccent
                        )
                    )
                  )
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Icon(Icons.save, color: Colors.white),
                  onPressed: _addToDo
                )
              ]
            )
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem
              )
            )
          )
        ]
      )
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.redAccent,
        child: Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(Icons.delete_forever, color: Colors.white)
        )
      ),
      direction: DismissDirection.startToEnd,
      onDismissed: (dir) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();
          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              }
            )
          );

          Scaffold.of(context).showSnackBar(snack);
        });
      },
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["done"],
        secondary: CircleAvatar(
          child: Icon(
            _toDoList[index]["done"] ? Icons.check : Icons.error
          )
        ),
        onChanged: (checked) {
          setState(() {
            _toDoList[index]["done"] = checked;
            _saveData();
          });
        }
      )
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String dados = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(dados);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}



