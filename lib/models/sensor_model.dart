class ServiceUUID {
  static const String smartWatch = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
}

class CharacteristicUUID {
  static const String data = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String command = "cba1d466-359c-4f5e-bd0a-5a8250d4b5e5";
}

class SensorData {
  final int packetNumber;
  final int timestamp;
  final int heartRate;
  final double spO2;
  final int accelX, accelY, accelZ;
  final int gyroX, gyroY, gyroZ;
  final DateTime receivedAt;

  SensorData({
    required this.packetNumber,
    required this.timestamp,
    required this.heartRate,
    required this.spO2,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.receivedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'packet_number': packetNumber,
      'timestamp': timestamp,
      'heart_rate': heartRate,
      'spO2': spO2,
      'accel_x': accelX,
      'accel_y': accelY,
      'accel_z': accelZ,
      'gyro_x': gyroX,
      'gyro_y': gyroY,
      'gyro_z': gyroZ,
      'received_at': receivedAt.toIso8601String(),
    };
  }
}