import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wifi_iot/wifi_iot.dart';

class WifiController extends GetxController {
  static WifiController get instance => Get.find();

  Future<bool> isWiFiEnabled() async {
    try {
      // Check if Wi-Fi is enabled
      bool isEnabled = await WiFiForIoTPlugin.isEnabled();
      return isEnabled;
    } catch (e) {
    
      debugPrint("Error checking Wi-Fi status: $e");
      return false;
    }
  }

  Future<bool> enableWifi() async {
    try {
    
      bool? success =  WiFiForIoTPlugin.setEnabled(true);
      return success ?? false;
    } catch (e) {
    
      debugPrint("Error checking Wi-Fi status: $e");
      return false;
    }
  }


}
