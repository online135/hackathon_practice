import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeftPage extends StatefulWidget {
  const LeftPage({super.key});

  @override
  _LeftPageState createState() => _LeftPageState();
}

class _LeftPageState extends State<LeftPage> {
  DateTime _selectedDate = DateTime.now();
  String _description = '';
  String _selectedOption = 'Option 1';
  final List<String> _options = ['Option 1', 'Option 2', 'Option 3'];

  @override
  void initState() {
    super.initState();
    _loadFormData();
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

  void _updateSelectedOption(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedOption = newValue;
        _saveFormData();
      });
    }
  }

  void _submitForm() {
    // 在這裡實現表單提交的邏輯
    print('Selected date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}');
    print('Description: $_description');
    print('Selected option: $_selectedOption');
    _clearFormData();
  }

  Future<void> _saveFormData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedDate', _selectedDate.toString());
    await prefs.setString('description', _description);
    await prefs.setString('selectedOption', _selectedOption);
  }

  Future<void> _loadFormData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedDate = DateTime.parse(prefs.getString('selectedDate') ?? _selectedDate.toString());
      _description = prefs.getString('description') ?? '';
      _selectedOption = prefs.getString('selectedOption') ?? 'Option 1';
    });
  }

  Future<void> _clearFormData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedDate');
    await prefs.remove('description');
    await prefs.remove('selectedOption');
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Left Page'),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Date'),
          const SizedBox(height: 8.0),
          ElevatedButton(
            onPressed: () => _selectDate(context),
            child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
          ),
          const SizedBox(height: 16.0),
          const Text('Description'),
          const SizedBox(height: 8.0),
          Expanded(
            child: TextField(
              maxLines: null,
              expands: true,
              minLines: null,
              onChanged: _updateDescription,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter description (max 20 characters)',
              ),
              controller: TextEditingController(text: _description),
            ),
          ),
          const SizedBox(height: 16.0),
          const Text('Select Option'),
          const SizedBox(height: 8.0),
          DropdownButton<String>(
            value: _selectedOption,
            onChanged: _updateSelectedOption,
            items: _options.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
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