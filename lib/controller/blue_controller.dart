import 'dart:async';

import 'package:blue/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothController extends GetxController {
  static BluetoothController get instance => Get.find();

  /// -- Functional Variables
  var newDevices = <BluetoothDevice>[].obs;
  var pairedDevices = <BluetoothDevice>[].obs;
  var connectedDevices = <BluetoothDevice>[].obs;

  var isPairing = false.obs;
  var isConnecting = false.obs;
  var isDisconnecting = false.obs;

  /// -- 1. Connect Bluetooth Devices
  Future<void> connectDevice(BluetoothDevice device) async {
    try {
      isConnecting.value = true;
      debugPrint("Connecting to ${device.name ?? 'Device'}...");

      BluetoothConnection connection = await BluetoothConnection.toAddress(device.address).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException("Connection attempt timed out.");
        },
      );

      if (connection.isConnected) {
        connectedDevices.add(device);
        pairedDevices.removeWhere((d) => d.address == device.address);
        debugPrint("Connected to ${device.name ?? 'Device'}");
        TLoaders.successSnackBar(title: 'Connected', message: '${device.name ?? 'Device'} connected successfully.');
      } else {
        debugPrint("Connection to ${device.name ?? 'Device'} failed.");
        Get.snackbar('Oops..!', "${device.name ?? 'Device'} couldn't connect.", snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      debugPrint("Error during connection: $e");
      TLoaders.errorSnackBar(title: 'Oops..!', message: "${device.name ?? 'Device'} couldn't connect.");
    } finally {
      isConnecting.value = false;
    }
  }

  /// -- 2. Disconnect Bluetooth Devices
  Future<void> disconnectDevice(BluetoothDevice device, BluetoothConnection? connection) async {
    try {
      isDisconnecting.value = true;
      debugPrint("Disconnecting from ${device.name ?? 'Device'}...");

      if (connection != null && connection.isConnected) {
        await connection.close();
        await connection.finish();
      }
      connectedDevices.removeWhere((d) => d.address == device.address);
      pairedDevices.add(device);
      debugPrint("Disconnected successfully.");
    } catch (e) {
      debugPrint("Error during disconnection: $e");
    } finally {
      isDisconnecting.value = false;
    }
  }

  /// -- 3. Pair Bluetooth Devices
  Future<bool> pairDevice(BluetoothDevice device) async {
    try {
      List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      bool isPaired = bondedDevices.any((d) => d.address == device.address);

      if (isPaired) {
        debugPrint("Device ${device.name ?? 'Unknown Device'} is already paired.");
        return true;
      }

      bool proceedWithPairing = await Get.defaultDialog(
        title: "Pairing Required",
        content: Text("Device ${device.name ?? 'Unknown Device'} is not paired. Would you like to pair?"),
        confirm: ElevatedButton(onPressed: () => Get.back(result: true), child: Text("Pair")),
        cancel: ElevatedButton(onPressed: () => Get.back(result: false), child: Text("Cancel")),
      );

      if (!proceedWithPairing) {
        debugPrint("User cancelled pairing.");
        return false;
      }

      debugPrint("Attempting to pair with ${device.name ?? 'Unknown Device'}...");
      bool? paired = await FlutterBluetoothSerial.instance.bondDeviceAtAddress(device.address);

      if (paired == true) {
        pairedDevices.add(device);
        newDevices.removeWhere((d) => d.address == device.address);
        pairedDevices.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        debugPrint("Device paired successfully.");
        return true;
      } else {
        debugPrint("Pairing failed or cancelled.");
        return false;
      }
    } catch (e) {
      debugPrint("Error during pairing: $e");
      return false;
    }
  }

  /// -- 4. Scan Bluetooth Devices
  Future<void> scanDevices() async {
    if (await Permission.location.request().isGranted) {
      if (await Permission.bluetoothScan.request().isGranted
          && await Permission.bluetoothConnect.request().isGranted
          && await Permission.locationWhenInUse.request().isGranted
      ) {
        newDevices.clear();

        List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
        pairedDevices.clear();
        pairedDevices.addAll(bondedDevices);

        FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
          debugPrint('This is total devices: ${result.device}');
          if (!bondedDevices.any((d) => d.address == result.device.address)) {
              debugPrint('This is un-bonded devices: ${result.device}');
            if (!newDevices.any((d) => d.address == result.device.address)) {
              newDevices.add(result.device);
              debugPrint('This is new devices: ${result.device}');
            }
          }
        });
      } else {
        debugPrint("Bluetooth permissions are not granted.");
      }
    } else {
      debugPrint("Location permission is not granted.");
    }
  }

  /// -- 5. Unpair Bluetooth Devices
  Future<void> unpairDevice(BluetoothDevice device) async {
    try {
      bool? success = await FlutterBluetoothSerial.instance.removeDeviceBondWithAddress(device.address);

      if (success != null && success) {
        pairedDevices.removeWhere((d) => d.address == device.address);
        newDevices.add(device);
        debugPrint("Device unpaired successfully.");
      } else {
        debugPrint("Failed to unpair the device.");
      }
    } catch (e) {
      debugPrint("Error during unpairing: $e");
    }
  }
}