import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  Socket? _socket;
  Uint8List? _imageBytes;
  final BytesBuilder _buffer = BytesBuilder();
  bool _isConnected = false;

  String serverAddr = '';

  Socket? _controllerSocket;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  bool _isControllerConnected = false;

  Future<void> _controllerConnect() async {
    try {
      _controllerSocket = await Socket.connect(serverAddr, 8081);
      setState(() => _isControllerConnected = true);
      _showMessage('连接成功');

      _controllerSocket!.listen(
        (_) => {}, // 处理接收数据（如有需要）
        onError: (error) => _handleControllerDisconnect(),
        onDone: () => _handleControllerDisconnect(),
      );
    } catch (e) {
      _showMessage('连接失败: $e');
    }
  }

  void _controllerDisconnect() {
    _controllerSocket?.close();
    _handleControllerDisconnect();
  }

  void _handleControllerDisconnect() {
    if (_isControllerConnected) {
      setState(() => _isControllerConnected = false);
      _showMessage('已断开连接');
    }
  }

  void _sendCommand(String command) {
    if (_isControllerConnected && _controllerSocket != null) {
      try {
        _controllerSocket!.writeln(command);
        print('已发送: $command');
      } catch (e) {
        _showMessage('发送失败: $e');
        _controllerDisconnect();
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      serverAddr = prefs.getString('server_addr') ?? '';
    });
  }

  void _connectToServer(String ip, int port) async {
    try {
      _socket = await Socket.connect(ip, port);
      _isConnected = true;
      _socket!.listen(_onData, onError: _onError, onDone: _onDone);
    } catch (e) {
      _showMessage('连接失败: $e');
    }
  }

  void _onData(List<int> data) {
    _buffer.add(data);
    _processBuffer();
  }

  void _processBuffer() {
    while (true) {
      if (!_isConnected) {
        _buffer.clear();
        return;
      }
      final bytes = _buffer.toBytes();
      if (bytes.length < 4) {
        return; // 长度头不完整
      }

      // 读取小端格式的长度
      final lengthData = bytes.sublist(0, 4);
      final imageLength = ByteData.view(
        lengthData.buffer,
      ).getUint32(0, Endian.little);

      if (bytes.length < 4 + imageLength) {
        return; // 数据不完整
      }

      // 提取图像数据
      final imageData = bytes.sublist(4, 4 + imageLength);
      _updateImage(imageData);

      // 移除已处理的数据并继续处理
      _buffer.clear();
      if (bytes.length > 4 + imageLength) {
        _buffer.add(bytes.sublist(4 + imageLength));
      }
    }
  }

  void _updateImage(List<int> data) {
    if (!mounted) return;
    setState(() => _imageBytes = Uint8List.fromList(data));
  }

  void _onError(Object error) {
    _showMessage('发生错误: $error');
    _disconnect();
  }

  void _onDone() => _disconnect();

  void _disconnect() {
    _socket?.close();
    _socket?.destroy();
    if (mounted) {
      _buffer.clear();

      setState(() {
        _isConnected = false;
      });
    }
  }

  void _disconnectServer() {
    _disconnect();
    _controllerDisconnect();
  }

  void _connectServer() {
    _connectToServer(serverAddr, 8080);
    _controllerConnect();
  }

  @override
  void dispose() {
    _socket?.close();

    _controllerSocket?.close();
    super.dispose();
  }

  Widget _buildDirectionButton(String direction) {
    return GestureDetector(
      onTapDown: (_) => _sendCommand(direction),
      onTapUp: (_) => _sendCommand('STOP'),
      onTapCancel: () => _sendCommand('STOP'),
      child: Container(
        width: 100,
        height: 40,
        decoration: BoxDecoration(
          color: _isControllerConnected ? Colors.blue : Colors.grey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            direction,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Video"),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child:
                  _imageBytes != null
                      ? Image.memory(_imageBytes!, gaplessPlayback: true)
                      : Text(_isConnected ? '等待数据...' : '连接断开'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 40,
                  child: _buildDirectionButton('UP'),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 40,
                      child: _buildDirectionButton("LEFT"),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 70,
                        height: 70,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isControllerConnected
                                    ? Colors.red
                                    : Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                          onPressed:
                              () =>
                                  _isControllerConnected
                                      ? _disconnectServer()
                                      : _connectServer(),
                          child: Text(
                            _isControllerConnected ? '断开' : '连接',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      height: 40,
                      child: _buildDirectionButton("RIGHT"),
                    ),
                  ],
                ),
                SizedBox(
                  width: 100,
                  height: 40,
                  child: _buildDirectionButton("DOWN"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
