import 'package:cloud_firestore/cloud_firestore.dart';

class BluetoothModel {
  String id;
  final String name;
  final String macAddress;
  final String? bluetoothType;

  BluetoothModel({
    required this.id,
    required this.name,
    required this.macAddress,
    this.bluetoothType,
  });

  static BluetoothModel empty() => BluetoothModel(id: '', name: '', macAddress: '');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mac_address': macAddress,
      'bluetooth_type': bluetoothType,
    };
  }

  factory BluetoothModel.fromMap(Map<String, dynamic> data) {
    return BluetoothModel(
      id: data['id'] as String,
      name: data['name'] as String,
      macAddress: data['mac_address'] as String,
      bluetoothType: data['bluetooth_type'] as String,
    );
  }

  factory BluetoothModel.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return BluetoothModel(
      id: snapshot.id,
      name: data['name'] ?? '',
      macAddress: data['mac_address'] ?? '',
      bluetoothType: data['bluetooth_type'] ?? 'Unknown',
    );
  }
}
