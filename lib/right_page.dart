import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'mock_data.dart'; // 導入模擬數據

class RightPage extends StatefulWidget {
  const RightPage({super.key});

  @override
  _RightPageState createState() => _RightPageState();
}

class _RightPageState extends State<RightPage> {
  String _responseText = 'Loading...';
  late Future<List<Toilet>> futureToilets;

  @override
  void initState() {
    super.initState();
    futureToilets  = _fetchData();
  }

  Future<List<Toilet>> _fetchData() async {
    // 使用模擬數據而不是實際的 API 調用
    await Future.delayed(Duration(seconds: 1)); // 模擬網絡延遲
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
    return MaterialApp(
      title: 'Taipei Public Toilets',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Taipei Public Toilets'),
        ),
        body: Center(
          child: FutureBuilder<List<Toilet>>(
            future: futureToilets, // 呼叫一個變數 futureAlbum, futureAlbum 再呼叫 _fetchData() 去抓資料
            builder: (context, snapshot) { // 資料會存在 snapshot 裡面(此時已經是 json object Album, 為什麼是 json 要看 _fetchData() )
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

              // By default, show a loading spinner.
              return const CircularProgressIndicator();
            },
          ),
        ),
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