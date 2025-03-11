import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:sign_in_life/protocol/binary_deserializer.dart';
import 'package:sign_in_life/protocol/binary_protocol.dart';

class Message {
  final String content;
  final bool isSent;

  Message(this.content, this.isSent);
}

class BlePage extends StatefulWidget {
  const BlePage({super.key});

  @override
  State<BlePage> createState() => _BlePageState();
}

class _BlePageState extends State<BlePage> {
  final String _serviceUuid = "04402a2b-6a6d-e2f4-ac79-3eb90974c30a";
  final String _readCharUuid = "cf0fd776-bf2a-3f3b-d763-7369c17ba1e0";
  final String _writeCharUuid = "1b9df75a-b25d-6617-9f17-125de428cc38";

  final TextEditingController _textController = TextEditingController();
  final List<Message> _messages = [];
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;

  // 新增状态管理
  bool _isScanning = false;
  List<BluetoothDevice> _foundDevices = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await FlutterBluePlus.turnOn();
    // 检查并请求必要权限
    if (await FlutterBluePlus.isAvailable == false) {
      print("蓝牙不可用");
      return;
    }
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _foundDevices.clear();
    });

    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      _updateDeviceList(results);
    }, onError: (e) => print("扫描错误: $e"));

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  void _stopScan() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    setState(() => _isScanning = false);
  }

  void _updateDeviceList(List<ScanResult> results) {
    final newDevices =
        results
            .where((r) => r.device.platformName.isNotEmpty)
            .map((r) => r.device)
            .where((d) => !_foundDevices.contains(d))
            .toList();

    if (newDevices.isNotEmpty) {
      setState(() {
        _foundDevices.addAll(newDevices);
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _stopScan();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await device.connect(autoConnect: false);
      setState(() => _connectedDevice = device);

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == _serviceUuid) {
          _setupCharacteristics(service);
          break;
        }
      }
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      _showError("连接失败: ${e.toString()}");
    }
  }

  void _disconnect() {
    _connectedDevice?.disconnect();
    setState(() {
      _connectedDevice = null;
      _writeCharacteristic = null;
    });
  }

  void handleReceivedData(Uint8List data) {
    if (data.isEmpty) return;
    try {
      final message = BinaryDeserializer.parseMessage(data);

      if (message is BatteryStatus) {
        _addMessage('''
Received Battery Status:
Level: ${message.level}%
Status: ${message.status}
Voltage: ${message.voltage / 1000}V
Temperature: ${message.temperature / 10}℃
''', false);
      }
    } catch (e) {
      _addMessage('Parse error: $e', false);
    }
  }

  void _setupCharacteristics(BluetoothService service) {
    for (var characteristic in service.characteristics) {
      if (characteristic.uuid.toString().toLowerCase() == _readCharUuid) {
        characteristic.setNotifyValue(true);
        characteristic.lastValueStream.listen((value) {
          handleReceivedData(Uint8List.fromList(value));
        });
      }
      if (characteristic.uuid.toString().toLowerCase() == _writeCharUuid) {
        _writeCharacteristic = characteristic;
      }
    }
  }

  void _addMessage(String text, bool isSent) {
    setState(() {
      _messages.add(Message(text, isSent));
    });
  }

  void _sendMessage() async {
    String text = _textController.text;
    if (text.isEmpty || _writeCharacteristic == null) return;

    try {
      await _writeCharacteristic!.write(text.codeUnits);
      _addMessage(text, true);
      _textController.clear();
    } catch (e) {
      _showError("发送失败: ${e.toString()}");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildDeviceList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _foundDevices.length,
      itemBuilder: (context, index) {
        final device = _foundDevices[index];
        return ListTile(
          leading: const Icon(Icons.bluetooth),
          title: Text(device.platformName),
          subtitle: Text(device.remoteId.toString()),
          trailing:
              _isScanning
                  ? const Icon(Icons.wifi_find_outlined)
                  : const SizedBox.shrink(),
          onTap: () => _connectToDevice(device),
        );
      },
    );
  }

  Widget _buildScanButton() {
    return FloatingActionButton(
      onPressed: _isScanning ? _stopScan : _startScan,
      tooltip: '扫描设备',
      child: Icon(_isScanning ? Icons.stop : Icons.search),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('蓝牙聊天'),
        actions: [
          if (_connectedDevice != null)
            IconButton(
              icon: const Icon(Icons.link_off),
              onPressed: _disconnect,
            ),
        ],
      ),
      body:
          _connectedDevice == null
              ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                      child:
                          _foundDevices.isEmpty
                              ? const Center(child: Text("未发现设备"))
                              : _buildDeviceList(),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isScanning ? null : _startScan,
                      child: Text(_isScanning ? "扫描中..." : "开始扫描"),
                    ),
                  ],
                ),
              )
              : _buildChatInterface(),
      floatingActionButton:
          _connectedDevice == null ? _buildScanButton() : null,
    );
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return Align(
                alignment:
                    message.isSent
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isSent ? Colors.blue[100] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(message.content),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: '输入消息...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                color: Colors.blue,
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectedDevice?.disconnect();
    super.dispose();
  }
}
