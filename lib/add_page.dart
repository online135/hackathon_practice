import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart'; // 導入配置檔案

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  // final List<String> _categories = [
  //   '垃圾、噪音、汙染及資源回收', 
  //   '道路、山坡地、樹路及路燈', 
  //   '公園、排水溝、下水道及自來水',
  // ];

  final List<String> _categories = [
    'A', 
    'B', 
    'C',
  ];

  String _category = 'A';
  String _title = '';
  DateTime _selectedDate = DateTime.now();
  String _description = '';

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  void _updateSelectedCategory(String? newValue) {
    if (newValue != null) {
      setState(() {
        _category = newValue;
        _saveFormData();
      });
    }
  }

  void _updateTitle (String value) {
    setState(() {
      _title = value;
      _saveFormData();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _saveFormData();
      });
    }
  }

  void _updateDescription(String value) {
    setState(() {
      _description = value;
      _saveFormData();
    });
  }

  void _submitForm() async {
    // 確認所有欄位不為空，且敘述不少於10個字
    if (_category.isEmpty ||
        _title.isEmpty ||
        _title.length < 3 ||
        _description.isEmpty ||
        _description.length < 10
    ) {
      print('所有欄位必須填寫且描述不少於10個字');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請填寫所有欄位且描述不少於10個字，標題不小於3個字')),
      );
      return; // 中止發送
    }

    final url = Uri.parse('${baseUrl}api/issues'); // Replace with your server's IP address or hostname

    final Map<String, dynamic> data = {
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'category': _category,
      'title': _title,
      'description': _description,
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      print('資料傳送成功');
      _clearFormData();
    } else {
      print('資料傳送失敗');
    }
  }

  Future<void> _saveFormData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('category', _category);
    await prefs.setString('title', _title);
    await prefs.setString('date', _selectedDate.toString());
    await prefs.setString('description', _description);
  }

  Future<void> _loadFormData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _category = prefs.getString('category') ?? _category;
      _title = prefs.getString('title') ?? '';
      _selectedDate = DateTime.parse(prefs.getString('date') ?? _selectedDate.toString());
      _description = prefs.getString('description') ?? '';
    });
  }

  Future<void> _clearFormData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('category');
    await prefs.remove('title');
    await prefs.remove('date');
    await prefs.remove('description');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新增頁'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 案件類別: Category
            const Text('請選擇案件類別'),
            const SizedBox(height: 8.0),

            DropdownButton<String>(
              hint: Text(
                '案件類別',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).hintColor,
                ),
              ),
              value: _category.isNotEmpty ? _category : _categories.first,
              onChanged: _updateSelectedCategory,
              items: _categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 16.0),

            // 案件主旨
            const Text('案件主旨'),
            const SizedBox(height: 8.0),

            TextField(
              onChanged: _updateTitle,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '請輸入主旨',
              ), 
              maxLines: 1,
            ),
            const SizedBox(height: 16.0),

            // 案件日期: date
            const Text('案件日期'),
            const SizedBox(height: 8.0),

            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
            ),
            const SizedBox(height: 16.0),

            const Text('描述'),
            const SizedBox(height: 8.0),

            Expanded(
              child: TextField(
                maxLines: null,
                expands: true,
                minLines: null,
                onChanged: _updateDescription,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '人、事、時、地、物 4000字以內',
                ),
                controller: TextEditingController(text: _description),
              ),
            ),
            const SizedBox(height: 16.0),
            
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}