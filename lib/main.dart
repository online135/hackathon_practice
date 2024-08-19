import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<Map<String, dynamic>> _todoList = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTodoList();
  }

  Future<void> _loadTodoList() async {
    final prefs = await SharedPreferences.getInstance();
    final String? todoListString = prefs.getString('todoList');
    if (todoListString != null) {
      setState(() {
        _todoList = List<Map<String, dynamic>>.from(
          json.decode(todoListString) as List,
        );
      });
    }
  }

  Future<void> _saveTodoList() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('todoList', json.encode(_todoList));
  }

  void _addTodoItem(String title) {
    setState(() {
      _todoList.add({'title': title, 'completed': false});
    });
    _controller.clear();
    _saveTodoList();
  }

  void _toggleTodoItem(int index) {
    setState(() {
      _todoList[index]['completed'] = !_todoList[index]['completed'];
    });
    _saveTodoList();
  }

  void _deleteTodoItem(int index) {
    setState(() {
      _todoList.removeAt(index);
    });
    _saveTodoList();
  }

  void _showAddTodoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add a new task'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: 'Enter task title'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  _addTodoItem(_controller.text);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
      ),
      body: ListView.builder(
        itemCount: _todoList.length,
        itemBuilder: (context, index) {
          final todoItem = _todoList[index];
          return ListTile(
            title: Text(
              todoItem['title'],
              style: TextStyle(
                decoration: todoItem['completed']
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            leading: Switch(
              value: todoItem['completed'],
              onChanged: (value) {
                _toggleTodoItem(index);
              },
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _deleteTodoItem(index);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}