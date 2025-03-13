import 'package:flutter/material.dart';
import 'package:sign_in_life/protocol/binary_protocol.dart';

class BatteryPage extends StatefulWidget {
  const BatteryPage({super.key});

  @override
  State<BatteryPage> createState() => _BatteryPageState();
}

class _BatteryPageState extends State<BatteryPage> {
  BatteryStatus? _batteryStatus;

  @override
  void initState() {
    super.initState();
    // 初始化状态
    _batteryStatus = BatteryStatus(
      level: 50,
      status: ChargingStatus.charging,
      voltage: 3800,
      temperature: 250,
    );
  }

  // 暴露给外部的状态更新接口
  void updateBatteryStatus(BatteryStatus newStatus) {
    setState(() {
      _batteryStatus = newStatus;
    });
  }

  Color _getBatteryColor(int level) {
    if (level < 20) return Colors.red;
    if (level < 50) return Colors.orange;
    return Colors.green;
  }

  Widget _buildBatteryIcon() {
    if (_batteryStatus == null) {
      return CircularProgressIndicator();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        Positioned(
          top: 4,
          bottom: 4,
          left: 4,
          right: 4,
          child: Container(
            decoration: BoxDecoration(
              color: _getBatteryColor(_batteryStatus!.level).withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Positioned(
          bottom: _batteryStatus!.level.toDouble() * 1.8,
          child: Container(
            height: 200 * _batteryStatus!.level / 100 - 8,
            color: _getBatteryColor(_batteryStatus!.level),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_batteryStatus!.level}%',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_batteryStatus!.status == ChargingStatus.charging)
              Icon(Icons.bolt, color: Colors.white, size: 32),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusInfo() {
    if (_batteryStatus == null) return SizedBox();

    return Column(
      children: [
        Text(
          '电压: ${_batteryStatus!.voltage} mV',
          style: TextStyle(color: Colors.white),
        ),
        Text(
          '温度: ${_batteryStatus!.temperature / 10} ℃',
          style: TextStyle(color: Colors.white),
        ),
        SizedBox(height: 20),
        Text(
          _batteryStatus!.status.toString().split('.').last,
          style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBatteryIcon(),
            SizedBox(height: 40),
            _buildStatusInfo(),
          ],
        ),
      ),
    );
  }
}

// 使用示例：
// class MyApp extends StatelessWidget {
//   final _batteryDisplayKey = GlobalKey<_BatteryDisplayState>();
//
//   void _updateStatus() {
//     final newStatus = BatteryStatus(
//       level: 75,
//       status: ChargingStatus.charging,
//       voltage: 4200,
//       temperature: 256,
//     );
//     _batteryDisplayKey.currentState?.updateBatteryStatus(newStatus);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         body: BatteryDisplay(key: _batteryDisplayKey),
//         floatingActionButton: FloatingActionButton(
//           onPressed: _updateStatus,
//           child: Icon(Icons.refresh),
//         ),
//       ),
//     );
//   }
// }
