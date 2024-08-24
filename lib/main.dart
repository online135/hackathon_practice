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
            'id': item['id'],
            'category': item['category'],
            'title': item['title'],
            'date': item['date'],
            'description': item['description'],
            'status': item['status'],
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

  void _deleteIssueItem(int index) async {
    final issueItem = _issueList[index];

    // Optimistic UI Update: Remove the item immediately
    setState(() {
      _issueList.removeAt(index);
    });

    final response = await http.delete(
      Uri.parse('${baseUrl}api/issue/${issueItem['id']}'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Deletion successful, save the list locally
      _saveIssueList();
    } else {
      // Revert UI if backend deletion fails
      setState(() {
        _issueList.insert(index, issueItem);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('無法刪除項目: ${issueItem['title']}')),
      );
    }
  }

  Widget _buildIssueListPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '市政通報追蹤'
            ),
          ],
        ),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        itemCount: _issueList.length,
        itemBuilder: (context, index) {
          final issueItem = _issueList[index];
          return ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issueItem['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('類別: ${issueItem['category']}'),
                Text('日期: ${issueItem['date']}'),
              ],
            ),
            trailing: _getStatusIcon(issueItem['status']) // 顯示圖標和文字描述
            , // 顯示不同的圖標根據 status
            onTap: () {
              _showIssueDetail(issueItem);
            },
            onLongPress: issueItem['status'] == 'UNPROCESSED'
                ? () {
                    _showDeleteConfirmationDialog(index);
                  }
                : null, // Disable long press if not 'UNPROCESSED'
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

  void _showIssueDetail(Map<String, dynamic> issueItem) async {
    final response = await http.get(Uri.parse('${baseUrl}api/issue/${issueItem['id']}'));
    if (response.statusCode == 200) {
      final issueDetail = json.decode(response.body);
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(issueDetail['title']),
                if (issueDetail['status'] == 'UNPROCESSED') 
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      _showDeleteConfirmationDialog(issueDetail['id']);
                    },
                  ),
              ],
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('類別: ${issueDetail['category']}'),
                Text('日期: ${issueDetail['date']}'),
                const SizedBox(height: 8),
                Text('描述: ${issueDetail['description']}'),
                const SizedBox(height: 8),
                Text('狀態: ${issueDetail['status']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('關閉'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('無法載入通報詳情: ${issueItem['title']}')),
      );
    }
  }

  void _showDeleteConfirmationDialog(int index) {
    final issueItem = _issueList[index];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('刪除通報'),
          content: Text('您確定要刪除 ${issueItem['title']} 嗎？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                _deleteIssueItem(index);
                Navigator.of(context).pop();
              },
              child: const Text('刪除'),
            ),
          ],
        );
      },
    );
  }

 Widget _getStatusIcon(String status) {
    switch (status) {
      case 'UNPROCESSED':
        return const Icon(Icons.circle, color: Colors.red);
      case 'PROCESSING':
        return const Icon(Icons.circle, color: Colors.orange);
      case 'PROCESSED':
        return const Icon(Icons.circle, color: Colors.green);
      default:
        return const Icon(Icons.circle, color: Colors.grey);
    }
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