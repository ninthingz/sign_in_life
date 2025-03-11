import 'dart:typed_data';

import 'package:sign_in_life/protocol/binary_protocol.dart';

class BinarySerializer {
  static ByteData serializeBatteryStatus(BatteryStatus status) {
    final buffer = ByteData(ProtocolHeader.headerSize + BatteryStatus.size);
    int offset = 0;

    // 写入Header占位
    offset = _writeHeaderPlaceholder(buffer);

    // 写入电池数据
    buffer.setUint8(offset++, status.level);
    buffer.setUint8(offset++, status.status.value);
    buffer.setUint16(offset, status.voltage, Endian.little);
    offset += 2;
    buffer.setInt16(offset, status.temperature, Endian.little);
    offset += 2;

    // 回填Header
    _writeRealHeader(
      buffer,
      ProtocolHeader(
        version: 1,
        type: MessageType.batteryStatus,
        payloadSize: BatteryStatus.size,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
    );

    return buffer;
  }

  static int _writeHeaderPlaceholder(ByteData buffer) {
    return (buffer
          ..setUint8(0, 0) // version placeholder
          ..setUint8(1, 0) // type placeholder
          ..setUint16(2, 0, Endian.little) // payloadSize placeholder
          ..setUint32(4, 0, Endian.little))
        .lengthInBytes // timestamp placeholder
        ;
  }

  static void _writeRealHeader(ByteData buffer, ProtocolHeader header) {
    buffer
      ..setUint8(0, header.version)
      ..setUint8(1, header.type.value)
      ..setUint16(2, header.payloadSize, Endian.little)
      ..setUint32(4, header.timestamp, Endian.little);
  }
}
