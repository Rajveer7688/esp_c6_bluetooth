import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:blue/utils/constants/colors.dart';
import 'package:blue/utils/constants/sizes.dart';
import 'package:blue/utils/popups/loaders.dart';
import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
  var sensorData = <SensorData?>[].obs;
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
  int rtDiscardCount = 5;

  /// -- Memory Info
  var memoryUsed = 0.obs;
  var memoryFree = 0.obs;
  var memoryCount = 0.obs;
  var memoryPercentage = 0.0.obs;

  /// -- Bluetooth related variables
  BluetoothDevice? connectedDevice;
  BluetoothService? smartWatchService;
  BluetoothCharacteristic? dataCharacteristic;
  BluetoothCharacteristic? commandCharacteristic;

  var oldDeviceConnected = false.obs;
  var connectionStatus = BluetoothConnectionStatus.disconnected.obs;

  StreamSubscription<List<int>>? dataSubscription;
  StreamSubscription<bool>? scanSubscription;
  StreamSubscription<BluetoothConnectionState>? connectionSubscription;

  /// Sync Data Screen
  final GlobalKey<AnimatedListState> syncDataListKey = GlobalKey<AnimatedListState>();

  /// -- Notes
  /// 1. Battery Status
  /// 2. Export in CSV and PDF.

  @override
  void onInit() async {
    super.onInit();
    _checkPermissions();
    _setupBluetoothListeners();
    _initializeGraphs();
    startScan();
  }

  @override
  void dispose() {
    super.dispose();
    disconnect();
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
      BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
      if (state == BluetoothAdapterState.off) {
        TLoaders.warningSnackBar(title: 'Bluetooth Turn On', message: "Please turn on your device bluetooth");
        return;
      }

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

      connectionSubscription = device.connectionState.listen((state) {
        _handleConnectionStateChange(state, device);
      });

      await device.connect();
      connectedDevice = device;

      await device.connectionState.where((state) => state == BluetoothConnectionState.connected).first.timeout(Duration(seconds: 10));
      await _discoverServices(device);

    } catch (e) {
      updateStatus("Connection failed: $e");
      _onDisconnected();
    }
  }

  void _handleConnectionStateChange(BluetoothConnectionState state, BluetoothDevice device) {
    switch (state) {
      case BluetoothConnectionState.connected:
        isConnected.value = true;
        oldDeviceConnected.value = true;
        updateStatus("Connected to Smart Watch");
        break;

      case BluetoothConnectionState.disconnected:
        _onDisconnected();
        break;

      default:
        updateStatus("In Progress...");
        break;
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == ServiceUUID.smartWatch.toLowerCase()) {
          smartWatchService = service;

          for (BluetoothCharacteristic characteristic in service.characteristics) {
            String charUUID = characteristic.uuid.toString().toLowerCase();
            if (charUUID == CharacteristicUUID.data.toLowerCase()) {
              dataCharacteristic = characteristic;
              await dataCharacteristic!.setNotifyValue(true);
              dataSubscription = dataCharacteristic!.onValueReceived.listen(_handleData);
            } else if (charUUID == CharacteristicUUID.command.toLowerCase()) {
              commandCharacteristic = characteristic;
            }
          }
          break;
        }
      }

      if (dataCharacteristic == null || commandCharacteristic == null) {
        throw Exception("Required characteristics not found");
      }

    } catch (e) {
      updateStatus("Service discovery failed: $e");
      rethrow;
    }
  }

  void _handleData(List<int> value) {
    try {
      String data = utf8.decode(value);
      if (!data.startsWith("RT:")) {
        debugPrint('received: $data');
      }

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
      }
    } catch (e) {
      debugPrint("Data parsing error: $e");
    }
  }

  void _handleRealTimeData(String data) {
    try {
      if (data.startsWith("RT:")) data = data.substring(3);

      if (rtDiscardCount > 0) {
        rtDiscardCount--;
        debugPrint("Discarding initial RT packet: $data");
        return;
      }

      final bpmMatch = RegExp(r'BPM=(\d+)').firstMatch(data);
      final spo2Match = RegExp(r'SpO2=([\d.]+)').firstMatch(data);
      final accelMatch = RegExp(r'Accel:X=(-?\d+),Y=(-?\d+),Z=(-?\d+)').firstMatch(data);
      final gyroMatch = RegExp(r'Gyro:X=(-?\d+),Y=(-?\d+),Z=(-?\d+)').firstMatch(data);

      if (bpmMatch == null || spo2Match == null || accelMatch == null || gyroMatch == null) {
        debugPrint("Invalid RT packet dropped: $data");
        return;
      }

      int bpm = int.tryParse(bpmMatch.group(1) ?? '0') ?? 0;
      double spo2 = double.tryParse(spo2Match.group(1) ?? '0') ?? 0.0;

      int accelX = int.tryParse(accelMatch.group(1) ?? '0') ?? 0;
      int accelY = int.tryParse(accelMatch.group(2) ?? '0') ?? 0;
      int accelZ = int.tryParse(accelMatch.group(3) ?? '0') ?? 0;

      int gyroX = int.tryParse(gyroMatch.group(1) ?? '0') ?? 0;
      int gyroY = int.tryParse(gyroMatch.group(2) ?? '0') ?? 0;
      int gyroZ = int.tryParse(gyroMatch.group(3) ?? '0') ?? 0;

      heartBeatCurrent.value = bpm;
      spo2Current.value = spo2;
      accelXCurrent.value = accelX;
      accelYCurrent.value = accelY;
      accelZCurrent.value = accelZ;
      gyroXCurrent.value = gyroX;
      gyroYCurrent.value = gyroY;
      gyroZCurrent.value = gyroZ;

      _addDataPoint(bpm, spo2, accelX, accelY, accelZ, gyroX, gyroY, gyroZ);

    } catch (e) {
      debugPrint("Real-time data parsing error: $e");
    }
  }

  void _handleSyncData(String data) {
    try {
      data = data.replaceFirst("DATA:", "");
      List<String> parts = data.split(",");
      if (parts.length == 10) {
        SensorData sensorDataPoint = SensorData(
          packetNumber: int.parse(parts[0]),
          timestamp: int.parse(parts[1]),
          heartRate: int.parse(parts[2]),
          spO2: double.parse(parts[3]),
          accelX: int.parse(parts[4]),
          accelY: int.parse(parts[5]),
          accelZ: int.parse(parts[6]),
          gyroX: int.parse(parts[7]),
          gyroY: int.parse(parts[8]),
          gyroZ: int.parse(parts[9]),
          receivedAt: DateTime.now(),
        );
        sensorData.add(sensorDataPoint);
        syncDataListKey.currentState?.insertItem(0, duration: Duration(microseconds: 500));

        heartBeatCurrent.value = sensorDataPoint.heartRate;
        spo2Current.value = sensorDataPoint.spO2;
        accelXCurrent.value = sensorDataPoint.accelX;
        accelYCurrent.value = sensorDataPoint.accelY;
        accelZCurrent.value = sensorDataPoint.accelZ;
        gyroXCurrent.value = sensorDataPoint.gyroX;
        gyroYCurrent.value = sensorDataPoint.gyroY;
        gyroZCurrent.value = sensorDataPoint.gyroZ;

        _addDataPoint(sensorDataPoint.heartRate, sensorDataPoint.spO2, sensorDataPoint.accelX, sensorDataPoint.accelY, sensorDataPoint.accelZ, sensorDataPoint.gyroX, sensorDataPoint.gyroY, sensorDataPoint.gyroZ);

        update();
        updateStatus("Received sync packet: ${parts[1]}");
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
      data = data.replaceFirst("MEM_INFO:", "");

      final usedMatch = RegExp(r'Used=(\d+)').firstMatch(data);
      final freeMatch = RegExp(r'Free=(\d+)').firstMatch(data);
      final countMatch = RegExp(r'Count=(\d+)').firstMatch(data);

      if (usedMatch != null && freeMatch != null && countMatch != null) {
        int used = int.parse(usedMatch.group(1)!);
        int free = int.parse(freeMatch.group(1)!);
        int count = int.parse(countMatch.group(1)!);

        debugPrint("📦 Memory Info → Used=$used Free=$free Count=$count");
        updateStatus("Memory Info → Used=$used, Free=$free, Count=$count");

        memoryUsed.value = used;
        memoryFree.value = free;
        memoryCount.value = count;
      } else {
        debugPrint("❌ Invalid MEM_INFO packet: $data");
      }

      if (usedMatch != null && freeMatch != null) {
        memoryUsed.value = int.parse(usedMatch.group(1)!);
        memoryFree.value = int.parse(freeMatch.group(1)!);
      } else if (countMatch != null) {
        memoryUsed.value = int.parse(countMatch.group(1)!);
      }

      int total = memoryUsed.value + memoryFree.value;
      memoryPercentage.value = total > 0 ? (memoryUsed.value / total) * 100 : 0.0;

      update();
    } catch (e) {
      debugPrint("Memory info parsing error: $e");
    }
  }

  void updateStatus(String message) {
    statusMessage.value = message;
    debugPrint("Status: $message");
  }

  Future<void> sendCommand(String command, {int retries = 3}) async {
    if (commandCharacteristic == null || !isConnected.value) {
      updateStatus("Not connected");
      return;
    }

    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        await commandCharacteristic!.write(utf8.encode(command)).timeout(Duration(seconds: 5));
        updateStatus("Command sent: $command");
        return;
      } catch (e) {
        if (attempt == retries) {
          updateStatus("Command failed after $retries attempts: $e");
          rethrow;
        }
        await Future.delayed(Duration(seconds: 1));
      }
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
    await sendCommand("SYNC");
  }

  Future<void> stopSyncData() async {
    if (!isConnected.value) {
      updateStatus("Not connected");
      return;
    }

    isSyncing.value = false;
    sensorData.clear();
    clearGraphData();

    update();
    updateStatus("Stoping data sync...");
    await sendCommand("STOP_SYNC");
    updateStatus("Response: Sync stopped.");
  }

  Future<void> getMemoryInfo() async {
    await sendCommand("INFO");
  }

  Future<void> eraseData() async {
    if (!isConnected.value) return;

    Get.dialog(
      AlertDialog(
        title: Text("Erase Data?", style: GoogleFonts.recursive(fontSize: TSizes.fontSizeMd, fontWeight: FontWeight.w600)),
        content: Text("This will erase all data on the smartwatch. Continue?", style: GoogleFonts.nunito(color: TColors.black, fontSize: TSizes.fontSizeXs, fontWeight: FontWeight.w400)),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text("Cancel", style: GoogleFonts.balooBhai2(color: TColors.primary, fontSize: TSizes.fontSizeSm, fontWeight: FontWeight.w500))),
          TextButton(onPressed: () => Get.back(result: true), child: Text("Erase", style: GoogleFonts.balooBhai2(color: TColors.primary, fontSize: TSizes.fontSizeSm, fontWeight: FontWeight.w500)),),
        ],
      ),
    ).then((confirm) async {
      if (confirm == true) {
        await sendCommand("ERASE");
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
    final status = await Permission.manageExternalStorage.request();
    if (status != PermissionStatus.granted) {
      Get.snackbar("Permission Denied", "Storage permission required for export");
      return;
    }

    if (sensorData.isEmpty) {
      Get.snackbar("No Data", "No data to export", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      List<List<dynamic>> csvData = [['Packet', 'Timestamp', 'Heart Rate', 'SpO2', 'Accel X', 'Accel Y', 'Accel Z', 'Gyro X', 'Gyro Y', 'Gyro Z', 'Received At']];

      for (var data in sensorData) {
        csvData.add([data!.packetNumber, data.timestamp, data.heartRate, data.spO2, data.accelX, data.accelY, data.accelZ, data.gyroX, data.gyroY, data.gyroZ, data.receivedAt.toIso8601String()]);
      }

      String csv = ListToCsvConverter().convert(csvData);

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