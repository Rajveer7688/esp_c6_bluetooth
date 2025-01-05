import 'package:blue/models/bluetooth_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';

class BluetoothRepository extends GetxController {
  static BluetoothRepository get instance => Get.find();

  /// Variables
  final _db = FirebaseFirestore.instance;

  /// Add or update Bluetooth device
  Future<void> addOrUpdateBluetooth(BluetoothModel bluetooth) async {
    try {
      final query = await _db.collection('Bluetooth').where('mac_address', isEqualTo: bluetooth.macAddress).get();

      if (query.docs.isNotEmpty) {
        final docId = query.docs.first.id;
        await _db.collection('Bluetooth').doc(docId).update(bluetooth.toJson());
      } else {
        await _db.collection('Bluetooth').add(bluetooth.toJson());
      }
    } catch (e) {
      throw 'Something went wrong while saving or updating Bluetooth Information. Try again later';
    }
  }

  /// Get Bluetooth data for a specific MAC address
  Future<String> getBluetoothByMac(BluetoothDevice device) async {
    try {
      final query = await _db.collection('Bluetooth').where('mac_address', isEqualTo: device.address).get();
      if (query.docs.isNotEmpty) return BluetoothModel.fromDocumentSnapshot(query.docs.first).name;
      return device.name ?? 'Unknown Device';
    } catch (e) {
      throw 'Something went wrong while fetching Bluetooth Information. Try again later';
    }
  }

  /// Get all bluetooth data
  Future<List<BluetoothModel>> getBluetoothData() async {
    try {
      final result = await _db.collection('Bluetooth').get();
      return result.docs.map((bluetooth) => BluetoothModel.fromDocumentSnapshot(bluetooth)).toList();
    } catch (e) {
      throw 'Something went wrong while fetching Bluetooth Information. Try again later';
    }
  }
}