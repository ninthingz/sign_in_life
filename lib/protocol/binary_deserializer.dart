import 'dart:typed_data';

import 'package:sign_in_life/protocol/binary_protocol.dart';

class BinaryDeserializer {
  static ProtocolHeader parseHeader(ByteData data) {
    return ProtocolHeader(
      version: data.getUint8(0),
      type: MessageType.fromValue(data.getUint8(1)),
      payloadSize: data.getUint16(2, Endian.little),
      timestamp: data.getUint32(4, Endian.little),
    );
  }

  static BatteryStatus parseBatteryStatus(ByteData data) {
    int offset = ProtocolHeader.headerSize;
    return BatteryStatus(
      level: data.getUint8(offset++),
      status: ChargingStatus.fromValue(data.getUint8(offset++)),
      voltage: data.getUint16(offset, Endian.little),
      temperature: data.getInt16(offset + 2, Endian.little),
    );
  }

  static dynamic parseMessage(Uint8List rawData) {
    final data = rawData.buffer.asByteData();
    final header = parseHeader(data);

    if (header.payloadSize + ProtocolHeader.headerSize != rawData.length) {
      throw Exception('Invalid payload length');
    }

    switch (header.type) {
      case MessageType.batteryStatus:
        return parseBatteryStatus(data);
      // 其他消息类型...
      default:
        throw Exception('Unsupported message type: ${header.type}');
    }
  }
}
