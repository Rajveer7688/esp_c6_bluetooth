import 'package:blue/controller/location_controller.dart';
import 'package:blue/controller/wifi_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/blue_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BluetoothController());
    final wifiController = Get.put(WifiController());
    final locationcontroller = Get.put(Locationcontroller());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bluetooth Devices Nearby"),
        actions: [
          IconButton(
            icon: Icon(Icons.bluetooth_searching),
            onPressed: controller.scanDevices,
          ),
          IconButton(
              onPressed: () async {
                bool isWiFiEnabled = await wifiController.isWiFiEnabled();
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (isWiFiEnabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Wi-Fi is enabled'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    bool success = await wifiController.enableWifi();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Wi-Fi is enabled'
                            : 'Wifi not enabled !'),
                      ),
                    );
                  }
                });
              },
              icon: Icon(Icons.wifi_outlined)),
          IconButton(
              onPressed: () async {
                bool success = await locationcontroller.isLocationEnabled();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? "Location is Enabled"
                        : "Location is not enabled"),
                  ),
                );
              },
              icon: Icon(
                Icons.location_on,
              ))
        ],
      ),
      body: Obx(() => Column(
            children: [
              if (controller.connectedDevices.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: controller.connectedDevices.length,
                    itemBuilder: (context, index) {
                      var device = controller.connectedDevices[index];
                      return ListTile(
                        title: Text(device.name ?? 'Unknown Device'),
                        subtitle: Text(device.address),
                        trailing: IconButton(
                          icon: Icon(Icons.link_off),
                          onPressed: () =>
                              controller.disconnectDevice(device, null),
                        ),
                      );
                    },
                  ),
                ),
              if (controller.pairedDevices.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: controller.pairedDevices.length,
                    itemBuilder: (context, index) {
                      var device = controller.pairedDevices[index];
                      return ListTile(
                        title: Text(device.name ?? 'Unknown Device'),
                        subtitle: Text(device.address),
                        onTap: () => controller.connectDevice(device),
                      );
                    },
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.newDevices.length,
                  itemBuilder: (context, index) {
                    var device = controller.newDevices[index];
                    return ListTile(
                      title: Text(device.name ?? 'Unknown Device'),
                      subtitle: Text(device.address),
                      trailing: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => controller.pairDevice(device),
                      ),
                    );
                  },
                ),
              ),
            ],
          )),
    );
  }
}
