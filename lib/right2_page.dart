import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// 導入模擬數據


class Right2Page extends StatefulWidget {
  const Right2Page({super.key});

  @override
  _RightPageState createState() => _RightPageState();
}

class _RightPageState extends State<Right2Page> {
  final String _responseText = 'Loading...';
  late Future<String> futureData ;

  @override
  void initState() {
    super.initState();
    futureData  = _fetchData();
  }

  Future<String> _fetchData() async {
    const apiUrl = 'http://localhost:8080/api/data'; // 確保這個 URL 與你的 Java 服務匹配
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      return response.body; // 直接返回原始響應體
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data from Java API'),
      ),
      body: Center(
        child: FutureBuilder<String>(
          future: futureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              // 這裡直接顯示原始數據
              return SingleChildScrollView(
                child: Text(snapshot.data!),
              );
            } else {
              return const Text('No data');
            }
          },
        ),
      ),
    );
  }
}