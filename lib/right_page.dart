import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'mock_data.dart'; // 導入模擬數據
import 'right2_page.dart'; // 導入模擬數據


class RightPage extends StatefulWidget {
  const RightPage({super.key});

  @override
  _RightPageState createState() => _RightPageState();
}

class _RightPageState extends State<RightPage> {
  final String _responseText = 'Loading...';
  late Future<List<Toilet>> futureToilets;

  @override
  void initState() {
    super.initState();
    futureToilets  = _fetchData();
  }

  Future<List<Toilet>> _fetchData() async {
    // 使用模擬數據而不是實際的 API 調用
    await Future.delayed(const Duration(seconds: 1)); // 模擬網絡延遲
    final jsonData = jsonDecode(mockApiResponse);
    final results = jsonData['result']['results'] as List;
    return results.map((toiletData) => Toilet.fromJson(toiletData)).toList();


    // 只能用在開發模式
    // final corsProxyUrl = 'https://cors-anywhere.herokuapp.com/';
    // final apiUrl = 'https://data.taipei/api/v1/dataset/9e0e6ad4-b9f9-4810-8551-0cffd1b915b3?scope=resourceAquire';
    // final response = await http.get(Uri.parse(corsProxyUrl + apiUrl));

    // if (response.statusCode == 200) {
    //   final jsonData = jsonDecode(response.body);
    //   final results = jsonData['result']['results'] as List;
    //   return results.map((toiletData) => Toilet.fromJson(toiletData)).toList();
    // } else {
    //   throw Exception('Failed to load toilets');
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taipei Public Toilets'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to Right Page!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 5),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Right2Page()),
                );
              },
              child: const Text('Go to Right2 Page'),
            ),
            Expanded(
              child: FutureBuilder<List<Toilet>>(
                future: futureToilets,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final toilet = snapshot.data![index];
                        return ListTile(
                          title: Text(toilet.name),
                          subtitle: Text('${toilet.district} - ${toilet.category}'),
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  return const CircularProgressIndicator();
                },
              ),
            ),
          ],
        )
      ),
    );
  }
}

class Toilet {
  final int id;
  final String district;
  final String category;
  final String name;
  final String address;
  final String longitude;
  final String latitude;

  const Toilet({
    required this.id,
    required this.district,
    required this.category,
    required this.name,
    required this.address,
    required this.longitude,
    required this.latitude,
  });

  factory Toilet.fromJson(Map<String, dynamic> json) {
    return Toilet(
      id: json['_id'],
      district: json['行政區'],
      category: json['公廁類別'],
      name: json['公廁名稱'],
      address: json['公廁地址'],
      longitude: json['經度'],
      latitude: json['緯度'],
    );
  }
}