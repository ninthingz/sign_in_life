// lib/pages/ble_page.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_life/state/app_state.dart';

class BlePage extends StatefulWidget {
  const BlePage({super.key});

  @override
  State<BlePage> createState() => _BlePageState();
}

class _BlePageState extends State<BlePage> {
  final String _serviceUuid = "04402a2b-6a6d-e2f4-ac79-3eb90974c30a";
  final String _readCharUuid = "cf0fd776-bf2a-3f3b-d763-7369c17ba1e0";
  final String _writeCharUuid = "1b9df75a-b25d-6617-9f17-125de428cc38";

  late TextEditingController _textController;
  final List<BluetoothDevice> _foundDevices = [];
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
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
    }, onError: (e) => _showError(context, "Scan error: $e"));

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
    final appState = Provider.of<AppState>(context, listen: false);
    _stopScan();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await device.connect(autoConnect: false);
      appState.setConnectedDevice(device);

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
      _showError(context, "连接失败: ${e.toString()}");
    }
  }

  void _disconnect(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.connectedDevice?.disconnect();
    appState.setConnectedDevice(null);
    appState.setWriteCharacteristic(null);
  }

  void _setupCharacteristics(BluetoothService service) {
    final appState = Provider.of<AppState>(context, listen: false);

    for (var characteristic in service.characteristics) {
      if (characteristic.uuid.toString().toLowerCase() == _readCharUuid) {
        characteristic.setNotifyValue(true);
        characteristic.lastValueStream.listen((value) {
          appState.handleReceivedData(Uint8List.fromList(value));
        });
      }
      if (characteristic.uuid.toString().toLowerCase() == _writeCharUuid) {
        appState.setWriteCharacteristic(characteristic);
      }
    }
  }

  void _sendMessage(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    String text = _textController.text;
    if (text.isEmpty || appState.writeCharacteristic == null) return;

    text = "s$text"; // 添加协议前缀
    try {
      await appState.writeCharacteristic!.write(text.codeUnits);
      appState.addMessage(Message(text, true));
      _textController.clear();
    } catch (e) {
      _showError(context, "Send failed: ${e.toString()}");
    }
  }

  void _showError(BuildContext context, String message) {
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

  Widget _buildChatInterface(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: appState.messages.length,
            itemBuilder: (context, index) {
              final message = appState.messages[index];
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
                  onSubmitted: (_) => _sendMessage(context),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                color: Colors.blue,
                onPressed: () => _sendMessage(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return IconButton(
      icon: const Icon(Icons.link_off),
      onPressed:
          appState.connectedDevice != null ? () => _disconnect(context) : null,
    );
  }

  Widget _buildScanningInterface(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child:
                _foundDevices.isEmpty
                    ? const Center(child: Text("No devices found"))
                    : _buildDeviceList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isScanning ? null : () => _startScan(),
            child: Text(_isScanning ? "Scanning..." : "Start Scan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    BluetoothDevice? connectedDevice =
        context.watch<AppState>().connectedDevice;

    return Scaffold(
      appBar: AppBar(
        title: const Text('蓝牙管理'),
        actions: [_buildConnectionStatus(context)],
      ),
      body:
          connectedDevice == null
              ? _buildScanningInterface(context)
              : _buildChatInterface(context),
      floatingActionButton: connectedDevice == null ? _buildScanButton() : null,
    );
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _textController.dispose();
    super.dispose();
  }
}
