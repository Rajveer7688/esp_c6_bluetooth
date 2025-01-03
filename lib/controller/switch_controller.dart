import 'package:blue/screens/bluetooth_screen.dart';
import 'package:blue/screens/wifi_screen.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';


class SwitchController extends GetxController {
  static SwitchController get instance => Get.find();

  /// Functional Variables
  var screens = <Widget>[].obs;
  final selectedIndex = 0.obs;
  final isBluetoothOn = false.obs;
  final isWiFiOn = false.obs;
  final isLocationOn = false.obs;

  @override
  void onInit() {
    super.onInit();
    screens.value = [ BluetoothScreen(), WifiScreen() ];
    isBluetoothActive();
    isWiFiActive();
    isLocationActive();
  }

  /// -- 1. Check Bluetooth Status
  Future<bool> isBluetoothActive() async {
    try {
      var status = await Permission.bluetooth.request();
      if (status.isGranted) isBluetoothOn.value = await FlutterBluetoothSerial.instance.isEnabled ?? false;
      return isBluetoothOn.value;
    } catch (e) { return isBluetoothOn(false); }
  }

  /// -- 2. Check Wi-Fi Status
  Future<bool> isWiFiActive() async {
    try {
      bool isEnabled = await WiFiForIoTPlugin.isEnabled();
      return isWiFiOn(isEnabled);
    } catch (e) { return isWiFiOn(false); }
  }

  /// -- 3. Check Location Status
  Future<bool> isLocationActive() async {
    try {
      Location location = Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) serviceEnabled = await location.requestService();
      return isLocationOn(serviceEnabled);
    } catch (e) { return isLocationOn(false); }
  }
}