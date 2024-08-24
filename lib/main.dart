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

  void _deleteIssueItem(issueItem) async {
    final response = await http.delete(
      Uri.parse('${baseUrl}api/issues/${issueItem['id']}'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Deletion successful, save the list locally
      _saveIssueList();
    } else {
      // Revert UI if backend deletion fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('無法刪除項目: ${issueItem['title']}')),
      );
    }

    setState(() {
      _issueList.removeWhere((item) => item['id'] == issueItem['id']);
    });
  }

  Widget _buildIssueListPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('市政通報追蹤'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Header Row
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                // Date
                SizedBox(
                  width: 100, // Adjust width to your needs
                  child: Text(
                    '日期',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 16), // Add spacing between date and category

                // Category
                SizedBox(
                  width: 100, // Adjust width to your needs
                  child: Text(
                    '類別',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 16), // Add spacing between category and title
              
                // Title
                SizedBox(
                  width: 150, // Adjust width to match your needs
                  child: Text(
                    '主旨',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.start, // Align the header text to the start
                  ),
                ),
                SizedBox(width: 16), // Add spacing between title and status

                // Status
                const SizedBox(
                  width: 80, // Adjust width to match the status column
                  child: Align(
                    alignment: Alignment.bottomRight, // Align the status header text to the bottom right
                    child: const Text(
                      '狀態',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )
                
              ],
            ),
          ),
          const Divider(thickness: 1), // Divider line below the header
          // Issue List
          Expanded(
            child: ListView.builder(
              itemCount: _issueList.length,
              itemBuilder: (context, index) {
                final issueItem = _issueList[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero, // Remove default padding
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
                    children: [
                      // Display Date
                      SizedBox(
                        width: 100, // Adjust width to match header width
                        child: Text(
                          issueItem['date'],
                          style: const TextStyle(fontWeight: FontWeight.normal),
                        ),
                      ),
                      const SizedBox(width: 16), // Add spacing between date and category

                      // Display Category
                      SizedBox(
                        width: 100, // Adjust width to match header width
                        child: Text(
                          issueItem['category'],
                          style: const TextStyle(fontWeight: FontWeight.normal),
                        ),
                      ),
                      const SizedBox(width: 16), // Add spacing between category and title

                      // Display Title
                      SizedBox(
                        child: Text(
                          issueItem['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis, // Truncate title with ellipsis if too long
                          textAlign: TextAlign.start, // Align the title to the start
                        ),
                      ),

                      // Display Status
                      SizedBox(
                        width: 80, // Adjust width to match the status column
                        child: Align(
                          alignment: Alignment.bottomRight,  // Align the status icon to the bottom right
                          child: _getStatusIcon(issueItem['status']),
                        ) 
                      ),
                    ],
                  ),
                  trailing: SizedBox(
                    width: 80, // Match the status column width
                    child: Align(
                      alignment: Alignment.bottomRight, // Align the status text to the bottom right
                      child: Text(
                        _getStatusText(issueItem['status']),
                        style: TextStyle(
                          color: _getStatusColor(issueItem['status']), // Status color
                        ),
                        textAlign: TextAlign.right, // Align text to the right
                      ),
                    )
                  ),
                  onTap: () {
                    _showIssueDetail(issueItem);
                  },
                  onLongPress: issueItem['status'] == 'UNPROCESSED'
                      ? () {
                          _showDeleteConfirmationDialog(issueItem);
                        }
                      : null, // Disable long press if not 'UNPROCESSED'
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPage() {
    return const AddPage();
  }

  Widget _buildExplainPage() {
    return const ExplainPage();
  }

  void _showIssueDetail(Map<String, dynamic> issueItem) async {
    final response = await http.get(Uri.parse('${baseUrl}api/issues/${issueItem['id']}'));
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
                      _showDeleteConfirmationDialog(issueItem);
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

  void _showDeleteConfirmationDialog(issueItem) {
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
                _deleteIssueItem(issueItem);
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
        return const Icon(Icons.circle, color: Colors.orange);
      case 'PROCESSING':
        return const Icon(Icons.circle, color: Colors.blue);
      case 'PROCESSED':
        return const Icon(Icons.circle, color: Colors.green);
      default:
        return const Icon(Icons.circle, color: Colors.grey);
    }
  }

  // 保持三個字的長度
  // Method to get the status text based on the status
  String _getStatusText(String status) {
    switch (status) {
      case 'UNPROCESSED':
        return '未處理';
      case 'PROCESSING':
        return '處理中';
      case 'PROCESSED':
        return '已處理';
      default:
        return 'Other';
    }
  }

  // Method to get the status color based on the status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'UNPROCESSED':
        return Colors.orange;
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'PROCESSED':
        return Colors.green;
      default:
        return Colors.grey;
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