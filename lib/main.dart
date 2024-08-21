import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'second_page.dart'; // 載入第二頁

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1;
  List<Map<String, dynamic>> _todoList = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTodoList();
  }

  Future<void> _loadTodoList() async {
    final response = await http.get(Uri.parse('http://your-backend-url.com/api/todos'));

    if (response.statusCode == 200) {
      final List<dynamic> todoListJson = json.decode(response.body);
      setState(() {
        _todoList = todoListJson.map((item) {
          return {
            'title': item['title'],
            'completed': item['completed'],
          };
        }).toList();
      });
    } else {
      throw Exception('Failed to load todos');
    }
  }

  Future<void> _saveTodoList() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('todoList', json.encode(_todoList));
  }

  Future<void> _sendTodoListToBackend() async {
    final url = Uri.parse('http://your-backend-url.com/api/todos');
    for (var todoItem in _todoList) {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(todoItem),
      );
    }
  }

  void _addTodoItem(String title) {
    setState(() {
      _todoList.add({'title': title, 'completed': false});
    });
    _controller.clear();
    _saveTodoList();
    _sendTodoListToBackend();  // 保存後發送資料到後端
  }

  void _toggleTodoItem(int index) {
    setState(() {
      _todoList[index]['completed'] = !_todoList[index]['completed'];
    });
    _saveTodoList();
    _sendTodoListToBackend();  // 切換完成狀態後發送資料到後端
  }

  void _deleteTodoItem(int index) {
    setState(() {
      _todoList.removeAt(index);
    });
    _saveTodoList();
    _sendTodoListToBackend();  // 刪除後發送資料到後端
  }

  void _showAddTodoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add a new task'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Enter task title'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  _addTodoItem(_controller.text);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodoListPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SecondPage()),
              );
            },
          ),
        ],
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
              icon: const Icon(Icons.delete),
              onPressed: () {
                _deleteTodoItem(index);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLeftPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Left Page'),
      ),
      body: const Center(
        child: Text(
          'This is the left page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  Widget _buildRightPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Right Page'),
      ),
      body: const Center(
        child: Text(
          'This is the right page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildLeftPage(), // 左邊的頁面
          _buildTodoListPage(), // 中間的 Home 頁面
          _buildRightPage(), // 右邊的頁面
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_back),
            label: 'Page 1',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_forward),
            label: 'Page 3',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
