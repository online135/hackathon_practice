import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'add_page.dart'; // 載入左頁 - 新增頁
import 'explain_page.dart'; // 載入右頁 - 說明頁
import 'config.dart'; // 導入配置檔案


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '市政通報追蹤',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const IssueListPage(),
    );
  }
}

class IssueListPage extends StatefulWidget {
  const IssueListPage({super.key});

  @override
  _IssueListPageState createState() => _IssueListPageState();
}

class _IssueListPageState extends State<IssueListPage> {
  int _selectedIndex = 1;
  List<Map<String, dynamic>> _issueList = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadIssueList();
  }

  Future<void> _loadIssueList() async {
    final response = await http.get(Uri.parse('${baseUrl}api/issues'));

    if (response.statusCode == 200) {
      final List<dynamic> issueListJson  = json.decode(response.body);
      setState(() {
        _issueList = issueListJson.map((item) {
          return {
            'category': item['category'],
            'title': item['title'],
            'date': item['date'],
            'description': item['description'],
            'completed': item['completed'],
          };
        }).toList();
      });
    } else {
      throw Exception('無法載入通報列表');
    }
  }

  Future<void> _saveIssueList() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('issueList', json.encode(_issueList));
  }

  Future<void> _sendIssueListToBackend() async {
    final url = Uri.parse('${baseUrl}api/issues');
    for (var issueItem in _issueList) {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(issueItem),
      );
    }
  }

  void _deleteIssueItem(int index) {
    setState(() {
      _issueList.removeAt(index);
    });
    _saveIssueList();
    _sendIssueListToBackend();
  }

  Widget _buildIssueListPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('市政通報追蹤'),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        itemCount: _issueList.length,
        itemBuilder: (context, index) {
          final issueItem = _issueList[index];
          return ListTile(
            title: Text(
              issueItem['title'],
              style: TextStyle(
                decoration: issueItem['completed']
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            leading: Icon(
              issueItem['completed'] ? Icons.check_circle_outline : Icons.radio_button_unchecked,
              color: issueItem['completed'] ? Colors.grey : Colors.blue,
            ),
            trailing: issueItem['status'] == '未處理' 
             ?  IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _deleteIssueItem(index);
                  },
                )
              : Icon(
                Icons.delete,
                color: Colors.grey, // 顯示灰色的刪除圖標，但不可點擊
              )
          );
        },
      )
    );
  }

  Widget _buildAddPage() {
    return const AddPage();
  }

  Widget _buildExplainPage() {
    return const ExplainPage();
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
          _buildAddPage(), // 左邊的頁面 - 新增
          _buildIssueListPage(), // 中間的 Home 頁面
          _buildExplainPage(), // 右邊的頁面 - 說明
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: '新增',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '列表',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: '說明',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}