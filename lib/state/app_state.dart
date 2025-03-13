import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  // 示例数据：计数器
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners(); // 通知监听者状态已更新
  }

  // 添加其他需要共享的状态和方法...
}
