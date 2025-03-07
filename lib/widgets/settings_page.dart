import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _serverController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  } // 保存数据方法

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_addr', _serverController.text);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverController.text = prefs.getString('server_addr') ?? '';
    });
  }

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _serverController,
              decoration: const InputDecoration(
                labelText: '服务器地址',
                hintText: '请输入服务器地址',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // 在这里处理服务器地址变化
                _saveData();
                print('服务器地址: $value');
              },
            ),
          ],
        ),
      ),
    );
  }
}
