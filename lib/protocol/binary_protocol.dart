// 协议头结构
class ProtocolHeader {
  final int version; // 1字节
  final MessageType type; // 1字节
  final int payloadSize; // 2字节
  final int timestamp; // 4字节

  static const int headerSize = 1 + 1 + 2 + 4;

  ProtocolHeader({
    required this.version,
    required this.type,
    required this.payloadSize,
    required this.timestamp,
  });
}

// 消息类型枚举
enum MessageType {
  batteryStatus(0x01),
  deviceControl(0x02),
  unknown(0xFF);

  final int value;
  const MessageType(this.value);

  static MessageType fromValue(int value) {
    return MessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageType.unknown,
    );
  }
}

// 电池状态结构
class BatteryStatus {
  final int level; // 1字节 (0-100)
  final ChargingStatus status; // 1字节
  final int voltage; // 2字节 (mV)
  final int temperature; // 2字节 (0.1℃)

  static const int size = 1 + 1 + 2 + 2;

  BatteryStatus({
    required this.level,
    required this.status,
    required this.voltage,
    required this.temperature,
  });
}

// 充电状态枚举
enum ChargingStatus {
  discharging(0),
  charging(1),
  full(2);

  final int value;
  const ChargingStatus(this.value);

  static ChargingStatus fromValue(int value) {
    return ChargingStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ChargingStatus.discharging,
    );
  }
}
