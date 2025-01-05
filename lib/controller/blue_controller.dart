import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/sensor_model.dart';

enum BluetoothConnectionStatus { disconnected, connecting, connected }

class BluetoothController extends GetxController {
  static BluetoothController get instance => Get.find();

  /// -- Functional Variables
  var isScanning = false.obs;
  var isConnected = false.obs;
  var isSyncing = false.obs;
  var statusMessage = "Disconnected".obs;
  var sensorData = <SensorData>[].obs;
  var realTimeData = <String>[].obs;

  /// -- Container Data
  final heartBeatCurrent = 0.obs;
  final spo2Current = 0.0.obs;
  final accelXCurrent = 0.obs;
  final accelYCurrent = 0.obs;
  final accelZCurrent = 0.obs;
  final gyroXCurrent = 0.obs;
  final gyroYCurrent = 0.obs;
  final gyroZCurrent = 0.obs;

  /// -- Graph Data
  var bpmPoints = <FlSpot>[].obs;
  var spo2Points = <FlSpot>[].obs;
  var accelXPoints = <FlSpot>[].obs;
  var accelYPoints = <FlSpot>[].obs;
  var accelZPoints = <FlSpot>[].obs;
  var gyroXPoints = <FlSpot>[].obs;
  var gyroYPoints = <FlSpot>[].obs;
  var gyroZPoints = <FlSpot>[].obs;

  /// -- Graph configuration
  var timeCounter = 0.0.obs;
  final maxDataPoints = 1000;

  /// -- Memory Info
  var memoryUsed = 0.obs;
  var memoryFree = 0.obs;
  var memoryPercentage = 0.0.obs;

  /// -- Bluetooth related variables
  BluetoothDevice? connectedDevice;
  BluetoothService? smartWatchService;
  BluetoothCharacteristic? dataCharacteristic;
  BluetoothCharacteristic? commandCharacteristic;

  StreamSubscription<List<int>>? dataSubscription;
  StreamSubscription<bool>? scanSubscription;
  StreamSubscription<BluetoothConnectionState>? connectionSubscription;

  @override
  void onInit() async {
    super.onInit();
    _checkPermissions();
    _setupBluetoothListeners();
    _initializeGraphs();
  }

  @override
  void onClose() {
    dataSubscription?.cancel();
    scanSubscription?.cancel();
    connectionSubscription?.cancel();
    disconnect();
    super.onClose();
  }

  void _initializeGraphs() {
    for (int i = 0; i < 10; i++) {
      bpmPoints.add(FlSpot(i.toDouble(), 0));
      spo2Points.add(FlSpot(i.toDouble(), 0));
      accelXPoints.add(FlSpot(i.toDouble(), 0));
      accelYPoints.add(FlSpot(i.toDouble(), 0));
      accelZPoints.add(FlSpot(i.toDouble(), 0));
      gyroXPoints.add(FlSpot(i.toDouble(), 0));
      gyroYPoints.add(FlSpot(i.toDouble(), 0));
      gyroZPoints.add(FlSpot(i.toDouble(), 0));
    }
  }

  void _addDataPoint(int bpm, double spo2, int accelX, int accelY, int accelZ, int gyroX, int gyroY, int gyroZ) {
    timeCounter.value += 1.0;

    bpmPoints.add(FlSpot(timeCounter.value, double.tryParse(bpm.toString()) ?? 0.0));
    spo2Points.add(FlSpot(timeCounter.value, spo2));
    accelXPoints.add(FlSpot(timeCounter.value, double.tryParse(accelX.toString()) ?? 0.0));
    accelYPoints.add(FlSpot(timeCounter.value, double.tryParse(accelY.toString()) ?? 0.0));
    accelZPoints.add(FlSpot(timeCounter.value, double.tryParse(accelZ.toString()) ?? 0.0));
    gyroXPoints.add(FlSpot(timeCounter.value, double.tryParse(gyroX.toString()) ?? 0.0));
    gyroYPoints.add(FlSpot(timeCounter.value, double.tryParse(gyroY.toString()) ?? 0.0));
    gyroZPoints.add(FlSpot(timeCounter.value, double.tryParse(gyroZ.toString()) ?? 0.0));

    if (bpmPoints.length > maxDataPoints) {
      bpmPoints.removeAt(0);
      spo2Points.removeAt(0);
      accelXPoints.removeAt(0);
      accelYPoints.removeAt(0);
      accelZPoints.removeAt(0);
      gyroXPoints.removeAt(0);
      gyroYPoints.removeAt(0);
      gyroZPoints.removeAt(0);
    }
  }

  void clearGraphData() {
    bpmPoints.clear();
    spo2Points.clear();
    accelXPoints.clear();
    accelYPoints.clear();
    accelZPoints.clear();
    gyroXPoints.clear();
    gyroYPoints.clear();
    gyroZPoints.clear();
    timeCounter.value = 0;
    _initializeGraphs();
  }

  Future<void> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
      Permission.storage,
    ].request();

    if (statuses[Permission.bluetoothScan] != PermissionStatus.granted) {
      Get.snackbar("Permission Required", "Bluetooth permissions required", snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _setupBluetoothListeners() {
    scanSubscription = FlutterBluePlus.isScanning.listen((state) {
      isScanning.value = state;
    });
  }

  Future<void> startScan() async {
    try {
      await FlutterBluePlus.stopScan();

      isScanning.value = true;
      updateStatus("Scanning for devices...");

      await FlutterBluePlus.startScan(timeout: Duration(seconds: 10), withServices: [Guid(ServiceUUID.smartWatch)]);
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (result.device.advName == "SMART_WATCH_SPAG" || result.device.remoteId.toString().contains("SMART_WATCH_SPAG")) {
            FlutterBluePlus.stopScan();
            _connectToDevice(result.device);
            break;
          }
        }
      });
    } catch (e) {
      updateStatus("Scan error: $e");
      isScanning.value = false;
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      updateStatus("Connecting...");

      await device.connect();
      connectedDevice = device;

      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == ServiceUUID.smartWatch.toLowerCase()) {
          smartWatchService = service;

          for (BluetoothCharacteristic characteristic in service.characteristics) {
            String charUUID = characteristic.uuid.toString().toLowerCase();
            if (charUUID == CharacteristicUUID.data.toLowerCase()) {
              dataCharacteristic = characteristic;
            } else if (charUUID == CharacteristicUUID.command.toLowerCase()) {
              commandCharacteristic = characteristic;
            }
          }
          break;
        }
      }

      if (dataCharacteristic != null && commandCharacteristic != null) {
        await dataCharacteristic!.setNotifyValue(true);
        dataSubscription = dataCharacteristic!.onValueReceived.listen(_handleData);

        isConnected.value = true;
        updateStatus("Connected to SMART_WATCH_SPAG");

        connectionSubscription = device.connectionState.listen((state) {
          if (state == BluetoothConnectionState.disconnected) {
            _onDisconnected();
          }
        });
      } else {
        updateStatus("Service characteristics not found");
      }
    } catch (e) {
      updateStatus("Connection failed: $e");
    }
  }

  void _handleData(List<int> value) {
    try {
      String data = utf8.decode(value);
      debugPrint("Received: $data");

      realTimeData.insert(0, "$data\n");
      if (realTimeData.length > 10) {
        realTimeData.removeLast();
      }

      if (data.startsWith("RT:")) {
        _handleRealTimeData(data);
      } else if (data.startsWith("DATA:")) {
        _handleSyncData(data);
      } else if (data.startsWith("SYNC_COMPLETE:")) {
        _handleSyncComplete(data);
      } else if (data.startsWith("MEM_INFO:")) {
        _handleMemoryInfo(data);
      } else {
        _handleRealTimeData(data);
      }
    } catch (e) {
      debugPrint("Data parsing error: $e");
    }
  }

  void _handleRealTimeData(String data) {
    try {
      Map<String, String> realTimeValues = {};
      List<String> parts = data.replaceFirst("RT:", "").split("|");

      for (String part in parts) {
        List<String> keyValue = part.split("=");
        if (keyValue.length == 2) {
          realTimeValues[keyValue[0]] = keyValue[1];
        }
      }

      int bpm = int.parse(realTimeValues['BPM'] ?? '0');
      double spo2 = double.parse(realTimeValues['SpO2'] ?? '0');

      List<String> accelValues = parts[2].split(":")[1].split(",");
      int accelX = int.tryParse(accelValues[0].split("=")[1]) ?? 0;
      int accelY = int.tryParse(accelValues[1].split("=")[1]) ?? 0;
      int accelZ = int.tryParse(accelValues[2].split("=")[1]) ?? 0;

      List<String> gyroValues = parts[3].split(":")[1].split(",");
      int gyroX = int.tryParse(gyroValues[0].split("=")[1]) ?? 0;
      int gyroY = int.tryParse(gyroValues[1].split("=")[1]) ?? 0;
      int gyroZ = int.tryParse(gyroValues[2].split("=")[1]) ?? 0;

      heartBeatCurrent.value = bpm;
      spo2Current.value = spo2;
      accelXCurrent.value = accelX;
      accelYCurrent.value = accelY;
      accelZCurrent.value = accelZ;
      accelZCurrent.value = accelZ;
      gyroXCurrent.value = gyroX;
      gyroYCurrent.value = gyroY;
      gyroZCurrent.value = gyroZ;

      _addDataPoint(bpm, spo2, accelX, accelY, accelZ, gyroX, gyroY, gyroZ);

      update();
      updateStatus("Real-time: HR ${realTimeValues['BPM']} SpO2 ${realTimeValues['SpO2']}");
    } catch (e) {
      debugPrint("Real-time data error: $e");
    }
  }

  void _handleSyncData(String data) {
    try {
      List<String> parts = data.split(":");
      if (parts.length == 11) {
        SensorData sensorDataPoint = SensorData(
          packetNumber: int.parse(parts[1]),
          timestamp: int.parse(parts[2]),
          heartRate: int.parse(parts[3]),
          spO2: double.parse(parts[4]),
          accelX: int.parse(parts[5]),
          accelY: int.parse(parts[6]),
          accelZ: int.parse(parts[7]),
          gyroX: int.parse(parts[8]),
          gyroY: int.parse(parts[9]),
          gyroZ: int.parse(parts[10]),
          receivedAt: DateTime.now(),
        );
        sensorData.add(sensorDataPoint);

        _addDataPoint(
            sensorDataPoint.heartRate,
            sensorDataPoint.spO2,
            sensorDataPoint.accelX,
            sensorDataPoint.accelY,
            sensorDataPoint.accelZ,
            sensorDataPoint.gyroX,
            sensorDataPoint.gyroY,
            sensorDataPoint.gyroZ
        );

        update();
        updateStatus("Received packet ${parts[1]}");
      }
    } catch (e) {
      debugPrint("Sync data error: $e");
    }
  }

  void _handleSyncComplete(String data) {
    isSyncing.value = false;
    updateStatus("Sync complete! Received ${sensorData.length} data points");
    Get.snackbar("Sync Complete", "Sync completed with ${sensorData.length} records", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
  }

  void _handleMemoryInfo(String data) {
    try {
      String info = data.replaceFirst("MEM_INFO:", "");
      debugPrint('This is memory info: $info}');

      List<String> parts = info.split(",");

      for (String part in parts) {
        List<String> keyValue = part.split("=");
        if (keyValue.length == 2) {
          if (keyValue[0] == "Used") {
            memoryUsed.value = int.tryParse(keyValue[1]) ?? 0;
          } else if (keyValue[0] == "Free") {
            memoryFree.value = int.tryParse(keyValue[1]) ?? 0;
          }
        }
      }

      int total = memoryUsed.value + memoryFree.value;
      if (total > 0) {
        memoryPercentage.value = (memoryUsed.value / total) * 100;
      }

      debugPrint('This is percentage: ${memoryPercentage.value}');

      update();
      updateStatus(data);
    } catch (e) {
      debugPrint("Memory info error: $e");
    }
  }

  void updateStatus(String message) {
    statusMessage.value = message;
    debugPrint("Status: $message");
  }

  Future<void> sendCommand(String command) async {
    if (commandCharacteristic == null || !isConnected.value) {
      updateStatus("Not connected");
      return;
    }

    try {
      await commandCharacteristic!.write(utf8.encode(command));
      updateStatus("Command sent: $command");
    } catch (e) {
      updateStatus("Command failed: $e");
    }
  }

  Future<void> syncData() async {
    if (!isConnected.value) {
      updateStatus("Not connected");
      return;
    }

    isSyncing.value = true;
    sensorData.clear();
    clearGraphData();

    update();
    updateStatus("Starting data sync...");
    await sendCommand("SYNC_DATA");
  }

  Future<void> getMemoryInfo() async {
    await sendCommand("GET_INFO");
  }

  Future<void> eraseData() async {
    if (!isConnected.value) return;

    Get.dialog(
      AlertDialog(
        title: Text("Erase Data?"),
        content: Text("This will erase all data on the smartwatch. Continue?"),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text("Cancel")),
          TextButton(onPressed: () => Get.back(result: true), child: Text("Erase"),),
        ],
      ),
    ).then((confirm) async {
      if (confirm == true) {
        await sendCommand("ERASE_DATA");
        sensorData.clear();
        clearGraphData();
        memoryUsed.value = 0;
        memoryFree.value = 0;
        memoryPercentage.value = 0.0;

        Get.snackbar("Data Erased", "All data and graphs have been cleared", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
      }
    });
  }

  Future<void> exportToCSV() async {
    if (sensorData.isEmpty) {
      Get.snackbar("No Data", "No data to export", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      List<List<dynamic>> csvData = [['Packet', 'Timestamp', 'Heart Rate', 'SpO2', 'Accel X', 'Accel Y', 'Accel Z', 'Gyro X', 'Gyro Y', 'Gyro Z', 'Received At']];

      for (var data in sensorData) {
        csvData.add([data.packetNumber, data.timestamp, data.heartRate, data.spO2, data.accelX, data.accelY, data.accelZ, data.gyroX, data.gyroY, data.gyroZ, data.receivedAt.toIso8601String()]);
      }

      String csv = const ListToCsvConverter().convert(csvData);

      final directory = await getDownloadsDirectory();
      final path = directory?.path;

      if (path == null) throw Exception("Could not access storage");

      String fileName = 'smartwatch_data_${DateTime.now().millisecondsSinceEpoch}.csv';
      File file = File('$path/$fileName');

      await file.writeAsString(csv);

      Get.snackbar("Export Successful", "Data exported to $fileName", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Export Failed", "Export failed: $e", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _onDisconnected() {
    isConnected.value = false;
    connectedDevice = null;
    smartWatchService = null;
    dataCharacteristic = null;
    commandCharacteristic = null;
    updateStatus("Disconnected");
    dataSubscription?.cancel();
  }

  Future<void> disconnect() async {
    dataSubscription?.cancel();
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
    }
    _onDisconnected();
  }
}