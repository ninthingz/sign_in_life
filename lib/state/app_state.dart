// lib/states/app_state.dart
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

class AppState extends ChangeNotifier {
  // 蓝牙连接相关状态
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? get writeCharacteristic => _writeCharacteristic;
  final List<Message> _messages = [];

  // 需要全局共享的业务数据（示例：电池状态）
  BatteryStatus? _batteryStatus;
  BatteryStatus? get batteryStatus => _batteryStatus;

  // Getter 方法
  BluetoothDevice? get connectedDevice => _connectedDevice;
  List<Message> get messages => _messages;

  // 状态更新方法
  void updateBatteryStatus(BatteryStatus status) {
    _batteryStatus = status;
    notifyListeners();
  }

  void addMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }

  void setConnectedDevice(BluetoothDevice? device) {
    _connectedDevice = device;
    notifyListeners();
  }

  void setWriteCharacteristic(BluetoothCharacteristic? characteristic) {
    _writeCharacteristic = characteristic;
  }

  // 处理接收到的蓝牙数据
  void handleReceivedData(Uint8List data) {
    if (data.isEmpty) return;

    try {
      final message = BinaryDeserializer.parseMessage(data);

      if (message is BatteryStatus) {
        final status = '''
电池状态更新:
电量: ${message.level}%
状态: ${message.status}
电压: ${message.voltage / 1000}V
温度: ${message.temperature / 10}℃
''';
        updateBatteryStatus(message);
        addMessage(Message(status, false));
      }
    } catch (e) {
      addMessage(Message('解析错误: $e', false));
    }
  }
}
